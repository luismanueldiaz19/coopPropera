import 'package:flutter/foundation.dart';
import '../models/occupation.dart';
import '../services/occupation_api_service.dart';

class OccupationProvider with ChangeNotifier {
  final OccupationApiService _apiService = OccupationApiService();
  
  List<Occupation> _occupations = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Occupation> get occupations => _occupations;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchOccupations() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _occupations = await _apiService.getOccupations();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createOccupation(Map<String, dynamic> data) async {
    try {
      final newOccupation = await _apiService.createOccupation(data);
      _occupations.add(newOccupation);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOccupation(int id, Map<String, dynamic> data) async {
    try {
      final updatedOccupation = await _apiService.updateOccupation(id, data);
      final index = _occupations.indexWhere((o) => o.id == id);
      if (index != -1) {
        _occupations[index] = updatedOccupation;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteOccupation(int id) async {
    try {
      await _apiService.deleteOccupation(id);
      _occupations.removeWhere((o) => o.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
