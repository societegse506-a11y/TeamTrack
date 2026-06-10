import 'package:flutter/material.dart';
import 'navigation/auth_notifier.dart';
import 'navigation/app_router.dart';
import 'shared/notifiers/settings_notifier.dart';
import 'theme/app_theme.dart';

final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthNotifier.instance.init();
  SettingsNotifier.instance.load();
  runApp(const TeamTrackApp());
}

class TeamTrackApp extends StatelessWidget {
  const TeamTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, _) {
        return MaterialApp.router(
          title: 'TeamTrack',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          routerConfig: appRouter,
        );
      },
    );
  }
}
