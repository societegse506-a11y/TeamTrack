import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget phone;
  final Widget? tablet;
  final Widget? desktop;

  const Responsive({
    super.key,
    required this.phone,
    this.tablet,
    this.desktop,
  });

  static const double phoneBreakpoint = 600;
  static const double tabletBreakpoint = 900;

  static bool isPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < phoneBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= phoneBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static double padding(BuildContext context) =>
      isPhone(context) ? 16.0 : 24.0;

  static double cardPadding(BuildContext context) =>
      isPhone(context) ? 16.0 : 20.0;

  static double spacing(BuildContext context) =>
      isPhone(context) ? 12.0 : 16.0;

  static double gridSpacing(BuildContext context) =>
      isPhone(context) ? 8.0 : 12.0;

  static int gridColumns(BuildContext context) =>
      isPhone(context) ? 1 : (isTablet(context) ? 2 : 3);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= tabletBreakpoint) {
          return desktop ?? tablet ?? phone;
        }
        if (constraints.maxWidth >= phoneBreakpoint) {
          return tablet ?? phone;
        }
        return phone;
      },
    );
  }
}
