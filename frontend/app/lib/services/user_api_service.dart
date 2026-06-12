import 'dart:convert';
import 'api_service.dart';
import '../models/user_model.dart';
import '../models/role_model.dart';
import '../models/occupation_model.dart';

class UserApiService {
  final ApiService _api = ApiService();

  Future<List<UserModel>> getUsers() async {
    final response = await _api.get('/users');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['data'];
      return items.map((json) => UserModel.fromJson(json)).toList();
    }
    throw Exception('Error al cargar usuarios');
  }

  Future<UserModel> createUser(Map<String, dynamic> data) async {
    final response = await _api.post('/users', data);
    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return UserModel.fromJson(responseData['data']);
    }
    throw Exception('Error al crear usuario: ${response.body}');
  }

  Future<List<OccupationModel>> getOccupations() async {
    final response = await _api.get('/occupations');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['data'];
      return items.map((json) => OccupationModel.fromJson(json)).toList();
    }
    throw Exception('Error al cargar ocupaciones');
  }

  Future<List<RoleModel>> getRoles() async {
    final response = await _api.get('/roles');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['data'];
      return items.map((json) => RoleModel.fromJson(json)).toList();
    }
    throw Exception('Error al cargar roles');
  }
}
