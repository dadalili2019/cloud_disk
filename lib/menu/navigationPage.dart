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
      style: TextStyle(
        fontSize: sub ? 15 : 16,
        fontWeight: sub ? FontWeight.w500 : FontWeight.w600,
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
      icon: Icon(icon),
      title: _menuTitle(title, sub: sub),
      body: const SizedBox.shrink(),
      onTap: onTap,
      tileColor: tileColor,
      selectedTileColor: selectedTileColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
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
        onTap: () {
          if (router.location != '/home') router.goNamed('home');
        },
      ),
      _item(
        icon: FluentIcons.to_do_logo_inverse,
        title: '待办清单',
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        onTap: () {
          if (router.location != '/todo') router.goNamed('todo');
        },
      ),
      _item(
        icon: FluentIcons.my_network,
        title: '网络测速',
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        onTap: () {
          if (router.location != '/speedtestpage') router.goNamed('speedtestpage');
        },
      ),
      _item(
        icon: FluentIcons.format_painter,
        title: 'JSON格式化',
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        onTap: () {
          if (router.location != '/jsonFormat') router.goNamed('jsonFormat');
        },
      ),
      _item(
        icon: FluentIcons.branch_compare,
        title: '文字比对',
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        onTap: () {
          if (router.location != '/comparison') router.goNamed('comparison');
        },
      ),
      PaneItemHeader(header: const Text('图片工作台')),
      PaneItemExpander(
        icon: const Icon(FluentIcons.photo_collection),
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
            onTap: () {
              if (router.location != '/imagetools/convert') router.goNamed('imageConvert');
            },
          ),
          _item(
            icon: FluentIcons.text_box,
            title: '水印工具',
            tileColor: tileColor,
            selectedTileColor: selectedTileColor,
            sub: true,
            onTap: () {
              if (router.location != '/imagetools/watermark') router.goNamed('imageWatermark');
            },
          ),
          _item(
            icon: FluentIcons.crop,
            title: '裁剪与尺寸',
            tileColor: tileColor,
            selectedTileColor: selectedTileColor,
            sub: true,
            onTap: () {
              if (router.location != '/imagetools/crop') router.goNamed('imageCrop');
            },
          ),
          _item(
            icon: FluentIcons.color,
            title: '滤镜增强',
            tileColor: tileColor,
            selectedTileColor: selectedTileColor,
            sub: true,
            onTap: () {
              if (router.location != '/imagetools/filter') router.goNamed('imageFilter');
            },
          ),
          _item(
            icon: FluentIcons.grid_view_medium,
            title: '拼图九宫格',
            tileColor: tileColor,
            selectedTileColor: selectedTileColor,
            sub: true,
            onTap: () {
              if (router.location != '/imagetools/collage') router.goNamed('imageCollage');
            },
          ),
          _item(
            icon: FluentIcons.search_and_apps,
            title: '去重与清理',
            tileColor: tileColor,
            selectedTileColor: selectedTileColor,
            sub: true,
            onTap: () {
              if (router.location != '/imagetools/dedupe') router.goNamed('imageDedupe');
            },
          ),
        ],
      ),
      PaneItemHeader(header: const Text('其他')),
      _item(
        icon: FluentIcons.library,
        title: '知识库',
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        onTap: () {
          if (router.location != '/ragknowledge') router.goNamed('ragknowledge');
        },
      ),
      _item(
        icon: FluentIcons.game,
        title: 'GAME',
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        onTap: () {
          if (router.location != '/game') router.goNamed('game');
        },
      ),
      PaneItemSeparator(),
      _item(
        icon: FluentIcons.settings,
        title: '设置',
        tileColor: tileColor,
        selectedTileColor: selectedTileColor,
        onTap: () {
          if (router.location != '/setting') router.goNamed('setting');
        },
      ),
    ];

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.navBackground,
        border: Border.all(color: palette.navBorder.withOpacity(0.75), width: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: palette.appBarBackground,
              border: Border(bottom: BorderSide(color: palette.appBarBorder.withOpacity(0.7), width: 0.8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: WindowTitleBarBox(
                    child: MoveWindow(),
                  ),
                ),
                if (Platform.isWindows) const SizedBox(width: 180, child: WindowButtons()),
              ],
            ),
          ),
          Expanded(
            child: NavigationView(
              paneBodyBuilder: (item, child) => widget.child,
              pane: NavigationPane(
                size: const NavigationPaneSize(openWidth: 218),
                displayMode: PaneDisplayMode.open,
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
