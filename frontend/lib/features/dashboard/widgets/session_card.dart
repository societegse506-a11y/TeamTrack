import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class SessionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int present;
  final int late;
  final int total;
  final LinearGradient gradient;

  const SessionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.present,
    required this.late,
    required this.total,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checkedIn = present + late;
    final rate = total > 0 ? checkedIn / total : 0.0;
    final iconColor = gradient.colors.first;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: gradient.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SessionStat(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                    label: 'Present',
                    value: present.toString(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SessionStat(
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    label: 'Late',
                    value: late.toString(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SessionStat(
                    icon: Icons.cancel_rounded,
                    color: AppColors.error,
                    label: 'Absent',
                    value: (total - checkedIn).toString(),
                  ),
                ),
              ],
            ),
            if (total > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: rate,
                  backgroundColor: Colors.grey.shade200,
                  color: iconColor,
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _SessionStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
