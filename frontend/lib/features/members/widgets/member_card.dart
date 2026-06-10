import 'package:flutter/material.dart';
import '../models/member.dart';
import '../../../theme/app_colors.dart';

class MemberCard extends StatelessWidget {
  final Member member;
  final bool isLateFrequent;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewHistory;

  const MemberCard({
    super.key,
    required this.member,
    this.isLateFrequent = false,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onViewHistory,
  });

  Color get _accentColor {
    if (isLateFrequent) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 4, color: _accentColor),
          InkWell(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: _accentColor.withAlpha(20),
                    child: Text(
                      member.initials,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                member.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isLateFrequent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Frequent Late',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.email_outlined,
                                size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                member.email.isNotEmpty
                                    ? member.email
                                    : 'No email',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined,
                                size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              member.telephone,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _IconButton(
                        icon: Icons.calendar_month_outlined,
                        color: AppColors.primary,
                        tooltip: 'View History',
                        onTap: onViewHistory,
                      ),
                      _IconButton(
                        icon: Icons.edit_outlined,
                        color: AppColors.warning,
                        tooltip: 'Edit',
                        onTap: onEdit,
                      ),
                      _IconButton(
                        icon: Icons.delete_outline,
                        color: AppColors.error,
                        tooltip: 'Delete',
                        onTap: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}
