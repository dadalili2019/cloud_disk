// lib/main.dart
import 'dart:async';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';

import './router/router.dart';
import './services/tray.dart';
import 'theme/theme_controller.dart';
import 'workbench/workbench_runtime.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final theme = ThemeController();
  await theme.load();

  runApp(ThemeScope(
    controller: theme,
    child: MyApp(theme: theme),
  ));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initDesktopStuff();
    unawaited(_initWorkbenchRouteTracking());
  });
}

Future<void> _initWorkbenchRouteTracking() async {
  try {
    final runtime = await WorkbenchRuntime.instance;
    void rememberRoute() {
      unawaited(
        runtime.settingsService.rememberLastActiveLocation(router.location),
      );
    }

    rememberRoute();
    router.addListener(rememberRoute);
  } catch (_) {
    // Settings route tracking is non-critical and must not block app startup.
  }
}

Future<void> _initDesktopStuff() async {
  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(1000, 600);
    win.minSize = initialSize;
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = 'cloud_disk';
    win.show();
  });

  unawaited(initSystemTray());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.theme});

  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: theme,
      builder: (_, __) {
        return FluentApp.router(
          debugShowCheckedModeBanner: false,
          title: 'cloud_disk',
          themeMode: theme.mode,
          theme: theme
              .buildTheme(Brightness.light)
              .copyWith(
                scaffoldBackgroundColor: theme.palette.appBackground,
              ),
          darkTheme: theme.buildTheme(Brightness.dark),
          routeInformationProvider: router.routeInformationProvider,
          routeInformationParser: router.routeInformationParser,
          routerDelegate: router.routerDelegate,
        );
      },
    );
  }
}
