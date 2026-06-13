import 'dart:convert';
import '../models/occupation.dart';
import 'api_service.dart';

class OccupationApiService {
  final ApiService _api = ApiService();

  Future<List<Occupation>> getOccupations() async {
    try {
      final response = await _api.get('/occupations');
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'];
        return data.map((json) => Occupation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load occupations');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Occupation> createOccupation(
    Map<String, dynamic> occupationData,
  ) async {
    final response = await _api.post('/occupations', occupationData);
    if (response.statusCode == 201) {
      final body = jsonDecode(response.body);
      return Occupation.fromJson(body['data']);
    } else {
      throw Exception('Failed to create occupation');
    }
  }

  Future<Occupation> updateOccupation(
    int id,
    Map<String, dynamic> occupationData,
  ) async {
    final response = await _api.put('/occupations/$id', occupationData);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return Occupation.fromJson(body['data']);
    } else {
      throw Exception('Failed to update occupation');
    }
  }

  Future<void> deleteOccupation(int id) async {
    final response = await _api.delete('/occupations/$id');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete occupation');
    }
  }
}
