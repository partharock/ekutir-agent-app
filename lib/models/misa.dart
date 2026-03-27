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
}
