import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String initials;
  final double radius;
  final String? imageUrl;

  const ProfileAvatar({
    super.key,
    required this.initials,
    this.radius = 28,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withAlpha(20),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.5,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class LargeAvatar extends StatelessWidget {
  final String initials;
  final double size;

  const LargeAvatar({
    super.key,
    required this.initials,
    this.size = 88,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
