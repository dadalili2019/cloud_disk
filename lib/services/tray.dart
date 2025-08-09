// lib/services/tray.dart
import 'dart:async' show unawaited;
import 'dart:io';
import 'package:system_tray/system_tray.dart';

/// 托盘初始化（优化版）：
/// - 首帧后调用，避免卡首屏（请在 main.dart 里以 addPostFrameCallback 触发）
/// - 先挂“轻菜单”，用户立刻可用；完整菜单稍后热替换
/// - 防重复初始化（多次调用也只会生效一次）
/// - 尽量减少同步/串行 await，缩短冷启动阻塞
Future<void> initSystemTray() async {
  if (_TrayState._inited) return; // 防止重复初始化
  _TrayState._inited = true;

  final systemTray = SystemTray();
  final appWindow = AppWindow();

  // 1) 必要初始化（必须 await）
  final iconPath = Platform.isWindows ? 'assets/tray.ico' : 'assets/tray.png';
  await systemTray.initSystemTray(
    title: 'NetDisk',
    iconPath: iconPath,
    toolTip: 'NetDisk',
  );

  // 2) 先挂一个轻量菜单（打开/退出），让用户立刻可操作
  final lightMenu = Menu();
  await lightMenu.buildFrom([
    MenuItemLabel(label: '打开主面板', onClicked: (_) => appWindow.show()),
    MenuSeparator(),
    MenuItemLabel(label: '退出', onClicked: (_) => appWindow.close()),
  ]);
  await systemTray.setContextMenu(lightMenu);

  // 3) 注册事件（很轻，立即挂上）
  systemTray.registerSystemTrayEventHandler((event) {
    // 左键/右键在 Win/Mac 行为不同，这里维持你原本逻辑
    if (event == kSystemTrayEventClick) {
      Platform.isWindows ? appWindow.show() : systemTray.popUpContextMenu();
    } else if (event == kSystemTrayEventRightClick) {
      Platform.isWindows ? systemTray.popUpContextMenu() : appWindow.show();
    }
  });

  // 4) 完整菜单延迟构建（不阻塞 UI），构建好后热替换
  unawaited(_replaceWithFullMenu(systemTray, appWindow));
}

/// 构建并替换为完整菜单（异步后台执行）
Future<void> _replaceWithFullMenu(SystemTray systemTray, AppWindow appWindow) async {
  // 微等一会儿，错开引擎/首帧后的小抖动
  await Future<void>.delayed(const Duration(milliseconds: 200));

  // 构建完整菜单
  final fullMenu = Menu();
  await fullMenu.buildFrom([
    MenuItemLabel(label: '打开主面板', onClicked: (_) => appWindow.show()),
    // MenuItemLabel(label: '打开网页版', onClicked: (_) {
    //   // TODO: 打开外链/内置 WebView
    //   // 这里保持轻输出，避免 Debug 里 print 过多拖慢
    // }),
    MenuSeparator(),
    MenuItemLabel(label: '设置', onClicked: (_) {}),
    MenuItemLabel(label: '检测更新', onClicked: (_) {}),
    MenuSeparator(),
    MenuItemLabel(label: '关于', onClicked: (_) {}),
    MenuItemLabel(label: '帮助中心', onClicked: (_) {}),
    MenuSeparator(),
    MenuItemLabel(label: '退出', onClicked: (_) => appWindow.close()),
  ]);

  // 热替换菜单
  await systemTray.setContextMenu(fullMenu);
}

/// 内部状态
class _TrayState {
  static bool _inited = false;
}
