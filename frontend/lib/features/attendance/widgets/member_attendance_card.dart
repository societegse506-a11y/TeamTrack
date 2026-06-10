import 'package:flutter/material.dart';
import '../../members/models/member.dart';
import '../models/attendance_model.dart';
import '../../../theme/app_colors.dart';

class MemberAttendanceCard extends StatelessWidget {
  final Member member;
  final AttendanceStatus status;
  final String session;
  final bool isLoading;
  final bool isSessionOpen;
  final VoidCallback? onTap;

  const MemberAttendanceCard({
    super.key,
    required this.member,
    required this.status,
    required this.session,
    this.isLoading = false,
    this.isSessionOpen = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canTap = onTap != null && !isLoading && isSessionOpen;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: canTap ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: _isCheckedIn ? _statusColor.withAlpha(50) : Colors.grey.shade200,
                width: _isCheckedIn ? 1.5 : 1,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: isDark
                            ? _statusColor.withAlpha(30)
                            : _statusColor.withAlpha(15),
                        child: Text(
                          member.initials,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: _statusColor,
                          ),
                        ),
                      ),
                      if (_isCheckedIn)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _statusColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              status == AttendanceStatus.present
                                  ? Icons.check
                                  : Icons.access_time,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      member.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _statusColor,
                        ),
                      ),
                    ),
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 6),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _isCheckedIn =>
      status == AttendanceStatus.present || status == AttendanceStatus.late;

  Color get _statusColor {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.late:
        return AppColors.warning;
      case AttendanceStatus.outsideZone:
        return AppColors.error;
      case AttendanceStatus.notChecked:
        return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.outsideZone:
        return 'Outside Zone';
      case AttendanceStatus.notChecked:
        return 'Tap to check in';
    }
  }
}
