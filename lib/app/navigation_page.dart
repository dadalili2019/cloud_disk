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

enum _NavTarget {
  home,
  workspace,
  time,
  knowledge,
  developer,
  tools,
  settings,
}

const double _shellTopbarHeight = 58;
const double _shellSidebarWidth = 208;

/// 外框单独配色，避免本轮视觉调整改变内页的主题与表单。
class _ShellColors {
  const _ShellColors({
    required this.background,
    required this.surface,
    required this.border,
    required this.text,
    required this.secondary,
    required this.accent,
    required this.selection,
    required this.hover,
  });

  final Color background;
  final Color surface;
  final Color border;
  final Color text;
  final Color secondary;
  final Color accent;
  final Color selection;
  final Color hover;

  factory _ShellColors.of(BuildContext context) {
    final theme = FluentTheme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final accent = dark
        ? Color.lerp(theme.accentColor.normal, Colors.white, 0.38)!
        : theme.accentColor.dark;
    return _ShellColors(
      background: dark ? const Color(0xFF1C1F22) : const Color(0xFFF0F2EF),
      surface: dark ? const Color(0xFF25292C) : const Color(0xFFFAFBF9),
      border: dark ? const Color(0xFF363B3D) : const Color(0xFFDDE2DA),
      text: dark ? const Color(0xFFE8ECE7) : const Color(0xFF262E29),
      secondary: dark ? const Color(0xFF9BA59E) : const Color(0xFF657068),
      accent: accent,
      selection: accent.withValues(alpha: dark ? 0.12 : 0.10),
      hover: dark ? const Color(0xFF292E30) : const Color(0xFFE5EAE3),
    );
  }
}

/// 标题栏只放全局入口，中间留出可拖动区域。
class _Topbar extends StatelessWidget {
  const _Topbar({
    required this.aiOpen,
    required this.onSearchPressed,
    required this.onAiPressed,
  });

  final bool aiOpen;
  final VoidCallback onSearchPressed;
  final VoidCallback onAiPressed;

  @override
  Widget build(BuildContext context) {
    final colors = _ShellColors.of(context);
    return SizedBox(
      height: _shellTopbarHeight,
      child: Row(
        children: [
          SizedBox(
            width: _shellSidebarWidth,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colors.selection,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: colors.accent.withValues(alpha: 0.25)),
                    ),
                    alignment: Alignment.center,
                    child: Text('W',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: colors.accent,
                        )),
                  ),
                  const SizedBox(width: 10),
                  Text('个人工作台',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: colors.text,
                      )),
                ],
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              return Row(children: [
                if (constraints.maxWidth >= 260)
                  SizedBox(
                    width: constraints.maxWidth >= 460 ? 340 : 220,
                    child: _ShellButton(
                      label: '搜索知识与工作内容',
                      onPressed: onSearchPressed,
                      background: colors.surface,
                      child: Row(children: [
                        Icon(FluentIcons.search,
                            size: 14, color: colors.secondary),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(
                          '搜索知识与工作内容',
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 12, color: colors.secondary),
                        )),
                      ]),
                    ),
                  )
                else
                  Tooltip(
                      message: '搜索知识与工作内容',
                      child: SizedBox(
                        width: 36,
                        child: _ShellButton(
                          label: '搜索知识与工作内容',
                          onPressed: onSearchPressed,
                          child: Icon(FluentIcons.search,
                              size: 15, color: colors.secondary),
                        ),
                      )),
                Expanded(child: WindowTitleBarBox(child: MoveWindow())),
              ]);
            }),
          ),
          Tooltip(
              message: '打开 AI 助手',
              child: SizedBox(
                width: 38,
                child: _ShellButton(
                  label: 'AI 助手',
                  selected: aiOpen,
                  onPressed: onAiPressed,
                  child: Icon(FluentIcons.chat_bot,
                      size: 17,
                      color: aiOpen ? colors.accent : colors.secondary),
                ),
              )),
          const SizedBox(width: 12),
          Container(width: 1, height: 18, color: colors.border),
          if (Platform.isWindows)
            const SizedBox(width: 150, child: WindowButtons())
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}

/// 统一外框按钮的悬停与键盘焦点，避免仅靠鼠标手势响应。
class _ShellButton extends StatelessWidget {
  const _ShellButton({
    required this.label,
    required this.onPressed,
    required this.child,
    this.selected = false,
    this.background,
    this.height = 36,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final String label;
  final VoidCallback onPressed;
  final Widget child;
  final bool selected;
  final Color? background;
  final double height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = _ShellColors.of(context);
    return Semantics(
      label: label,
      selected: selected,
      child: Button(
        onPressed: onPressed,
        style: ButtonStyle(
          padding: WidgetStateProperty.all(padding),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (selected) return colors.selection;
            if (states.isHovered || states.isPressed) return colors.hover;
            return background ?? Colors.transparent;
          }),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          )),
        ),
        child: DefaultTextStyle.merge(
          textAlign: TextAlign.left,
          child: SizedBox(height: height, child: child),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.compact,
    required this.currentWork,
    required this.contextLoading,
    required this.onWorkspacePressed,
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
  final ContinueItem? currentWork;
  final bool contextLoading;
  final VoidCallback onWorkspacePressed;
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
    final colors = _ShellColors.of(context);
    final workspace =
        contextLoading ? '加载中…' : currentWork?.workspace.name ?? '选择工作区';
    return SizedBox(
      width: compact ? 68 : _shellSidebarWidth,
      child: Padding(
        padding:
            EdgeInsets.fromLTRB(compact ? 10 : 12, 10, compact ? 10 : 12, 14),
        child: Column(children: [
          Tooltip(
              message: '切换工作区 · $workspace',
              child: _ShellButton(
                label: '切换工作区',
                height: compact ? 44 : 60,
                padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 12),
                background: colors.surface,
                onPressed: onWorkspacePressed,
                child: Row(
                  mainAxisAlignment: compact
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Icon(FluentIcons.open_folder_horizontal,
                        size: 18, color: colors.accent),
                    if (!compact) ...[
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('当前工作区',
                              style: TextStyle(
                                  fontSize: 11,
                                  height: 1.5,
                                  color: colors.secondary)),
                          const SizedBox(height: 2),
                          Text(workspace,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                  color: colors.text)),
                        ],
                      )),
                      Icon(FluentIcons.chevron_down,
                          size: 9, color: colors.secondary),
                    ],
                  ],
                ),
              )),
          const SizedBox(height: 16),
          Expanded(
              child: ListView(
            padding: EdgeInsets.zero,
            children: [
              if (!compact) const _SidebarSectionLabel('日常'),
              _NavItem(
                  compact: compact,
                  icon: FluentIcons.home,
                  label: '首页',
                  active: isActive(_NavTarget.home, location),
                  onPressed: onHome),
              _NavItem(
                  compact: compact,
                  icon: FluentIcons.open_folder_horizontal,
                  label: '工作区',
                  active: isActive(_NavTarget.workspace, location),
                  onPressed: onWorkspace),
              _NavItem(
                  compact: compact,
                  icon: FluentIcons.clock,
                  label: '时间',
                  active: isActive(_NavTarget.time, location),
                  onPressed: onTime),
              const SizedBox(height: 20),
              if (!compact) const _SidebarSectionLabel('资料与工具'),
              _NavItem(
                  compact: compact,
                  icon: FluentIcons.doc_library,
                  label: '知识',
                  active: isActive(_NavTarget.knowledge, location),
                  onPressed: onKnowledge),
              _NavItem(
                  compact: compact,
                  icon: FluentIcons.developer_tools,
                  label: '开发者',
                  active: isActive(_NavTarget.developer, location),
                  onPressed: onDeveloper),
              _NavItem(
                  compact: compact,
                  icon: FluentIcons.toolbox,
                  label: '工具',
                  active: isActive(_NavTarget.tools, location),
                  onPressed: onTools),
            ],
          )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Container(height: 1, color: colors.border),
          ),
          _NavItem(
              compact: compact,
              icon: FluentIcons.settings,
              label: '设置',
              active: isActive(_NavTarget.settings, location),
              onPressed: onSettings),
        ]),
      ),
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  const _SidebarSectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Text(label,
          style: TextStyle(
            fontSize: 11,
            height: 1.4,
            color: _ShellColors.of(context).secondary,
          )),
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
    final colors = _ShellColors.of(context);
    final foreground = active ? colors.text : colors.secondary;
    final button = Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: _ShellButton(
        label: label,
        onPressed: onPressed,
        selected: active,
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 12),
        child: Row(
          mainAxisAlignment:
              compact ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: active ? colors.accent : foreground),
            if (!compact) ...[
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                label,
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: foreground),
              )),
              if (active)
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                      color: colors.accent, shape: BoxShape.circle),
                ),
            ],
          ],
        ),
      ),
    );
    return compact ? Tooltip(message: label, child: button) : button;
  }
}

/// 路由只用于外框标题，内部页面仍保留原有布局与滚动区域。
class _ContentFrame extends StatelessWidget {
  const _ContentFrame(
      {required this.location, required this.compact, required this.child});

  final String location;
  final bool compact;
  final Widget child;

  (String, String) get _breadcrumb {
    final path = Uri.parse(location).path;
    if (path.startsWith('/workspace/')) {
      final section = path.split('/').last;
      const sections = {
        'overview': '概览',
        'tasks': '任务',
        'notes': '笔记',
        'issues': '问题',
        'resources': '资源',
        'decisions': '决策',
        'developer': '开发',
      };
      return ('工作区', sections[section] ?? '概览');
    }
    const pages = {
      '/home': ('个人空间', '首页'),
      '/workspace': ('个人空间', '工作区'),
      '/time': ('个人空间', '时间'),
      '/knowledge': ('资料与工具', '知识'),
      '/developer': ('资料与工具', '开发者'),
      '/tools': ('资料与工具', '工具'),
      '/jsonformat': ('工具', 'JSON 格式化'),
      '/comparison': ('工具', '文字比对'),
      '/speedtestpage': ('工具', '网络测速'),
      '/ragknowledge': ('工具', 'RAG 知识库'),
      '/game': ('工具', '游戏'),
    };
    if (path.startsWith('/setting')) return ('个人空间', '设置');
    if (path.startsWith('/imagetools')) return ('工具', '图片工具');
    return pages[path] ?? ('个人空间', '工作台');
  }

  @override
  Widget build(BuildContext context) {
    final colors = _ShellColors.of(context);
    final palette = ThemeScope.of(context).palette;
    final (section, title) = _breadcrumb;
    return Padding(
      padding: EdgeInsets.only(right: compact ? 8 : 14, bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: palette.appBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        padding: const EdgeInsets.all(1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Column(children: [
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: palette.appBackground,
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: Row(children: [
                Text(section,
                    style: TextStyle(fontSize: 12, color: colors.secondary)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(FluentIcons.chevron_right,
                      size: 8, color: colors.secondary),
                ),
                Expanded(
                    child: Semantics(
                        header: true,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.text),
                        ))),
              ]),
            ),
            Expanded(child: child),
          ]),
        ),
      ),
    );
  }
}
