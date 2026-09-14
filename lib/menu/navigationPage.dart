import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../router/router.dart';
import '../theme/theme_controller.dart';
import '../widgets/windowButtons.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key, required this.child});

  final Widget child;

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int topIndex = 0;

  Text _menuTitle(String text, {bool sub = false}) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: sub ? 13 : 14,
        fontWeight: sub ? FontWeight.w500 : FontWeight.w600,
        letterSpacing: 0,
        color: const Color(0xFF2F3437),
      ),
    );
  }

  Widget _groupHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
      child: Opacity(
        opacity: 0.56,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
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
      icon: Icon(icon, size: sub ? 15 : 17, color: const Color(0xFF3F464B)),
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
        icon: const Icon(FluentIcons.photo_collection, size: 17),
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
        icon: FluentIcons.library,
        title: '知识库',
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

    return Container(
      color: palette.appBackground,
      child: Column(
        children: [
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: palette.appBarBackground,
              border: Border(
                bottom: BorderSide(
                  color: palette.appBarBorder.withOpacity(0.45),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 14, right: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: palette.successSoft,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: accent.withOpacity(0.16),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          FluentIcons.cloud,
                          size: 14,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Personal Workbench',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                          color: Color(0xFF202124),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: WindowTitleBarBox(
                    child: MoveWindow(),
                  ),
                ),
                if (Platform.isWindows)
                  const SizedBox(width: 168, child: WindowButtons()),
              ],
            ),
          ),
          Expanded(
            child: NavigationView(
              paneBodyBuilder: (item, child) => widget.child,
              pane: NavigationPane(
                size: const NavigationPaneSize(openWidth: 220),
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
      header: PageHeader(title: Text(header ?? 'This is a header text')),
      content: content ?? const SizedBox.shrink(),
    );
  }
}
