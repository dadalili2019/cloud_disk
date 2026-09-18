import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../router/router.dart';
import '../theme/theme_controller.dart';
import '../widgets/windowButtons.dart';
import '../workbench/application/continue_service.dart';
import '../workbench/core/models.dart';
import '../workbench/presentation/global_ai_drawer.dart';
import '../workbench/workbench_runtime.dart';

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
      _NavTarget.tools =>
        location.startsWith('/tools') ||
            location.startsWith('/todo') ||
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
    final palette = ThemeScope.of(context).palette;

    return Stack(
      children: [
        Container(
          color: palette.appBackground,
          child: Column(
            children: [
              _Topbar(
                currentWork: _currentWork,
                contextLoading: _contextLoading,
                aiOpen: _aiOpen,
                onWorkspacePressed: _switchWorkspace,
                onSearchPressed: () => _go('/knowledge'),
                onAiPressed: () => setState(() => _aiOpen = !_aiOpen),
                onSettingsPressed: () => _go('/setting'),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 1000;
                    return Row(
                      children: [
                        _Sidebar(
                          compact: compact,
                          location: router.location,
                          isActive: _isActive,
                          onHome: () => _go('/home'),
                          onWorkspace: _openWorkspace,
                          onTime: () => _go('/time'),
                          onKnowledge: () => _go('/knowledge'),
                          onDeveloper: () => _go('/developer'),
                          onTools: () => _go('/tools'),
                          onSettings: () => _go('/setting'),
                        ),
                        Expanded(child: widget.child),
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
            top: 54,
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

enum _NavTarget {
  home,
  workspace,
  time,
  knowledge,
  developer,
  tools,
  settings,
}

class _Topbar extends StatelessWidget {
  const _Topbar({
    required this.currentWork,
    required this.contextLoading,
    required this.aiOpen,
    required this.onWorkspacePressed,
    required this.onSearchPressed,
    required this.onAiPressed,
    required this.onSettingsPressed,
  });

  final ContinueItem? currentWork;
  final bool contextLoading;
  final bool aiOpen;
  final VoidCallback onWorkspacePressed;
  final VoidCallback onSearchPressed;
  final VoidCallback onAiPressed;
  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final theme = FluentTheme.of(context);
    final accent = theme.accentColor.normal;
    final primary = theme.typography.body?.color ?? const Color(0xFFE5E8EB);
    final secondary = primary.withValues(alpha: 0.58);

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: palette.appBarBackground,
        border: Border(
          bottom: BorderSide(color: palette.appBarBorder, width: 0.8),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showWorkspace = constraints.maxWidth >= 820;
          final showSearch = constraints.maxWidth >= 1040;
          return Row(
            children: [
              SizedBox(
                width: 224,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Row(
                    children: [
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
                      Expanded(
                        child: Text(
                          'Personal Workbench',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showWorkspace) ...[
                const SizedBox(width: 10),
                _TopbarButton(
                  width: 180,
                  icon: FluentIcons.open_folder_horizontal,
                  label: contextLoading
                      ? '加载工作区…'
                      : currentWork?.workspace.name ?? '选择工作区',
                  trailing: FluentIcons.chevron_down,
                  onPressed: onWorkspacePressed,
                ),
              ],
              if (showSearch) ...[
                const SizedBox(width: 10),
                _SearchEntry(
                  secondary: secondary,
                  onPressed: onSearchPressed,
                ),
              ],
              const SizedBox(width: 10),
              Expanded(
                child: WindowTitleBarBox(child: MoveWindow()),
              ),
              _IconTopbarButton(
                icon: FluentIcons.chat_bot,
                tooltip: 'AI',
                active: aiOpen,
                onPressed: onAiPressed,
              ),
              const SizedBox(width: 4),
              _IconTopbarButton(
                icon: FluentIcons.settings,
                tooltip: '设置',
                onPressed: onSettingsPressed,
              ),
              const SizedBox(width: 6),
              if (Platform.isWindows)
                const SizedBox(width: 168, child: WindowButtons()),
            ],
          );
        },
      ),
    );
  }
}

class _SearchEntry extends StatelessWidget {
  const _SearchEntry({
    required this.secondary,
    required this.onPressed,
  });

  final Color secondary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 360,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: palette.cardBorder),
          ),
          child: Row(
            children: [
              Icon(FluentIcons.search, size: 13, color: secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '搜索任务、笔记、问题、知识…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: secondary),
                ),
              ),
              Text(
                'Ctrl K',
                style: TextStyle(fontSize: 9.5, color: secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopbarButton extends StatelessWidget {
  const _TopbarButton({
    required this.width,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.trailing,
  });

  final double width;
  final IconData icon;
  final String label;
  final IconData? trailing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final theme = FluentTheme.of(context);
    final color = theme.typography.body?.color ?? const Color(0xFFE5E8EB);
    return Button(
      onPressed: onPressed,
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
      child: SizedBox(
        width: width,
        height: 32,
        child: Row(
          children: [
            Icon(icon, size: 13, color: color.withValues(alpha: 0.68)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: color),
              ),
            ),
            if (trailing != null)
              Icon(
                trailing,
                size: 9,
                color: color.withValues(alpha: 0.52),
              ),
          ],
        ),
      ),
    );
  }
}

class _IconTopbarButton extends StatelessWidget {
  const _IconTopbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final theme = FluentTheme.of(context);
    final foreground = active
        ? theme.accentColor.normal
        : (theme.typography.body?.color ?? const Color(0xFFE5E8EB))
            .withValues(alpha: 0.70);

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: active ? palette.surfaceMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: active ? Border.all(color: palette.cardBorder) : null,
        ),
        child: IconButton(
          icon: Icon(icon, size: 15, color: foreground),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.compact,
    required this.location,
    required this.isActive,
    required this.onHome,
    required this.onWorkspace,
    required this.onTime,
    required this.onKnowledge,
    required this.onDeveloper,
    required this.onTools,
    required this.onSettings,
  });

  final bool compact;
  final String location;
  final bool Function(_NavTarget, String) isActive;
  final VoidCallback onHome;
  final VoidCallback onWorkspace;
  final VoidCallback onTime;
  final VoidCallback onKnowledge;
  final VoidCallback onDeveloper;
  final VoidCallback onTools;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return Container(
      width: compact ? 76 : 224,
      decoration: BoxDecoration(
        color: palette.navBackground,
        border: Border(
          right: BorderSide(color: palette.navBorder, width: 0.8),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(compact ? 8 : 10, 10, compact ? 8 : 10, 10),
        child: Column(
          children: [
            _NavItem(
              compact: compact,
              icon: FluentIcons.home,
              label: '首页',
              active: isActive(_NavTarget.home, location),
              onPressed: onHome,
            ),
            _NavItem(
              compact: compact,
              icon: FluentIcons.open_folder_horizontal,
              label: '工作区',
              active: isActive(_NavTarget.workspace, location),
              onPressed: onWorkspace,
            ),
            _NavItem(
              compact: compact,
              icon: FluentIcons.clock,
              label: '时间',
              active: isActive(_NavTarget.time, location),
              onPressed: onTime,
            ),
            if (!compact) const _SidebarSectionLabel('工作台'),
            if (compact) const SizedBox(height: 10),
            _NavItem(
              compact: compact,
              icon: FluentIcons.library,
              label: '知识',
              active: isActive(_NavTarget.knowledge, location),
              onPressed: onKnowledge,
            ),
            _NavItem(
              compact: compact,
              icon: FluentIcons.link,
              label: '开发者',
              active: isActive(_NavTarget.developer, location),
              onPressed: onDeveloper,
            ),
            _NavItem(
              compact: compact,
              icon: FluentIcons.format_painter,
              label: '工具',
              active: isActive(_NavTarget.tools, location),
              onPressed: onTools,
            ),
            const Spacer(),
            Container(height: 1, color: palette.navBorder),
            const SizedBox(height: 8),
            _NavItem(
              compact: compact,
              icon: FluentIcons.settings,
              label: '设置',
              active: isActive(_NavTarget.settings, location),
              onPressed: onSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  const _SidebarSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = (FluentTheme.of(context).typography.body?.color ??
            const Color(0xFFE5E8EB))
        .withValues(alpha: 0.38);
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.compact,
    required this.icon,
    required this.label,
    required this.active,
    required this.onPressed,
  });

  final bool compact;
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final theme = FluentTheme.of(context);
    final primary = theme.typography.body?.color ?? const Color(0xFFE5E8EB);
    final foreground =
        active ? primary : primary.withValues(alpha: 0.62);

    final child = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 36,
          margin: const EdgeInsets.only(bottom: 3),
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 8),
          decoration: BoxDecoration(
            color: active ? palette.navItemSelected : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              if (active)
                Positioned(
                  left: 0,
                  top: 7,
                  bottom: 7,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: theme.accentColor.normal,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment:
                    compact ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Center(
                      child: Icon(icon, size: 15.5, color: foreground),
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w500,
                          color: foreground,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!compact) return child;
    return Tooltip(message: label, child: child);
  }
}

class NavigationBodyItem extends StatelessWidget {
  const NavigationBodyItem({super.key, this.header, this.content});

  final String? header;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.withPadding(
      header: PageHeader(title: Text(header ?? '页面标题')),
      content: content ?? const SizedBox.shrink(),
    );
  }
}
