import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../router/router.dart';
import '../theme/theme_controller.dart';
import '../widgets/windowButtons.dart';
import '../workbench/application/continue_service.dart';
import '../workbench/presentation/global_ai_drawer.dart';
import '../workbench/workbench_runtime.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key, required this.child});

  final Widget child;

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int topIndex = 0;
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

  Text _menuTitle(String text, {bool sub = false}) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: sub ? 12.5 : 13.5,
        fontWeight: sub ? FontWeight.w500 : FontWeight.w600,
        letterSpacing: 0,
        color: const Color(0xFF2F3437),
      ),
    );
  }

  Widget _groupHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 5),
      child: Opacity(
        opacity: 0.52,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: Color(0xFF485058),
          ),
        ),
      ),
    );
  }

  PaneItem _item({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ButtonState<Color?> tileColor,
    required ButtonState<Color?> selectedTileColor,
    bool sub = false,
  }) {
    return PaneItem(
      icon: Icon(icon, size: sub ? 14.5 : 16.5, color: const Color(0xFF3F464B)),
      title: _menuTitle(title, sub: sub),
      body: const SizedBox.shrink(),
      onTap: onTap,
      tileColor: tileColor,
      selectedTileColor: selectedTileColor,
    );
  }

  void _go(String location, String name) {
    if (router.location != location) {
      router.goNamed(name);
    }
  }

  void _openCurrentWork() {
    final current = _currentWork;
    if (current == null) {
      router.go('/workspace');
      return;
    }
    router.go('/workspace/${current.workspace.id}/overview');
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final accent = FluentTheme.of(context).accentColor.normal;
    final tileColor = ButtonState.resolveWith<Color?>((states) {
      if (states.isPressing) return palette.navItemSelected;
      if (states.isHovering) return palette.navItemHover;
      return Colors.transparent;
    });
    final selectedTileColor = ButtonState.all<Color?>(palette.navItemSelected);

    final items = <NavigationPaneItem>[
      _item(
        icon: FluentIcons.home,
        title: '首页',
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        onTap: () => _go('/home', 'home'),
      ),
      _item(
        icon: FluentIcons.open_folder_horizontal,
        title: '工作台',
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        onTap: () => _go('/workspace', 'workbenchWorkspace'),
      ),
      _item(
        icon: FluentIcons.library,
        title: '知识与搜索',
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        onTap: () => _go('/knowledge', 'workbenchKnowledge'),
      ),
      PaneItemHeader(header: _groupHeader('工具')),
      _item(
        icon: FluentIcons.to_do_logo_inverse,
        title: '待办清单',
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        onTap: () => _go('/todo', 'todo'),
      ),
      _item(
        icon: FluentIcons.my_network,
        title: '网络测速',
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        onTap: () => _go('/speedtestpage', 'speedtestpage'),
      ),
      _item(
        icon: FluentIcons.format_painter,
        title: 'JSON格式化',
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        onTap: () => _go('/jsonformat', 'jsonformat'),
      ),
      _item(
        icon: FluentIcons.branch_compare,
        title: '文字比对',
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        onTap: () => _go('/comparison', 'comparison'),
      ),
      PaneItemHeader(header: _groupHeader('图片工作台')),
      PaneItemExpander(
        icon: const Icon(FluentIcons.photo_collection, size: 16.5),
        title: _menuTitle('图片工具'),
        body: const SizedBox.shrink(),
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        items: [
          _item(
            icon: FluentIcons.switch_widget,
            title: '批量转换',
            tileColor: tileColor,
            selectedTileColor: selectedTileColor,
            sub: true,
            onTap: () => _go('/imagetools/convert', 'imageConvert'),
          ),
          _item(
            icon: FluentIcons.text_box,
            title: '水印工具',
            tileColor: tileColor,
            selectedTileColor: selectedTileColor,
            sub: true,
            onTap: () => _go('/imagetools/watermark', 'imageWatermark'),
          ),
          _item(
            icon: FluentIcons.crop,
            title: '裁剪与尺寸',
            tileColor: tileColor,
            selectedTileColor: selectedTileColor,
            sub: true,
            onTap: () => _go('/imagetools/crop', 'imageCrop'),
          ),
          _item(
            icon: FluentIcons.color,
            title: '滤镜增强',
            tileColor: tileColor,
            selectedTileColor: selectedTileColor,
            sub: true,
            onTap: () => _go('/imagetools/filter', 'imageFilter'),
          ),
          _item(
            icon: FluentIcons.grid_view_medium,
            title: '拼图九宫格',
            tileColor: tileColor,
            selectedTileColor: selectedTileColor,
            sub: true,
            onTap: () => _go('/imagetools/collage', 'imageCollage'),
          ),
          _item(
            icon: FluentIcons.search_and_apps,
            title: '去重与清理',
            tileColor: tileColor,
            selectedTileColor: selectedTileColor,
            sub: true,
            onTap: () => _go('/imagetools/dedupe', 'imageDedupe'),
          ),
        ],
      ),
      PaneItemHeader(header: _groupHeader('其他')),
      _item(
        icon: FluentIcons.chat_bot,
        title: 'RAG 知识库',
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        onTap: () => _go('/ragknowledge', 'ragknowledge'),
      ),
      _item(
        icon: FluentIcons.game,
        title: 'GAME',
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        onTap: () => _go('/game', 'game'),
      ),
      PaneItemSeparator(),
      _item(
        icon: FluentIcons.settings,
        title: '设置',
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        onTap: () => _go('/setting', 'setting'),
      ),
    ];

    return Stack(
      children: [
        Container(
          color: palette.appBackground,
          child: Column(
            children: [
              _buildTopbar(palette, accent),
              Expanded(
                child: NavigationView(
                  paneBodyBuilder: (item, child) => widget.child,
                  pane: NavigationPane(
                    size: const NavigationPaneSize(openWidth: 224),
                    displayMode: PaneDisplayMode.open,
                    indicator: const StickyNavigationIndicator(
                      color: Color(0xFF8CCBA4),
                      indicatorSize: 2,
                    ),
                    selected: topIndex,
                    onChanged: (index) => setState(() => topIndex = index),
                    items: items,
                  ),
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

  Widget _buildTopbar(ThemePalette palette, Color accent) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: palette.appBarBackground,
        border: Border(
          bottom: BorderSide(
            color: palette.appBarBorder.withOpacity(0.62),
            width: 0.8,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showCurrentContext = constraints.maxWidth >= 920;
          final showSearch = constraints.maxWidth >= 1180;
          return Row(
            children: [
              SizedBox(
                width: 224,
                child: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: palette.successSoft,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: accent.withOpacity(0.16),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          FluentIcons.cloud,
                          size: 15,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Expanded(
                        child: Text(
                          '个人工作台',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                            color: Color(0xFF202124),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showCurrentContext) ...[
                const SizedBox(width: 12),
                _currentContextEntry(palette, accent),
              ],
              if (showSearch) ...[
                const SizedBox(width: 10),
                _globalSearchEntry(palette),
              ],
              const SizedBox(width: 10),
              Expanded(
                child: WindowTitleBarBox(
                  child: MoveWindow(),
                ),
              ),
              _topAction(
                palette: palette,
                icon: FluentIcons.chat_bot,
                tooltip: 'Workbench AI',
                active: _aiOpen,
                accent: accent,
                onPressed: () => setState(() => _aiOpen = !_aiOpen),
              ),
              const SizedBox(width: 4),
              _topAction(
                palette: palette,
                icon: FluentIcons.settings,
                tooltip: '设置',
                accent: accent,
                onPressed: () => router.go('/setting'),
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

  Widget _currentContextEntry(ThemePalette palette, Color accent) {
    final current = _currentWork;
    final title = _contextLoading
        ? '加载当前工作…'
        : current == null
            ? '暂无当前任务'
            : '${current.workspace.name} · ${current.context.task.title}';
    final subtitle = current == null || _contextLoading
        ? 'Current Context'
        : current.context.task.nextStep.trim().isEmpty
            ? 'Current Task'
            : '下一步 · ${current.context.task.nextStep}';

    return Tooltip(
      message: current == null ? '打开工作台' : '返回当前工作区',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openCurrentWork,
          child: Container(
            width: 230,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: palette.cardBorder.withOpacity(0.88)),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: palette.cardBackground,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    FluentIcons.bulleted_list_text,
                    size: 12,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2F3437),
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 8.5,
                          color: Color(0xFF7A8084),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  FluentIcons.chevron_right,
                  size: 9,
                  color: Color(0xFF8A9094),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _globalSearchEntry(ThemePalette palette) {
    return Tooltip(
      message: '打开知识与搜索',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => router.go('/knowledge'),
          child: Container(
            width: 250,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: palette.cardBackground.withOpacity(0.72),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: palette.cardBorder.withOpacity(0.95)),
            ),
            child: const Row(
              children: [
                Icon(
                  FluentIcons.search,
                  size: 13,
                  color: Color(0xFF73797D),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '搜索工作上下文…',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF777D81),
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

  Widget _topAction({
    required ThemePalette palette,
    required IconData icon,
    required String tooltip,
    required Color accent,
    required VoidCallback onPressed,
    bool active = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: active ? palette.surfaceMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: active
              ? Border.all(color: palette.cardBorder.withOpacity(0.88))
              : null,
        ),
        child: IconButton(
          icon: Icon(
            icon,
            size: 15,
            color: active ? accent : const Color(0xFF3F464B),
          ),
          onPressed: onPressed,
        ),
      ),
    );
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
