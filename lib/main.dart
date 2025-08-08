import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import './router/router.dart';
import './services/tray.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 先画 UI 壳
  runApp(const MyApp());

  // 首帧绘制后再初始化桌面相关（避免阻塞首屏）
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initDesktopStuff();
  });
}

Future<void> _initDesktopStuff() async {
  // 窗口配置
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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: FluentThemeData(
        accentColor: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
    );
  }
}
