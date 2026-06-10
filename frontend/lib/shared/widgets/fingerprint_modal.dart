import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Visual-only fingerprint confirmation modal.
/// No real biometric authentication — just a smooth animated UI.
Future<bool> showFingerprintModal(
  BuildContext context, {
  required String memberName,
  required String sessionLabel,
  required String sessionTime,
  required bool isMorning,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _FingerprintModal(
      memberName: memberName,
      sessionLabel: sessionLabel,
      sessionTime: sessionTime,
      isMorning: isMorning,
    ),
  );
  return result ?? false;
}

class _FingerprintModal extends StatefulWidget {
  final String memberName;
  final String sessionLabel;
  final String sessionTime;
  final bool isMorning;

  const _FingerprintModal({
    required this.memberName,
    required this.sessionLabel,
    required this.sessionTime,
    required this.isMorning,
  });

  @override
  State<_FingerprintModal> createState() => _FingerprintModalState();
}

class _FingerprintModalState extends State<_FingerprintModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionColor =
        widget.isMorning ? AppColors.warning : AppColors.secondary;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

          // Pulsing fingerprint icon
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnim.value,
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(50),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fingerprint,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Confirm your identity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Place your finger to check in',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          // Member info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withAlpha(20),
                  child: Text(
                    widget.memberName.isNotEmpty
                        ? widget.memberName
                            .split(' ')
                            .map((e) => e.isNotEmpty ? e[0] : '')
                            .join()
                            .toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
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
                        widget.memberName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            widget.isMorning
                                ? Icons.wb_sunny
                                : Icons.nights_stay,
                            size: 14,
                            color: sessionColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.sessionLabel} — ${widget.sessionTime}',
                            style: TextStyle(
                              fontSize: 12,
                              color: sessionColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.fingerprint, size: 22),
              label: const Text('Confirm Check-In'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Cancel button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
