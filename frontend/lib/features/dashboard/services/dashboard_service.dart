import 'package:flutter/foundation.dart';
import '../../../shared/api/api_client.dart';
import '../models/dashboard_data.dart';
import '../../statistics/models/statistics_data.dart';
import 'user_service.dart';

class DashboardService {
  Future<UserInfo> fetchCurrentUser() async {
    try {
      final body = await ApiClient.getSafe('/auth/me', timeout: ApiClient.longTimeout);
      if (body != null) {
        final data = body['data'] ?? body;
        if (data is Map<String, dynamic>) {
          final user = UserInfo.fromJson(data);
          await UserService.saveUser(user);
          return user;
        }
      }
    } catch (e) {
      debugPrint('Dashboard: failed to load user — $e');
    }

    final cached = await UserService.loadUser();
    if (cached != null) return cached;

    return UserInfo(id: '', nom: '', prenom: '', email: '', telephone: '');
  }

  Future<DashboardData> fetchDashboard() async {
    final user = await fetchCurrentUser();

    final results = await Future.wait([
      ApiClient.getSafe('/attendance/dashboard-stats', timeout: ApiClient.longTimeout),
      ApiClient.getSafe('/settings', timeout: ApiClient.longTimeout),
    ]);

    final dashRes = results[0];
    final settingsRes = results[1];

    AttendanceConfig config = AttendanceConfig(
      morningStart: '08:00',
      morningEnd: '12:00',
      afternoonStart: '14:00',
      afternoonEnd: '18:00',
      lateToleranceMinutes: 15,
    );

    double workplaceLat = 0.0;
    double workplaceLng = 0.0;

    if (settingsRes != null) {
      try {
        final settingsData = settingsRes['data'] as Map<String, dynamic>? ?? settingsRes;
        config = AttendanceConfig.fromJson(settingsData);
        final wl = settingsData['workplaceLocation'] as Map<String, dynamic>?;
        if (wl != null) {
          workplaceLat = (wl['lat'] as num?)?.toDouble() ?? 0.0;
          workplaceLng = (wl['lng'] as num?)?.toDouble() ?? 0.0;
        }
      } catch (e) {
        debugPrint('Dashboard: settings parse error — $e');
      }
    }

    if (workplaceLat == 0.0 && workplaceLng == 0.0) {
      workplaceLat = user.lat;
      workplaceLng = user.lng;

      if (user.lat != 0.0 && user.lng != 0.0 && settingsRes == null) {
        try {
          await ApiClient.postSafe('/settings', body: {
            'workplaceLocation': {'lat': user.lat, 'lng': user.lng},
          });
        } catch (_) {}
      }
    }

    final d = dashRes?['data'] as Map<String, dynamic>? ?? {};

    final totalMembers = (d['totalMembers'] as num?)?.toInt() ?? 0;
    final attendanceRate = (d['attendanceRate'] as num?)?.toDouble() ?? 0.0;
    final overallRate = (d['overallRate'] as num?)?.toDouble() ?? 0.0;
    final lateRate = (d['lateRate'] as num?)?.toDouble() ?? 0.0;
    final outsideRate = (d['outsideRate'] as num?)?.toDouble() ?? 0.0;

    final todayRaw = d['today'] as Map<String, dynamic>? ?? {};
    final todayMorningPresent = (todayRaw['morningPresent'] as num?)?.toInt() ?? 0;
    final todayMorningLate = (todayRaw['morningLate'] as num?)?.toInt() ?? 0;
    final todayAfternoonPresent = (todayRaw['afternoonPresent'] as num?)?.toInt() ?? 0;
    final todayAfternoonLate = (todayRaw['afternoonLate'] as num?)?.toInt() ?? 0;

    final totalsRaw = d['totals'] as Map<String, dynamic>? ?? {};
    final totalPresent = (totalsRaw['present'] as num?)?.toInt() ?? 0;
    final totalLate = (totalsRaw['late'] as num?)?.toInt() ?? 0;
    final totalAbsent = (totalsRaw['absent'] as num?)?.toInt() ?? 0;
    final totalRecords = (totalsRaw['records'] as num?)?.toInt() ?? 0;

    final memberStatsRaw = d['memberStats'] as List<dynamic>? ?? [];
    final memberStats = memberStatsRaw
        .map((e) => MemberStat.fromJson(e as Map<String, dynamic>))
        .where((s) => s.id.isNotEmpty)
        .toList();

    final monthlyStatsRaw = d['monthlyStats'] as List<dynamic>? ?? [];
    final monthlyStats = monthlyStatsRaw.map((e) {
      final m = e as Map<String, dynamic>;
      final ym = (m['yearMonth'] as String?) ?? '';
      final parts = ym.split('-');
      final year = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? DateTime.now().year;
      final month = int.tryParse(parts.length > 1 ? parts[1] : '') ?? DateTime.now().month;
      return MonthlyStat(
        year: year,
        month: month,
        present: (m['present'] as num?)?.toInt() ?? 0,
        late: (m['late'] as num?)?.toInt() ?? 0,
        absent: (m['absent'] as num?)?.toInt() ?? 0,
        total: (m['total'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    return DashboardData(
      user: user,
      totalMembers: totalMembers,
      morningPresent: todayMorningPresent,
      morningLate: todayMorningLate,
      afternoonPresent: todayAfternoonPresent,
      afternoonLate: todayAfternoonLate,
      config: config,
      workplaceLat: workplaceLat,
      workplaceLng: workplaceLng,
      totalPresent: totalPresent,
      totalLate: totalLate,
      totalAbsent: totalAbsent,
      totalRecords: totalRecords,
      totalPossible: totalPresent + totalLate + totalAbsent,
      memberStats: memberStats,
      monthlyStats: monthlyStats,
      attendanceRate: attendanceRate,
      overallRate: overallRate,
      lateRate: lateRate,
      outsideRate: outsideRate,
    );
  }
}
