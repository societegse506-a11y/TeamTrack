import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static String baseUrl = 'https://teamtrack-9otq.onrender.com/api';
  //static String baseUrl = 'https://21d2-102-159-21-193.ngrok-free.app/api';
   
  static const String _tokenKey = 'jwt_token';
  static const String _roleKey = 'user_role';
  static const Duration defaultTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(seconds: 15);

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<bool> isAdmin() async {
    final role = await getRole();
    return role == 'admin';
  }

  static Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(
    String endpoint, {
    Duration? timeout,
  }) async {
    final headers = await authHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl$endpoint'), headers: headers)
        .timeout(timeout ?? defaultTimeout);
    return response;
  }

  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    final headers = await authHeaders();
    final response = await http
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(timeout ?? defaultTimeout);
    return response;
  }

  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    final headers = await authHeaders();
    final response = await http
        .put(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(timeout ?? defaultTimeout);
    return response;
  }

  static Future<http.Response> delete(
    String endpoint, {
    Duration? timeout,
  }) async {
    final headers = await authHeaders();
    final response = await http
        .delete(Uri.parse('$baseUrl$endpoint'), headers: headers)
        .timeout(timeout ?? defaultTimeout);
    return response;
  }

  static Future<Map<String, dynamic>?> getSafe(
    String endpoint, {
    Duration? timeout,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers: await authHeaders(),
          )
          .timeout(timeout ?? defaultTimeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiClient.getSafe($endpoint) failed: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> postSafe(
    String endpoint, {
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: await authHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? defaultTimeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiClient.postSafe($endpoint) failed: $e');
    }
    return null;
  }
}
