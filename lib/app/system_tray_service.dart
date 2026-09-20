import 'dart:io';

import 'package:system_tray/system_tray.dart';

/// 初始化 Personal Workbench 系统托盘。
///
/// 托盘只保留当前真正可用的操作，不放没有实现的占位菜单。
Future<void> initSystemTray() async {
  if (_TrayState.initialized) return;
  _TrayState.initialized = true;

  final systemTray = SystemTray();
  final appWindow = AppWindow();

  try {
    await systemTray.initSystemTray(
      title: 'Personal Workbench',
      iconPath: Platform.isWindows ? 'assets/tray.ico' : 'assets/tray.png',
      toolTip: 'Personal Workbench',
    );

    final menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
        label: '打开 Personal Workbench',
        onClicked: (_) => appWindow.show(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: '退出',
        onClicked: (_) => appWindow.close(),
      ),
    ]);
    await systemTray.setContextMenu(menu);

    systemTray.registerSystemTrayEventHandler((event) {
      if (event == kSystemTrayEventClick) {
        if (Platform.isWindows) {
          appWindow.show();
        } else {
          systemTray.popUpContextMenu();
        }
        return;
      }

      if (event == kSystemTrayEventRightClick) {
        if (Platform.isWindows) {
          systemTray.popUpContextMenu();
        } else {
          appWindow.show();
        }
      }
    });
  } catch (_) {
    // 初始化失败时允许后续重试；托盘失败不能影响主应用启动。
    _TrayState.initialized = false;
  }
}

class _TrayState {
  static bool initialized = false;
}
