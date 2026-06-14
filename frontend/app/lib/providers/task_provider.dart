import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/task_api_service.dart';

class TaskProvider with ChangeNotifier {
  final TaskApiService _api = TaskApiService();

  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Timer state
  final Map<int, DateTime> _activeTaskStarts = {};

  DateTime? getTaskStartTime(int taskId) => _activeTaskStarts[taskId];

  void setTaskStartTime(int taskId, DateTime time) {
    _activeTaskStarts[taskId] = time;
    notifyListeners();
  }

  void clearTaskStartTime(int taskId) {
    _activeTaskStarts.remove(taskId);
    notifyListeners();
  }

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
      await _api.createTask(data);
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

  Future<bool> assignTask(int taskId, int userId) async {
    try {
      await _api.assignTask(taskId, userId);
      await fetchTasks();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> closeTask(int taskId) async {
    try {
      await _api.closeTask(taskId);
      await fetchTasks();
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
      await fetchTasks();
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
      await fetchTasks();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadAttachment(int taskId, {String? filePath, List<int>? fileBytes, String? fileName}) async {
    try {
      await _api.uploadAttachment(taskId, filePath: filePath, fileBytes: fileBytes, fileName: fileName);
      await fetchTasks();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAttachment(int taskId, int attachmentId) async {
    try {
      await _api.deleteAttachment(taskId, attachmentId);
      await fetchTasks();
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
