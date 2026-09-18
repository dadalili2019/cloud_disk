import 'dart:io';
import 'dart:math';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme_controller.dart';
import '../widgets/windowButtons.dart';
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
  bool _transitioning = false;

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
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    selectedIconPath = iconPaths[Random().nextInt(iconPaths.length)];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

    setState(() => _transitioning = true);
    await Future<void>.delayed(const Duration(milliseconds: 140));

    if (Platform.isWindows) {
      appWindow.minSize = const Size(860, 640);
      // 先设置对齐，再让尺寸调整按新尺寸居中，避免异步调整期间读取旧尺寸。
      appWindow.alignment = Alignment.center;
      appWindow.size = const Size(1280, 800);
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }

    if (!mounted) return;
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    const primary = Color(0xFFB2BAB2);
    const secondary = Color(0xFF8D958E);
    final accent = ThemeScope.of(context).accent.normal;

    return Material(
      color: palette.appBackground,
      child: AnimatedOpacity(
        opacity: _transitioning ? 0 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Column(
          children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: palette.appBarBackground,
              border: Border(
                bottom: BorderSide(
                  color: palette.appBarBorder,
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Text(
                    'PW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF151711),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                const Text(
                  'Personal Workbench',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: MoveWindow()),
                if (Platform.isWindows)
                  const SizedBox(
                    width: 150,
                    child: WindowButtons(),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                width: 320,
                padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
                decoration: BoxDecoration(
                  color: palette.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                      color: palette.shadow.withOpacity(0.18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: palette.cardBorder),
                      ),
                      child: SvgPicture.asset(
                        selectedIconPath,
                        width: 88,
                        height: 88,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Personal Workbench',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '继续你的工作',
                      style: TextStyle(
                        fontSize: 11,
                        color: secondary,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: 148,
                      height: 40,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          elevation: MaterialStateProperty.all(0),
                          backgroundColor:
                              MaterialStateProperty.all(accent),
                          foregroundColor: MaterialStateProperty.all(
                            const Color(0xFF151711),
                          ),
                          padding:
                              MaterialStateProperty.all(EdgeInsets.zero),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                        onPressed: _entering ? null : _enterWorkbench,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Text(
                            _entering ? '正在进入…' : '进入工作台',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
        ],
        ),
      ),
    );
  }
}
