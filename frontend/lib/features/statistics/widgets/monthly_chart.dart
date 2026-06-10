import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/statistics_data.dart';
import '../../../theme/app_colors.dart';

class MonthlyChart extends StatelessWidget {
  final List<MonthlyStat> monthlyStats;

  const MonthlyChart({super.key, required this.monthlyStats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (monthlyStats.isEmpty) {
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
              'No monthly data available',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
        ),
      );
    }

    final sorted = List<MonthlyStat>.from(monthlyStats)
      ..sort((a, b) {
        final c = a.year.compareTo(b.year);
        return c != 0 ? c : a.month.compareTo(b.month);
      });

    final maxY = sorted
        .map((m) => [m.present, m.late, m.absent].reduce((a, b) => a > b ? a : b))
        .reduce((a, b) => a > b ? a : b);

    final totalPresent = sorted.fold(0, (s, m) => s + m.present);
    final totalLate = sorted.fold(0, (s, m) => s + m.late);
    final totalAbsent = sorted.fold(0, (s, m) => s + m.absent);
    final totalAll = totalPresent + totalLate + totalAbsent;
    final overallRate = totalAll > 0 ? (totalPresent / totalAll * 100) : 0.0;

    MonthlyStat? bestMonth;
    double bestRate = -1;
    for (final m in sorted) {
      final r = m.total > 0 ? (m.present / m.total * 100) : 0.0;
      if (r > bestRate) {
        bestRate = r;
        bestMonth = m;
      }
    }

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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientInfo.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bar_chart_rounded,
                      size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  'Monthly Statistics',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final stat = sorted[groupIndex];
                        final label = rodIndex == 0
                            ? 'Present'
                            : rodIndex == 1
                                ? 'Late'
                                : 'Absent';
                        return BarTooltipItem(
                          '${stat.label} ${stat.year}\n$label: ${rod.toY.toInt()}',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= sorted.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              sorted[idx].label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 10 ? (maxY / 5).ceilToDouble() : 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  groupsSpace: 8,
                  barGroups: sorted.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final stat = entry.value;
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: stat.present.toDouble(),
                          color: AppColors.success,
                          width: 8,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: stat.late.toDouble(),
                          color: AppColors.warning,
                          width: 8,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: stat.absent.toDouble(),
                          color: AppColors.error,
                          width: 8,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                duration: const Duration(milliseconds: 300),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: AppColors.success, label: 'Present'),
                const SizedBox(width: 16),
                _LegendDot(color: AppColors.warning, label: 'Late'),
                const SizedBox(width: 16),
                _LegendDot(color: AppColors.error, label: 'Absent'),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 12),
            _SummaryRow(
              label: 'Total records',
              value: '$totalAll',
              icon: Icons.calendar_month,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Attendance rate',
              value: '${overallRate.toStringAsFixed(1)}%',
              icon: Icons.trending_up,
              color: AppColors.success,
            ),
            if (bestMonth != null) ...[
              const SizedBox(height: 8),
              _SummaryRow(
                label: 'Best month',
                value: '${bestMonth.label} ${bestMonth.year}',
                icon: Icons.emoji_events,
                color: AppColors.warning,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Present',
                    value: '$totalPresent',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                    label: 'Late',
                    value: '$totalLate',
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                    label: 'Absent',
                    value: '$totalAbsent',
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
