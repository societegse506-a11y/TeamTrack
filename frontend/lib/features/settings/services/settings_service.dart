import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../shared/api/api_client.dart';
import '../models/settings_model.dart';

class SettingsService {
  Future<WorkSettings> load() async {
    try {
      final body = await ApiClient.getSafe('/settings');
      if (body != null && body['data'] is Map) {
        return WorkSettings.fromJson(body['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Settings: failed to load — $e');
    }

    return WorkSettings(
      morningStart: '08:00',
      morningEnd: '12:00',
      afternoonStart: '14:00',
      afternoonEnd: '18:00',
      lateToleranceMinutes: 15,
      gpsRadius: 500,
      workingDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
    );
  }

  Future<void> save(WorkSettings settings) async {
    final response = await ApiClient.post('/settings', body: settings.toJson());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = jsonDecode(response.body);
      final msg = body is Map ? (body['message'] ?? 'Failed to save settings') : 'Failed to save settings';
      throw Exception(msg);
    }
  }
}
