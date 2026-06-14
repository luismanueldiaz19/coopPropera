import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // static const String baseUrl = 'http://localhost:8000/api/v1'; // Entorno Local
  static const String baseUrl =
      'https://cooppropera.onrender.com/api/v1'; // Entorno Producción (Render)
  final _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();
    return await http.get(url, headers: headers);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();
    return await http.post(url, headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();
    return await http.put(url, headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();
    return await http.delete(url, headers: headers);
  }

  Future<http.StreamedResponse> postMultipart(
    String endpoint, {
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final token = await _storage.read(key: 'auth_token');

    final request = http.MultipartRequest('POST', url);
    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    if (fileBytes != null && fileName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'attachment',
          fileBytes,
          filename: fileName,
        ),
      );
    } else if (filePath != null) {
      request.files.add(
        await http.MultipartFile.fromPath('attachment', filePath),
      );
    }

    return await request.send();
  }
}
