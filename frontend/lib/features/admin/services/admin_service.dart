import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../shared/api/api_client.dart';
import '../../auth/models/user.dart';

class AdminService {
  static const _prefix = '/admin';

  Future<List<User>> getUsers() async {
    final response = await ApiClient.get('$_prefix/users');
    final data = _handleResponse(response);
    final List<dynamic> list = data['data'] ?? [];
    return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<User> getUserById(String id) async {
    final response = await ApiClient.get('$_prefix/users/$id');
    final data = _handleResponse(response);
    final userData = data['data'] ?? data;
    return User.fromJson(userData as Map<String, dynamic>);
  }

  Future<User> updateUser(String id, {String? nom, String? prenom, String? email, String? telephone, String? role, bool? isActive}) async {
    final body = <String, dynamic>{};
    if (nom != null) body['nom'] = nom;
    if (prenom != null) body['prenom'] = prenom;
    if (email != null) body['email'] = email;
    if (telephone != null) body['telephone'] = telephone;
    if (role != null) body['role'] = role;
    if (isActive != null) body['isActive'] = isActive;

    final response = await ApiClient.put('$_prefix/users/$id', body: body);
    final data = _handleResponse(response);
    final userData = data['data'] ?? data;
    return User.fromJson(userData as Map<String, dynamic>);
  }

  Future<void> deleteUser(String id) async {
    final response = await ApiClient.delete('$_prefix/users/$id');
    _handleResponse(response);
  }

  Future<void> toggleActive(String id) async {
    final response = await ApiClient.put('$_prefix/users/$id/toggle-active');
    _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data is Map<String, dynamic> ? data : <String, dynamic>{'data': data};
    }
    final msg = data is Map ? (data['message'] ?? 'Request failed') : 'Request failed';
    throw AdminException(msg.toString());
  }
}

class AdminException implements Exception {
  final String message;
  AdminException(this.message);
  @override
  String toString() => message;
}
