import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? height;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.height,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Card(
      elevation: 0,
      color: color ?? theme.cardTheme.color,
      margin: margin ?? EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Container(
        height: height,
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
