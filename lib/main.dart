// lib/main.dart
import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

import './router/router.dart';
import './services/tray.dart';
import 'theme/theme_controller.dart'; // ← 新增：全局主题控制器

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 载入主题设置（从 SharedPreferences 恢复）
  final theme = ThemeController();
  await theme.load();

  // 先把带主题作用域的应用跑起来
  runApp(ThemeScope(
    controller: theme,
    child: MyApp(theme: theme),
  ));

  // 首帧后再做桌面相关初始化，避免阻塞首屏
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initDesktopStuff();
  });
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

  // 托盘后台初始化
  unawaited(initSystemTray());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.theme});

  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    // 监听主题变化，实时重建全局 App
    return AnimatedBuilder(
      animation: theme,
      builder: (_, __) {
        return FluentApp.router(
          debugShowCheckedModeBanner: false,
          title: 'cloud_disk',

          // 全局主题（浅色/深色/跟随系统）
          themeMode: theme.mode,
          theme: theme
              .buildTheme(Brightness.light)
              .copyWith(
                scaffoldBackgroundColor: theme.palette.appBackground,
              ),
          darkTheme: theme.buildTheme(Brightness.dark),

          // 如果项目里还混用了少量 Material 组件，打开下面这段可让字体也同步
          // builder: (context, child) => Theme(
          //   data: ThemeData(fontFamily: ThemeScope.of(context).fontFamily),
          //   child: child!,
          // ),

          routeInformationProvider: router.routeInformationProvider,
          routeInformationParser: router.routeInformationParser,
          routerDelegate: router.routerDelegate,
        );
      },
    );
  }
}
