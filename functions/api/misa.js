const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Cache-Control': 'no-store',
};

const model = '@cf/meta/llama-3.1-8b-instruct';

export async function onRequestOptions() {
  return new Response(null, {
    status: 204,
    headers: corsHeaders,
  });
}

export async function onRequestPost(context) {
  try {
    if (!context.env.AI) {
      return json(
        { error: 'Workers AI binding is not configured for this deployment.' },
        503,
      );
    }

    const body = await context.request.json();
    const prompt = typeof body?.prompt === 'string' ? body.prompt.trim() : '';
    const candidateActions = Array.isArray(body?.candidateActions)
        ? body.candidateActions.filter(isCandidateAction)
        : [];

    if (!prompt) {
      return json({ error: 'Prompt is required.' }, 400);
    }

    const systemPrompt = [
      'You are MISA, a field operations assistant for an agricultural workflow app.',
      'Use only the supplied context. Do not invent farmer state, actions, or routes.',
      'Your job is to answer the agent clearly and, when appropriate, choose exactly one allowed action from the candidate action list.',
      'Prefer short operational guidance over general advice.',
      'If the user asks about one farmer, keep the answer focused on that farmer unless the context clearly calls for escalation.',
      'Return ONLY valid JSON with this shape:',
      '{"answer":"string","recommended_action_id":"string or null","recommendation_title":"string or null","recommendation_message":"string or null"}',
      'If no listed action fits, set recommended_action_id, recommendation_title, and recommendation_message to null.',
      'Do not wrap the JSON in markdown fences.',
    ].join(' ');

    const transcript = Array.isArray(body?.conversation)
        ? body.conversation
            .filter((item) => item && typeof item.message === 'string')
            .map((item) => {
              const speaker = item.author === 'agent' ? 'Agent' : 'MISA';
              return `${speaker}: ${item.message}`;
            })
            .join('\n')
        : '';

    const userPrompt = [
      `Current agent request: ${prompt}`,
      transcript ? `Conversation so far:\n${transcript}` : null,
      `Mode: ${body?.mode ?? 'general'}`,
      `Selected farmer: ${body?.selectedFarmerId ?? 'none'}`,
      `Structured workflow context:\n${JSON.stringify(body?.context ?? {}, null, 2)}`,
      `Candidate actions:\n${JSON.stringify(candidateActions, null, 2)}`,
      'Remember: choose only from candidate_actions.id values when recommending an action.',
    ]
        .filter(Boolean)
        .join('\n\n');

    const result = await context.env.AI.run(model, {
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ],
      max_tokens: 450,
      temperature: 0.2,
    });

    const rawText =
        typeof result?.response === 'string'
            ? result.response
            : JSON.stringify(result ?? {});
    const parsed = parseModelJson(rawText);

    const answer = typeof parsed.answer === 'string' ? parsed.answer.trim() : '';
    if (!answer) {
      throw new Error('Model returned an empty answer.');
    }

    const actionId =
        typeof parsed.recommended_action_id === 'string'
            ? parsed.recommended_action_id.trim()
            : null;
    const chosenAction =
        actionId == null
            ? null
            : candidateActions.find((candidate) => candidate.id === actionId) ??
              null;

    const recommendation =
        chosenAction == null
            ? null
            : {
                title:
                    cleanOptionalString(parsed.recommendation_title) ??
                    chosenAction.title,
                message:
                    cleanOptionalString(parsed.recommendation_message) ??
                    chosenAction.summary,
                actionLabel: chosenAction.actionLabel,
                actionRoute: chosenAction.actionRoute,
                farmerId:
                    cleanOptionalString(chosenAction.farmerId) ??
                    cleanOptionalString(body?.selectedFarmerId),
              };

    return json(
      {
        message: answer,
        recommendation,
      },
      200,
    );
  } catch (error) {
    return json(
      {
        error:
            error instanceof Error
                ? error.message
                : 'MISA request failed.',
      },
      502,
    );
  }
}

function isCandidateAction(value) {
  return (
    value &&
    typeof value.id === 'string' &&
    typeof value.title === 'string' &&
    typeof value.summary === 'string' &&
    typeof value.actionLabel === 'string' &&
    typeof value.actionRoute === 'string'
  );
}

function cleanOptionalString(value) {
  return typeof value === 'string' && value.trim() ? value.trim() : null;
}

function parseModelJson(text) {
  const fencedMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/i);
  const source = fencedMatch ? fencedMatch[1] : text;
  const start = source.indexOf('{');
  const end = source.lastIndexOf('}');

  if (start === -1 || end === -1 || end < start) {
    throw new Error(`Unable to parse model response: ${text}`);
  }

  return JSON.parse(source.slice(start, end + 1));
}

function json(payload, status) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}
