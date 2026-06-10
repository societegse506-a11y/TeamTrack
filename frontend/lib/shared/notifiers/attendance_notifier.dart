import 'package:flutter/foundation.dart';

/// Global notifier that fires after any attendance check-in.
/// Other screens (dashboard, members, statistics) listen to this
/// to reload their data automatically.
final attendanceRefreshNotifier = ValueNotifier<int>(0);
