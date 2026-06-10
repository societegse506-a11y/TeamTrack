import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback? onPressed;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.onPressed,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = (isLoading || isDisabled) ? null : onPressed;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: effectiveOnPressed == null
              ? LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade400],
                )
              : AppColors.gradientPrimary,
          boxShadow: effectiveOnPressed == null
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(60),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: effectiveOnPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final bool isLoading;
  final VoidCallback? onPressed;

  const GradientButton({
    super.key,
    required this.label,
    required this.icon,
    required this.gradient,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isLoading ? gradient.withOpacity(0.7) : gradient,
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withAlpha(60),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: isLoading ? null : onPressed,
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: Colors.white, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
