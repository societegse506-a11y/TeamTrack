import '../../statistics/models/statistics_data.dart';

class UserInfo {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final double lat;
  final double lng;

  UserInfo({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    this.lat = 0.0,
    this.lng = 0.0,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    final position = json['position'] as Map<String, dynamic>?;
    return UserInfo(
      id: json['_id'] ?? json['id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'] ?? '',
      lat: (position?['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (position?['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get fullName => '$prenom $nom';
}

class AttendanceConfig {
  final String morningStart;
  final String morningEnd;
  final String afternoonStart;
  final String afternoonEnd;
  final int lateToleranceMinutes;

  AttendanceConfig({
    required this.morningStart,
    required this.morningEnd,
    required this.afternoonStart,
    required this.afternoonEnd,
    required this.lateToleranceMinutes,
  });

  factory AttendanceConfig.fromJson(Map<String, dynamic> json) {
    return AttendanceConfig(
      morningStart: json['morningStart'] ?? '08:00',
      morningEnd: json['morningEnd'] ?? '12:00',
      afternoonStart: json['afternoonStart'] ?? '14:00',
      afternoonEnd: json['afternoonEnd'] ?? '18:00',
      lateToleranceMinutes: json['lateToleranceMinutes'] ?? 15,
    );
  }
}

class DashboardData {
  final UserInfo? user;
  final int totalMembers;
  final int morningPresent;
  final int morningLate;
  final int afternoonPresent;
  final int afternoonLate;
  final AttendanceConfig? config;

  final int totalPresent;
  final int totalLate;
  final int totalAbsent;
  final int totalRecords;
  final int totalPossible;
  final List<MemberStat> memberStats;
  final List<MonthlyStat> monthlyStats;

  // Pre-computed by backend, clamped 0–100
  final double attendanceRate;
  final double overallRate;
  final double lateRate;
  final double outsideRate;

  DashboardData({
    this.user,
    required this.totalMembers,
    required this.morningPresent,
    required this.morningLate,
    required this.afternoonPresent,
    required this.afternoonLate,
    this.config,
    this.totalPresent = 0,
    this.totalLate = 0,
    this.totalAbsent = 0,
    this.totalRecords = 0,
    this.totalPossible = 0,
    this.memberStats = const [],
    this.monthlyStats = const [],
    this.attendanceRate = 0,
    this.overallRate = 0,
    this.lateRate = 0,
    this.outsideRate = 0,
  });

  int get morningTotal => morningPresent + morningLate;
  int get afternoonTotal => afternoonPresent + afternoonLate;
}
