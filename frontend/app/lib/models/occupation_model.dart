class OccupationModel {
  final int id;
  final String name;

  OccupationModel({
    required this.id,
    required this.name,
  });

  factory OccupationModel.fromJson(Map<String, dynamic> json) {
    return OccupationModel(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }
}
