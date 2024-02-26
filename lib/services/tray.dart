import 'dart:io';
import 'package:system_tray/system_tray.dart';

Future<void> initSystemTray() async {
  String path = Platform.isWindows ? 'assets/tray.ico' : 'assets/tray.png';

  final AppWindow appWindow = AppWindow();
  final SystemTray systemTray = SystemTray();

  // 初始化SystemTray
  await systemTray.initSystemTray(
    title: "NetDisk",
    iconPath: path,
  );

  // 创建Menu
  final Menu menu = Menu();
  await menu.buildFrom([
    MenuItemLabel(label: '打开主面板', onClicked: (menuItem) => appWindow.show()),
    MenuItemLabel(
        label: '打开网页版',
        onClicked: (menuItem) {
          print("打开网页版");
        }),
    MenuSeparator(),
    MenuItemLabel(
        label: '设置',
        onClicked: (menuItem) {
          print("设置");
        }),
    MenuItemLabel(
        label: '检测更新',
        onClicked: (menuItem) {
          print("检测更新");
        }),
    MenuSeparator(),
    MenuItemLabel(
        label: '关于',
        onClicked: (menuItem) {
          print("关于");
        }),
    MenuItemLabel(
        label: '帮助中心',
        onClicked: (menuItem) {
          print("帮助中心");
        }),
    MenuSeparator(),
    MenuItemLabel(label: '退出网盘', onClicked: (menuItem) => appWindow.close()),
  ]);

  // 创建 context menu

  await systemTray.setContextMenu(menu);

  // 处理system tray 事件
  systemTray.registerSystemTrayEventHandler((eventName) {
    print("eventName: $eventName");
    if (eventName == kSystemTrayEventClick) {
      Platform.isWindows ? appWindow.show() : systemTray.popUpContextMenu();
    } else if (eventName == kSystemTrayEventRightClick) {
      Platform.isWindows ? systemTray.popUpContextMenu() : appWindow.show();
    }
  });
}
