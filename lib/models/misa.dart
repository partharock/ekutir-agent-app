enum MisaMode { general, farmer }

extension MisaModeX on MisaMode {
  String get label => this == MisaMode.general ? 'General' : 'Farmer-Specific';
}

enum MisaMessageAuthor { assistant, agent }

class MisaRecommendation {
  const MisaRecommendation({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.actionRoute,
    this.farmerId,
  });

  final String title;
  final String message;
  final String actionLabel;
  final String actionRoute;
  final String? farmerId;

  Map<String, dynamic> toJson() => {
        'title': title,
        'message': message,
        'actionLabel': actionLabel,
        'actionRoute': actionRoute,
        'farmerId': farmerId,
      };

  factory MisaRecommendation.fromJson(Map<String, dynamic> json) {
    return MisaRecommendation(
      title: (json['title'] as String? ?? '').trim(),
      message: (json['message'] as String? ?? '').trim(),
      actionLabel: (json['actionLabel'] as String? ?? '').trim(),
      actionRoute: (json['actionRoute'] as String? ?? '').trim(),
      farmerId: (json['farmerId'] as String?)?.trim(),
    );
  }
}

class MisaMessage {
  const MisaMessage({
    required this.id,
    required this.author,
    required this.message,
    required this.timestamp,
    this.recommendation,
  });

  final String id;
  final MisaMessageAuthor author;
  final String message;
  final DateTime timestamp;
  final MisaRecommendation? recommendation;

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author.name,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'recommendation': recommendation?.toJson(),
      };
}

class MisaActionCandidate {
  const MisaActionCandidate({
    required this.id,
    required this.title,
    required this.summary,
    required this.actionLabel,
    required this.actionRoute,
    this.farmerId,
  });

  final String id;
  final String title;
  final String summary;
  final String actionLabel;
  final String actionRoute;
  final String? farmerId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'actionLabel': actionLabel,
        'actionRoute': actionRoute,
        'farmerId': farmerId,
      };
}

class MisaRequest {
  const MisaRequest({
    required this.prompt,
    required this.mode,
    this.selectedFarmerId,
    required this.conversation,
    required this.context,
    required this.candidateActions,
  });

  final String prompt;
  final MisaMode mode;
  final String? selectedFarmerId;
  final List<MisaMessage> conversation;
  final Map<String, dynamic> context;
  final List<MisaActionCandidate> candidateActions;

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        'mode': mode.name,
        'selectedFarmerId': selectedFarmerId,
        'conversation':
            conversation.map((message) => message.toJson()).toList(),
        'context': context,
        'candidateActions':
            candidateActions.map((action) => action.toJson()).toList(),
      };
}

class MisaAiReply {
  const MisaAiReply({
    required this.message,
    this.recommendation,
  });

  final String message;
  final MisaRecommendation? recommendation;

  factory MisaAiReply.fromJson(Map<String, dynamic> json) {
    final recommendationJson = json['recommendation'];
    return MisaAiReply(
      message: (json['message'] as String? ?? '').trim(),
      recommendation: recommendationJson is Map<String, dynamic>
          ? MisaRecommendation.fromJson(recommendationJson)
          : null,
    );
  }
}
