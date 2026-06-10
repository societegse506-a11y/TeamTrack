import 'package:flutter/material.dart';
import '../../../shared/notifiers/settings_notifier.dart';
import '../../../theme/app_colors.dart';

class SessionSelector extends StatelessWidget {
  final void Function(String session) onSelected;

  const SessionSelector({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = SettingsNotifier.instance.value;
    final afternoonParts = settings.afternoonStart.split(':');
    final afternoonHour = int.tryParse(afternoonParts[0]) ?? 14;
    final hour = DateTime.now().hour;
    final isMorningTime = hour < afternoonHour;
    final pad = MediaQuery.of(context).size.width > 600 ? 24.0 : 16.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, 32),
      children: [
        const SizedBox(height: 48),
        Container(
          padding: EdgeInsets.fromLTRB(pad, 48, pad, 24),
          decoration: const BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a session to begin',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        _SessionCard(
          icon: Icons.wb_sunny,
          label: 'Morning Session',
          time: '${settings.morningStart} - ${settings.morningEnd}',
          gradient: AppColors.gradientWarning,
          isRecommended: isMorningTime,
          recommendedLabel: isMorningTime ? 'Current session' : null,
          innerPad: pad,
          onTap: () => onSelected('morning'),
        ),
        const SizedBox(height: 16),
        _SessionCard(
          icon: Icons.nights_stay,
          label: 'Afternoon Session',
          time: '${settings.afternoonStart} - ${settings.afternoonEnd}',
          gradient: AppColors.gradientInfo,
          isRecommended: !isMorningTime,
          recommendedLabel: !isMorningTime ? 'Current session' : null,
          innerPad: pad,
          onTap: () => onSelected('afternoon'),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final LinearGradient gradient;
  final bool isRecommended;
  final String? recommendedLabel;
  final double innerPad;
  final VoidCallback onTap;

  const _SessionCard({
    required this.icon,
    required this.label,
    required this.time,
    required this.gradient,
    this.isRecommended = false,
    this.recommendedLabel,
    this.innerPad = 24,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = gradient.colors.first;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isRecommended ? iconColor : Colors.grey.shade200,
              width: isRecommended ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(innerPad),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: gradient.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: iconColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                recommendedLabel ?? '',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: iconColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
