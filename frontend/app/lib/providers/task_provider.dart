import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/task_api_service.dart';

class TaskProvider with ChangeNotifier {
  final TaskApiService _api = TaskApiService();
  
  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchTasks() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _tasks = await _api.getTasks();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTask(Map<String, dynamic> data) async {
    try {
      final newTask = await _api.createTask(data);
      _tasks.insert(0, newTask);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignTask(int taskId, int userId) async {
    try {
      await _api.assignTask(taskId, userId);
      // Actualizamos la tarea (recargamos toda la lista por simplicidad de momento)
      await fetchTasks();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTaskStatus(int id, String status) async {
    try {
      final updatedTask = await _api.updateTask(id, {'status': status});
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addReport(int taskId, Map<String, dynamic> data) async {
    try {
      await _api.addReport(taskId, data);
      await fetchTasks(); // Recargar las tareas para ver el reporte reflejado
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  Future<bool> syncParticipants(int taskId, List<int> participantIds) async {
    try {
      await _api.syncParticipants(taskId, participantIds);
      await fetchTasks(); // Recargar para reflejar cambios
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadAttachment(int taskId, String filePath) async {
    try {
      await _api.uploadAttachment(taskId, filePath);
      await fetchTasks(); // Recargar la tarea para obtener los nuevos adjuntos
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(int taskId) async {
    try {
      await _api.deleteTask(taskId);
      _tasks.removeWhere((t) => t.id == taskId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
