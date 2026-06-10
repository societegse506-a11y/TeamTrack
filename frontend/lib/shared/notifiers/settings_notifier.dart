import 'package:flutter/foundation.dart';
import '../../features/settings/models/settings_model.dart';
import '../../features/settings/services/settings_service.dart';

class SettingsNotifier extends ValueNotifier<WorkSettings> {
  static final SettingsNotifier _instance = SettingsNotifier._();
  static SettingsNotifier get instance => _instance;

  SettingsNotifier._()
      : super(WorkSettings(
          morningStart: '08:00',
          morningEnd: '12:00',
          afternoonStart: '14:00',
          afternoonEnd: '18:00',
          lateToleranceMinutes: 15,
          gpsRadius: 500,
          workingDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
        ));

  final _service = SettingsService();

  Future<void> load() async {
    final s = await _service.load();
    value = s;
  }

  Future<void> refresh() async {
    await load();
  }
}
