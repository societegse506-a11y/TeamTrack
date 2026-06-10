import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../shared/api/api_client.dart';

class ApiService {
  static const _prefix = '/auth';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiClient.post('$_prefix/login', body: {
      'email': email,
      'password': password,
    });
    final data = _parseResponse(response);
    if (data['token'] != null) {
      await ApiClient.saveToken(data['token']);
    }
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String password,
    required double lat,
    required double lng,
  }) async {
    final response = await ApiClient.post('$_prefix/register', body: {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'password': password,
      'position': {'lat': lat, 'lng': lng},
    });
    final data = _parseResponse(response);
    if (data['token'] != null) {
      await ApiClient.saveToken(data['token']);
    }
    return data;
  }

  Future<void> forgotPassword(String email) async {
    final response = await ApiClient.post('$_prefix/forgot-password', body: {
      'email': email,
    });
    _parseResponse(response);
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    final response = await ApiClient.post('$_prefix/reset-password', body: {
      'email': email,
      'code': code,
      'password': password,
    });
    _parseResponse(response);
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw ApiException(
      data['message'] ?? data['error'] ?? 'Une erreur est survenue',
    );
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
