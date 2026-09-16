import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../workbench/core/workbench_settings.dart';
import '../workbench/workbench_runtime.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _entering = false;

  final List<String> iconPaths = [
    'assets/login/兔子.svg',
    'assets/login/小狗.svg',
    'assets/login/小猪.svg',
    'assets/login/小猫.svg',
    'assets/login/小鸡.svg',
    'assets/login/小鸭.svg',
    'assets/login/棕熊.svg',
    'assets/login/猴子.svg',
    'assets/login/白熊.svg',
    'assets/login/老虎.svg',
    'assets/login/青蛙.svg',
    'assets/login/鸽子.svg',
  ];

  late String selectedIconPath;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    selectedIconPath = iconPaths[Random().nextInt(iconPaths.length)];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _closeApp() async {
    await Future.delayed(Duration.zero);
    if (Platform.isWindows) {
      exit(0);
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _enterWorkbench() async {
    if (_entering) return;
    setState(() => _entering = true);
    await _animationController.forward();

    var target = '/home';
    try {
      final runtime = await WorkbenchRuntime.instance;
      final settings = runtime.settingsService.current.general;
      final remembered = runtime.settingsService.lastActiveLocation;

      if (settings.restoreLastActiveContext && remembered != null) {
        target = remembered;
      } else {
        switch (settings.startupPage) {
          case WorkbenchStartupPage.home:
            target = '/home';
          case WorkbenchStartupPage.knowledge:
            target = '/knowledge';
          case WorkbenchStartupPage.workspace:
            final defaultWorkspaceId = settings.defaultWorkspaceId;
            if (defaultWorkspaceId == null) {
              target = '/workspace';
            } else {
              final workspaces = await runtime.workspaceService.listActive();
              final exists =
                  workspaces.any((item) => item.id == defaultWorkspaceId);
              target = exists
                  ? '/workspace/$defaultWorkspaceId/overview'
                  : '/workspace';
            }
        }
      }
    } catch (_) {
      target = '/home';
    }

    if (!mounted) return;
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          toolbarHeight: 40,
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _closeApp,
          ),
        ),
        body: Center(
          child: Container(
            alignment: Alignment.center,
            width: 400,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  selectedIconPath,
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      const Color.fromRGBO(126, 145, 250, 1),
                    ),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  onPressed: _entering ? null : _enterWorkbench,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 15,
                      ),
                      child: Text(
                        _entering ? '正在进入…' : '进入',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
