import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  UserModel? _user;
  String _errorMessage = '';

  bool get isAuthenticated => _isAuthenticated;
  UserModel? get user => _user;
  String get errorMessage => _errorMessage;

  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      try {
        final response = await _apiService.get('/me');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _user = UserModel.fromJson(data['user']);
          _isAuthenticated = true;
        } else {
          await _storage.delete(key: 'auth_token');
          _isAuthenticated = false;
        }
      } catch (e) {
        // En caso de error de conexión, asumimos deslogueado por seguridad o guardamos offline
        _isAuthenticated = false;
      }
    } else {
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _apiService.post('/login', {
        'username': username,
        'password': password,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _storage.write(key: 'auth_token', value: data['access_token']);
        _user = UserModel.fromJson(data['user']);
        _isAuthenticated = true;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Error al iniciar sesión';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error de conexión. Inténtalo de nuevo.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.post('/logout', {});
    } catch (e) {
      // Ignorar error de red al desloguear
    }
    await _storage.delete(key: 'auth_token');
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
