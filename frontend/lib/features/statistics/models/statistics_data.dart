class MemberStat {
  final String id;
  final String nom;
  final String prenom;
  final int present;
  final int late;
  final int absent;
  final int total;
  final double rate;

  MemberStat({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.present,
    required this.late,
    required this.absent,
    required this.total,
    this.rate = 0,
  });

  factory MemberStat.fromJson(Map<String, dynamic> json) {
    return MemberStat(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      present: (json['present'] as num?)?.toInt() ?? 0,
      late: (json['late'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
    );
  }

  String get fullName => '$prenom $nom';

  double get attendanceRate => rate;
}

class MonthlyStat {
  final int year;
  final int month;
  final int present;
  final int late;
  final int absent;
  final int total;

  MonthlyStat({
    required this.year,
    required this.month,
    required this.present,
    required this.late,
    required this.absent,
    required this.total,
  });

  String get label {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  double get attendanceRate => total > 0 ? (present / total) * 100 : 0;
}

class StatisticsData {
  final int totalPresent;
  final int totalLate;
  final int totalAbsent;
  final int totalRecords;
  final int totalPossible;
  final List<MemberStat> memberStats;
  final List<MonthlyStat> monthlyStats;

  StatisticsData({
    required this.totalPresent,
    required this.totalLate,
    required this.totalAbsent,
    required this.totalRecords,
    this.totalPossible = 0,
    required this.memberStats,
    required this.monthlyStats,
  });

  double get attendanceRate =>
      totalRecords > 0 ? (totalPresent / totalRecords) * 100 : 0;

  double get lateRate =>
      totalRecords > 0 ? (totalLate / totalRecords) * 100 : 0;

  double get absentRate =>
      totalPossible > 0 ? (totalAbsent / totalPossible) * 100 : 0;
}
