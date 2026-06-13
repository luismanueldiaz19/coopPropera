import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/role_model.dart';
import '../models/occupation_model.dart';
import '../services/user_api_service.dart';

class UserProvider with ChangeNotifier {
  final UserApiService _api = UserApiService();

  List<UserModel> _users = [];
  List<OccupationModel> _occupations = [];
  List<RoleModel> _roles = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<UserModel> get users => _users;
  List<OccupationModel> get occupations => _occupations;
  List<RoleModel> get roles => _roles;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchUsers() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _users = await _api.getUsers();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUser(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final updatedUser = await _api.updateUser(id, data);
      final index = _users.indexWhere((u) => u.id == id);
      if (index != -1) {
        _users[index] = updatedUser;
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMetaData() async {
    try {
      _occupations = await _api.getOccupations();
      _roles = await _api.getRoles();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
