import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

class LoginButtons extends StatefulWidget {
  const LoginButtons({Key? key}) : super(key: key);
  @override
  _LoginButtonsState createState() => _LoginButtonsState();
}

class _LoginButtonsState extends State<LoginButtons> {
  final buttonColors = WindowButtonColors(
      iconNormal: Colors.grey[600],
      mouseOver: Colors.grey[400],
      mouseDown: Colors.grey[400],
      iconMouseOver: Colors.grey[600],
      iconMouseDown: Colors.grey[600]);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: MinimizeWindowButton(colors: buttonColors),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: CloseWindowButton(
            colors: buttonColors,
          ),
        )
      ],
    );
  }
}
