import 'package:fluent_ui/fluent_ui.dart';
import "./router/router.dart";
import 'package:bitsdojo_window/bitsdojo_window.dart';
import './services/tray.dart';

void main() async {
  //必须配置
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());

  //配置窗口大小
  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(1000, 600);
    win.minSize = initialSize;
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = "Shared cloud storage";
    win.show();
  });

  //初始化系统托盘
  await initSystemTray();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return FluentApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: FluentThemeData(
        accentColor: Colors.blue, //主题颜色
        scaffoldBackgroundColor: Colors.white, //背景颜色
        // navigationPaneTheme: NavigationPaneThemeData(//左侧导航颜色
        //   backgroundColor: Colors.red,
        // )
      ),
      //挂载路由
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
    );
  }
}
