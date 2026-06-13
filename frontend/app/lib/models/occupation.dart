class Occupation {
  final int id;
  final String name;
  final String? description;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  Occupation({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Occupation.fromJson(Map<String, dynamic> json) {
    return Occupation(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      status: json['status'] ?? 'active',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
    };
  }
}
