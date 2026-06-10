import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class OverviewCards extends StatelessWidget {
  final int totalPresent;
  final int totalLate;
  final int totalAbsent;
  final int totalRecords;
  final int totalPossible;

  const OverviewCards({
    super.key,
    required this.totalPresent,
    required this.totalLate,
    required this.totalAbsent,
    required this.totalRecords,
    this.totalPossible = 0,
  });

  double get attendanceRate =>
      totalRecords > 0 ? (totalPresent / totalRecords) * 100 : 0;

  double get lateRate =>
      totalRecords > 0 ? (totalLate / totalRecords) * 100 : 0;

  double get absentRate =>
      totalPossible > 0 ? (totalAbsent / totalPossible) * 100 : 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_rounded,
                label: 'Present',
                value: totalPresent.toString(),
                rate: attendanceRate,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.warning_amber_rounded,
                label: 'Late',
                value: totalLate.toString(),
                rate: lateRate,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.cancel_rounded,
                label: 'Absent',
                value: totalAbsent.toString(),
                rate: absentRate,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _RateCard(
              rate: attendanceRate,
              total: totalRecords,
            )),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double rate;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.rate,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: rate / 100,
                backgroundColor: Colors.grey.shade200,
                color: color,
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  final double rate;
  final int total;

  const _RateCard({required this.rate, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = rate >= 75
        ? AppColors.success
        : rate >= 50
            ? AppColors.warning
            : AppColors.error;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      value: rate / 100,
                      strokeWidth: 5,
                      backgroundColor: Colors.grey.shade200,
                      color: color,
                    ),
                  ),
                  Text(
                    '${rate.toStringAsFixed(0)}%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Attendance',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Text(
              '$total records',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
