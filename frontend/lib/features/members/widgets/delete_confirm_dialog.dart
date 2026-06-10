import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

Future<bool> showDeleteConfirmDialog(
  BuildContext context, {
  required String memberName,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
          SizedBox(width: 10),
          Text(
            'Delete Member',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to delete $memberName? This action cannot be undone.',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}
