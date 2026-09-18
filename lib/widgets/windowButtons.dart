import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

class WindowButtons extends StatefulWidget {
  const WindowButtons({super.key});

  @override
  State<WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> {
  final buttonColors = WindowButtonColors(
    iconNormal: Colors.grey[600],
    mouseOver: Colors.grey[400],
    mouseDown: Colors.grey[400],
    iconMouseOver: Colors.grey[600],
    iconMouseDown: Colors.grey[600],
  );

  void maximizeOrRestore() {
    setState(() {
      appWindow.maximizeOrRestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WindowTitleBarBox(
      child: Row(
        children: [
          Expanded(child: MoveWindow()), // 可拖动区域
          Row( // 右侧按钮组
            mainAxisSize: MainAxisSize.min,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: MinimizeWindowButton(colors: buttonColors),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: appWindow.isMaximized
                    ? RestoreWindowButton(
                  colors: buttonColors,
                  onPressed: maximizeOrRestore,
                )
                    : MaximizeWindowButton(
                  colors: buttonColors,
                  onPressed: maximizeOrRestore,
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: CloseWindowButton(colors: buttonColors),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
