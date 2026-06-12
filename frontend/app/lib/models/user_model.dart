class UserModel {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final int? occupationId;
  final String status;
  final List<dynamic>? roles;

  UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.occupationId,
    required this.status,
    this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      occupationId: json['occupation_id'],
      status: json['status'] ?? 'active',
      roles: json['roles'],
    );
  }

  String get fullName => '$firstName $lastName';
  bool get isAdmin =>
      roles?.any((r) {
        if (r is String) return r == 'admin';
        if (r is Map) return r['name'] == 'admin';
        return false;
      }) ??
      false;
}
