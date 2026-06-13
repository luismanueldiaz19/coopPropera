import 'dart:convert';
import 'api_service.dart';
import '../models/task_model.dart';

class TaskApiService {
  final ApiService _api = ApiService();

  Future<List<TaskModel>> getTasks() async {
    final response = await _api.get('/tasks');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['data'];
      return items.map((json) => TaskModel.fromJson(json)).toList();
    }
    throw Exception('Error al cargar tareas');
  }

  Future<TaskModel> createTask(Map<String, dynamic> data) async {
    final response = await _api.post('/tasks', data);
    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return TaskModel.fromJson(responseData['data']);
    }
    throw Exception('Error al crear tarea: ${response.body}');
  }

  Future<TaskModel> updateTask(int id, Map<String, dynamic> data) async {
    final response = await _api.put('/tasks/$id', data);
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return TaskModel.fromJson(responseData['data']);
    }
    throw Exception('Error al actualizar tarea');
  }

  Future<void> addReport(int taskId, Map<String, dynamic> data) async {
    final response = await _api.post('/tasks/$taskId/reports', data);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to add report: ${response.body}');
    }
  }

  Future<void> assignTask(int taskId, int userId) async {
    final response = await _api.post('/tasks/$taskId/assign', {
      'user_id': userId,
    });
    if (response.statusCode != 200) {
      throw Exception('Error al asignar tarea');
    }
  }

  Future<void> closeTask(int taskId) async {
    final response = await _api.post('/tasks/$taskId/close', {});
    if (response.statusCode != 200) {
      throw Exception('Error al finalizar tarea: ${response.body}');
    }
  }

  Future<void> syncParticipants(int taskId, List<int> participantIds) async {
    final response = await _api.post('/tasks/$taskId/participants', {
      'participants': participantIds,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al actualizar participantes: ${response.body}');
    }
  }

  Future<void> deleteTask(int taskId) async {
    final response = await _api.delete('/tasks/$taskId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar tarea: ${response.body}');
    }
  }

  Future<void> uploadAttachment(int taskId, String filePath) async {
    final response = await _api.postMultipart(
      '/tasks/$taskId/attachments',
      filePath,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final resBody = await response.stream.bytesToString();
      throw Exception('Error al subir archivo: $resBody');
    }
  }

  Future<void> deleteAttachment(int taskId, int attachmentId) async {
    final response = await _api.delete(
      '/tasks/$taskId/attachments/$attachmentId',
    );
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar anexo');
    }
  }
}
