/// Modèle Site - correspond à la table `sites`
class Site {
  final String id;
  final String name;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Site({
    required this.id,
    required this.name,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
