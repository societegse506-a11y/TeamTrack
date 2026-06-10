import 'package:flutter/material.dart';
import '../models/statistics_data.dart';
import '../../../theme/app_colors.dart';

class MemberStatsList extends StatelessWidget {
  final List<MemberStat> memberStats;

  const MemberStatsList({super.key, required this.memberStats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (memberStats.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No member data available',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
        ),
      );
    }

    final sorted = List<MemberStat>.from(memberStats)
      ..sort((a, b) => b.present.compareTo(a.present));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Member Breakdown',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sorted.map((stat) => _MemberRow(stat: stat)),
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final MemberStat stat;

  const _MemberRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withAlpha(20),
            child: Text(
              _initials(stat.prenom, stat.nom),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _MiniBadge(
                        color: AppColors.success,
                        label: '${stat.present}'),
                    const SizedBox(width: 6),
                    _MiniBadge(
                        color: AppColors.warning,
                        label: '${stat.late}'),
                    const SizedBox(width: 6),
                    _MiniBadge(
                        color: AppColors.error,
                        label: '${stat.absent}'),
                    const Spacer(),
                    Text(
                      '${stat.attendanceRate.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: stat.attendanceRate >= 75
                            ? AppColors.success
                            : stat.attendanceRate >= 50
                                ? AppColors.warning
                                : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String prenom, String nom) {
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    return '$p$n'.toUpperCase();
  }
}

class _MiniBadge extends StatelessWidget {
  final Color color;
  final String label;

  const _MiniBadge({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
