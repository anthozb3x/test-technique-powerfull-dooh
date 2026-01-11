/// Statut d'un contenu DOOH
enum ContentStatus {
  draft,
  published,
  archived;

  String get label {
    switch (this) {
      case ContentStatus.draft:
        return 'Brouillon';
      case ContentStatus.published:
        return 'Publié';
      case ContentStatus.archived:
        return 'Archivé';
    }
  }

  static ContentStatus fromString(String value) {
    return ContentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ContentStatus.draft,
    );
  }
}

class Content {
  final String id;
  final String title;
  final String? mediaUrl;
  final DateTime startAt;
  final DateTime endAt;
  final String siteId;
  final String createdBy;
  final ContentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Content({
    required this.id,
    required this.title,
    this.mediaUrl,
    required this.startAt,
    required this.endAt,
    required this.siteId,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      id: json['id'] as String,
      title: json['title'] as String,
      mediaUrl: json['media_url'] as String?,
      startAt: DateTime.parse(json['start_at'] as String),
      endAt: DateTime.parse(json['end_at'] as String),
      siteId: json['site_id'] as String,
      createdBy: json['created_by'] as String,
      status: ContentStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startAt) && now.isBefore(endAt);
  }

  bool get isScheduled => DateTime.now().isBefore(startAt);

  bool get isExpired => DateTime.now().isAfter(endAt);
}
