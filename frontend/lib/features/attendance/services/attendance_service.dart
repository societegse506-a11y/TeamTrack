import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/attendance_model.dart';
import '../../members/models/member.dart';
import '../../../shared/notifiers/settings_notifier.dart';
import '../../../shared/api/api_client.dart';

class AttendanceService {
  Future<List<Member>> getMembers() async {
    try {
      final response = await ApiClient.get('/members');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final list = body['data'] as List<dynamic>? ?? [];
        return list.map((e) => Member.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Attendance: failed to load members — $e');
    }
    return [];
  }

  Future<List<AttendanceRecord>> getTodayRecords() async {
    try {
      final body = await ApiClient.getSafe('/attendance/today');
      if (body != null) {
        final list = body['data'] as List<dynamic>? ?? [];
        return list.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Attendance: failed to load today records — $e');
    }
    return [];
  }

  Future<Map<String, MemberAttendance>> getMemberAttendanceMap(
      List<Member> members) async {
    final records = await getTodayRecords();
    final map = <String, MemberAttendance>{};

    for (final m in members) {
      map[m.id] = MemberAttendance(member: m);
    }

    for (final rec in records) {
      final existing = map[rec.memberId];
      if (existing != null) {
        if (rec.session == 'morning') {
          map[rec.memberId] = MemberAttendance(
            member: existing.member,
            morningStatus: rec.attendanceStatus,
            morningTime: rec.checkInTime,
            afternoonStatus: existing.afternoonStatus,
            afternoonTime: existing.afternoonTime,
          );
        } else {
          map[rec.memberId] = MemberAttendance(
            member: existing.member,
            morningStatus: existing.morningStatus,
            morningTime: existing.morningTime,
            afternoonStatus: rec.attendanceStatus,
            afternoonTime: rec.checkInTime,
          );
        }
      } else {
        final member = members.where((m) => m.id == rec.memberId).firstOrNull;
        if (member != null) {
          map[rec.memberId] = MemberAttendance(
            member: member,
            morningStatus: rec.session == 'morning' ? rec.attendanceStatus : AttendanceStatus.notChecked,
            afternoonStatus: rec.session == 'afternoon' ? rec.attendanceStatus : AttendanceStatus.notChecked,
          );
        }
      }
    }

    return map;
  }

  Future<CheckInResult> checkIn({
    required String memberId,
    required String session,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await ApiClient.post(
        '/attendance/checkin',
        body: {
          'memberId': memberId,
          'session': session,
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
        timeout: ApiClient.longTimeout,
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return CheckInResult.fromJson(body);
      }

      return CheckInResult(
        success: false,
        message: body['message'] as String? ?? 'Check-in failed',
        status: '',
      );
    } catch (e) {
      return CheckInResult(
        success: false,
        message: 'Check-in failed: $e',
        status: '',
      );
    }
  }

  Future<SessionConfig> getSessionConfig() async {
    final now = DateTime.now();
    final settings = SettingsNotifier.instance.value;
    final afternoonStart = settings.afternoonStart;
    final parts = afternoonStart.split(':');
    final afternoonHour = int.tryParse(parts[0]) ?? 14;

    final hour = now.hour;
    if (hour >= afternoonHour) {
      return SessionConfig(
        session: 'afternoon',
        label: 'Afternoon',
        start: settings.afternoonStart,
        end: settings.afternoonEnd,
      );
    }
    return SessionConfig(
      session: 'morning',
      label: 'Morning',
      start: settings.morningStart,
      end: settings.morningEnd,
    );
  }

  Future<List<AttendanceRecord>> getMemberHistory(String memberId,
      {int? year, int? month}) async {
    try {
      final queryParams = <String, String>{};
      if (year != null) queryParams['year'] = year.toString();
      if (month != null) queryParams['month'] = month.toString();
      final query = queryParams.isNotEmpty
          ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
          : '';
      final body = await ApiClient.getSafe('/attendance/member/$memberId$query');
      if (body != null) {
        final list = body['data'] as List<dynamic>? ?? [];
        return list.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Attendance: failed to load member history — $e');
    }
    return [];
  }
}
