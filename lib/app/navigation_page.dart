import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../router/router.dart';
import '../theme/theme_controller.dart';
import '../widgets/window_buttons.dart';
import '../workbench/application/continue_service.dart';
import '../workbench/core/models.dart';
import '../workbench/presentation/global_ai_drawer.dart';
import '../workbench/workbench_runtime.dart';

part 'navigation_shell_topbar.dart';
part 'navigation_shell_sidebar.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key, required this.child});

  final Widget child;

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  bool _aiOpen = false;
  bool _contextLoading = true;
  ContinueItem? _currentWork;
  String? _lastLocation;

  @override
  void initState() {
    super.initState();
    _lastLocation = router.location;
    _refreshCurrentWork();
  }

  @override
  void didUpdateWidget(covariant NavigationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final location = router.location;
    if (_lastLocation != location) {
      _lastLocation = location;
      _refreshCurrentWork();
    }
  }

  Future<void> _refreshCurrentWork() async {
    if (mounted) setState(() => _contextLoading = true);
    try {
      final runtime = await WorkbenchRuntime.instance;
      final snapshot = await runtime.continueService.load();
      if (!mounted) return;
      setState(() {
        _currentWork = snapshot.primary;
        _contextLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentWork = null;
        _contextLoading = false;
      });
    }
  }

  void _go(String location) {
    if (router.location != location) router.go(location);
  }

  void _openWorkspace() {
    final current = _currentWork;
    if (current == null) {
      _go('/workspace');
      return;
    }
    _go('/workspace/${current.workspace.id}/overview');
  }

  void _openDeveloper() {
    final current = _currentWork;
    if (current == null) {
      _go('/workspace');
      return;
    }
    _go('/workspace/${current.workspace.id}/developer');
  }

  Future<void> _switchWorkspace() async {
    try {
      final runtime = await WorkbenchRuntime.instance;
      final workspaces = await runtime.workspaceService.listActive();
      if (!mounted) return;

      if (workspaces.isEmpty) {
        _go('/workspace');
        return;
      }

      final selected = await showDialog<WorkspaceModel>(
        context: context,
        builder: (dialogContext) => ContentDialog(
          title: const Text('切换工作区'),
          content: SizedBox(
            width: 360,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final workspace in workspaces)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Button(
                        onPressed: () =>
                            Navigator.pop(dialogContext, workspace),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(workspace.name),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            Button(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            Button(
              onPressed: () {
                Navigator.pop(dialogContext);
                _go('/workspace');
              },
              child: const Text('管理工作区'),
            ),
          ],
        ),
      );

      if (selected != null && mounted) {
        _go('/workspace/${selected.id}/overview');
      }
    } catch (_) {
      if (mounted) _go('/workspace');
    }
  }

  bool _isActive(_NavTarget target, String location) {
    return switch (target) {
      _NavTarget.home => location == '/' || location.startsWith('/home'),
      _NavTarget.workspace =>
        location.startsWith('/workspace') && !location.endsWith('/developer'),
      _NavTarget.time => location.startsWith('/time'),
      _NavTarget.knowledge => location.startsWith('/knowledge'),
      _NavTarget.developer =>
        location.startsWith('/developer') || location.endsWith('/developer'),
      _NavTarget.tools => location.startsWith('/tools') ||
          location.startsWith('/speedtestpage') ||
          location.startsWith('/jsonformat') ||
          location.startsWith('/comparison') ||
          location.startsWith('/imagetools') ||
          location.startsWith('/ragknowledge') ||
          location.startsWith('/game'),
      _NavTarget.settings => location.startsWith('/setting'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = _ShellColors.of(context);

    return Stack(
      children: [
        Container(
          color: colors.background,
          child: Column(
            children: [
              _Topbar(
                aiOpen: _aiOpen,
                onSearchPressed: () => _go('/knowledge'),
                onAiPressed: () => setState(() => _aiOpen = !_aiOpen),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 1000;
                    return Row(
                      children: [
                        _Sidebar(
                          compact: compact,
                          currentWork: _currentWork,
                          contextLoading: _contextLoading,
                          onWorkspacePressed: _switchWorkspace,
                          location: router.location,
                          isActive: _isActive,
                          onHome: () => _go('/home'),
                          onWorkspace: _openWorkspace,
                          onTime: () => _go('/time'),
                          onKnowledge: () => _go('/knowledge'),
                          onDeveloper: _openDeveloper,
                          onTools: () => _go('/tools'),
                          onSettings: () => _go('/setting'),
                        ),
                        Expanded(
                          child: _ContentFrame(
                            location: router.location,
                            compact: compact,
                            child: widget.child,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (_aiOpen)
          Positioned(
            top: _shellTopbarHeight,
            right: 0,
            bottom: 0,
            child: GlobalAiDrawer(
              currentLocation: router.location,
              onClose: () => setState(() => _aiOpen = false),
            ),
          ),
      ],
    );
  }
}
