import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../shared/api/api_client.dart';
import '../models/member.dart';

class MemberService {
  static const _prefix = '/members';

  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data is Map<String, dynamic> ? data : <String, dynamic>{'data': data};
    }
    final msg = data is Map ? (data['message'] ?? 'Request failed') : 'Request failed';
    throw MemberException(msg.toString());
  }

  Future<List<Member>> getMembers() async {
    final response = await ApiClient.get(_prefix);
    final data = _handleResponse(response);
    final List<dynamic> list = data['data'] ?? [];
    return list.map((e) => Member.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Member> getMember(String id) async {
    final response = await ApiClient.get('$_prefix/$id');
    final data = _handleResponse(response);
    final memberData = data['data'] ?? data;
    return Member.fromJson(memberData as Map<String, dynamic>);
  }

  Future<Member> createMember({
    required String nom,
    required String prenom,
    required String cin,
    required String telephone,
    String description = '',
  }) async {
    final response = await ApiClient.post(_prefix, body: {
      'nom': nom,
      'prenom': prenom,
      'cin': cin,
      'telephone': telephone,
      if (description.isNotEmpty) 'description': description,
    });
    final data = _handleResponse(response);
    final memberData = data['data'] ?? data;
    return Member.fromJson(memberData as Map<String, dynamic>);
  }

  Future<Member> updateMember(String id, {
    required String nom,
    required String prenom,
    required String cin,
    required String telephone,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'nom': nom,
      'prenom': prenom,
      'cin': cin,
      'telephone': telephone,
    };
    if (description != null) body['description'] = description;
    final response = await ApiClient.put('$_prefix/$id', body: body);
    final data = _handleResponse(response);
    final memberData = data['data'] ?? data;
    return Member.fromJson(memberData as Map<String, dynamic>);
  }

  Future<void> deleteMember(String id) async {
    final response = await ApiClient.delete('$_prefix/$id');
    _handleResponse(response);
  }

  Future<Set<String>> getFrequentLateMemberIds() async {
    final ids = <String>{};
    try {
      final body = await ApiClient.getSafe('/statistics', timeout: ApiClient.longTimeout);
      if (body == null) return ids;
      final list = body['data'] as List<dynamic>? ?? [];
      for (final item in list) {
        final stats = item['stats'] as Map<String, dynamic>?;
        if (stats != null) {
          final late = (stats['morningLate'] as num?)?.toInt() ?? 0;
          final totalDays = (stats['totalDays'] as num?)?.toInt() ?? 0;
          if (totalDays > 2 && late > 0 && (late / totalDays) > 0.3) {
            final memberItem = item['member'] as Map<String, dynamic>? ?? {};
            final memberId = memberItem['id'] as String? ?? '';
            if (memberId.isNotEmpty) ids.add(memberId);
          }
        }
      }
    } catch (e) {
      debugPrint('MemberService: failed to load frequent late data — $e');
    }
    return ids;
  }
}

class MemberException implements Exception {
  final String message;
  MemberException(this.message);
  @override
  String toString() => message;
}
