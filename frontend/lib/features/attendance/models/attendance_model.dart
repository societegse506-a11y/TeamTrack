import '../../members/models/member.dart';

enum AttendanceStatus { notChecked, present, late, outsideZone }

class MemberAttendance {
  final Member member;
  final AttendanceStatus morningStatus;
  final AttendanceStatus afternoonStatus;
  final String? morningTime;
  final String? afternoonTime;

  MemberAttendance({
    required this.member,
    this.morningStatus = AttendanceStatus.notChecked,
    this.afternoonStatus = AttendanceStatus.notChecked,
    this.morningTime,
    this.afternoonTime,
  });

  bool get hasMorningCheckIn => morningStatus != AttendanceStatus.notChecked;
  bool get hasAfternoonCheckIn => afternoonStatus != AttendanceStatus.notChecked;
}

class AttendanceRecord {
  final String id;
  final String memberId;
  final String session;
  final DateTime date;
  final String status;
  final String? checkInTime;
  final Map<String, dynamic>? location;

  AttendanceRecord({
    required this.id,
    required this.memberId,
    required this.session,
    required this.date,
    required this.status,
    this.checkInTime,
    this.location,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['_id'] ?? json['id'] ?? '',
      memberId: _extractMemberId(json),
      session: json['session'] ?? 'morning',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'present',
      checkInTime: json['checkInTime'] as String?,
      location: json['location'] as Map<String, dynamic>?,
    );
  }

  static String _extractMemberId(Map<String, dynamic> json) {
    final member = json['member'];
    if (member is Map<String, dynamic>) {
      return member['_id'] as String? ?? member['id'] as String? ?? '';
    }
    if (member is String) return member;
    return json['_id'] as String? ?? '';
  }

  AttendanceStatus get attendanceStatus {
    switch (status) {
      case 'present':
        return AttendanceStatus.present;
      case 'late':
        return AttendanceStatus.late;
      case 'outside_zone':
        return AttendanceStatus.outsideZone;
      default:
        return AttendanceStatus.notChecked;
    }
  }
}

class CheckInResult {
  final bool success;
  final String message;
  final String status;
  final int? distance;
  final int? allowedRadius;

  CheckInResult({
    required this.success,
    required this.message,
    required this.status,
    this.distance,
    this.allowedRadius,
  });

  AttendanceStatus get attendanceStatus {
    switch (status) {
      case 'present':
        return AttendanceStatus.present;
      case 'late':
        return AttendanceStatus.late;
      case 'outside_zone':
        return AttendanceStatus.outsideZone;
      default:
        return AttendanceStatus.notChecked;
    }
  }

  factory CheckInResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return CheckInResult(
      success: json['success'] == true,
      message: json['message'] ?? '',
      status: data?['status'] ?? '',
      distance: data?['distance'] as int?,
      allowedRadius: data?['allowedRadius'] as int?,
    );
  }
}

class SessionConfig {
  final String session;
  final String label;
  final String start;
  final String end;

  SessionConfig({
    required this.session,
    required this.label,
    required this.start,
    required this.end,
  });

  bool get isMorning => session == 'morning';

  String get displayTime => '$start - $end';
}
