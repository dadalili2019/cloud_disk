import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../router/router.dart';
import '../widgets/windowButtons.dart';

class NavigationPage extends StatefulWidget {
  final Widget child;

  const NavigationPage({super.key, required this.child});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int topIndex = 0; // 左侧选中索引（仅控制高亮）

  // 左侧菜单
  late final List<NavigationPaneItem> items = <NavigationPaneItem>[
    PaneItem(
      icon: const Icon(FluentIcons.home),
      title:
          const Text('首页', style: TextStyle(fontSize: 14, fontFamily: "微软雅黑")),
      body: const SizedBox.shrink(),
      onTap: () {
        if (router.location != '/home') router.goNamed('home');
      },
    ),
    PaneItem(
      icon: const Icon(FluentIcons.to_do_logo_inverse),
      title: const Text('待办清单',
          style: TextStyle(fontSize: 14, fontFamily: "微软雅黑")),
      body: const SizedBox.shrink(),
      onTap: () {
        if (router.location != '/todo') router.goNamed('todo');
      },
    ),
    PaneItem(
      icon: const Icon(FluentIcons.my_network),
      title: const Text('网络测速',
          style: TextStyle(fontSize: 14, fontFamily: "微软雅黑")),
      body: const SizedBox.shrink(),
      onTap: () {
        if (router.location != '/speedtestpage')
          router.goNamed('speedtestpage');
      },
    ),
    PaneItem(
      icon: const Icon(FluentIcons.format_painter),
      title: const Text('JSON格式化',
          style: TextStyle(fontSize: 14, fontFamily: "微软雅黑")),
      body: const SizedBox.shrink(),
      onTap: () {
        if (router.location != '/jsonFormat') router.goNamed('jsonFormat');
      },
    ),
    PaneItem(
      icon: const Icon(FluentIcons.branch_compare),
      title: const Text('文字比对',
          style: TextStyle(fontSize: 14, fontFamily: "微软雅黑")),
      body: const SizedBox.shrink(),
      onTap: () {
        if (router.location != '/comparison') router.goNamed('comparison');
      },
    ),
    PaneItem(
      icon: const Icon(FluentIcons.library),
      title:
          const Text('知识库', style: TextStyle(fontSize: 14, fontFamily: "微软雅黑")),
      body: const SizedBox.shrink(),
      onTap: () {
        if (router.location != '/ragknowledge') router.goNamed('ragknowledge');
      },
    ),
    PaneItem(
      icon: const Icon(FluentIcons.game),
      title: const Text('GAME',
          style: TextStyle(fontSize: 14, fontFamily: "微软雅黑")),
      body: const SizedBox.shrink(),
      onTap: () {
        if (router.location != '/game') router.goNamed('game');
      },
    ),
    // PaneItemExpander(
    //   icon: const Icon(FluentIcons.folder_open),
    //   title:
    //       const Text('文件', style: TextStyle(fontSize: 14, fontFamily: "微软雅黑")),
    //   body: const SizedBox.shrink(),
    //   // 不要写 expanded: ...（老版本没有这个参数）
    //   items: [
    //     PaneItem(
    //       icon: const Icon(FluentIcons.reminder_time),
    //       title: const Text('最近播放',
    //           style: TextStyle(fontSize: 14, fontFamily: "微软雅黑")),
    //       body: const SizedBox.shrink(),
    //       onTap: () {
    //         if (router.location != '/recentlyPlayed')
    //           router.goNamed('recentlyPlayed');
    //       },
    //     ),
    //     PaneItem(
    //       icon: const Icon(FluentIcons.document_set),
    //       title: const Text('我的资料',
    //           style: TextStyle(fontSize: 14, fontFamily: "微软雅黑")),
    //       body: const SizedBox.shrink(),
    //       onTap: () {
    //         if (router.location != '/myProfile') router.goNamed('myProfile');
    //       },
    //     ),
    //     // 如需更多子项，在这里继续加 PaneItem 即可
    //   ],
    // ),
    PaneItemSeparator(),
    PaneItem(
      icon: const Icon(FluentIcons.settings),
      title:
          const Text('设置', style: TextStyle(fontSize: 14, fontFamily: "微软雅黑")),
      body: const SizedBox.shrink(),
      onTap: () {
        if (router.location != '/setting') router.goNamed('setting');
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return NavigationView(
      appBar: NavigationAppBar(
        height: 36,
        leading: const Text(""),
        title: WindowTitleBarBox(child: MoveWindow()),
        actions: Platform.isWindows
            ? Container(
                alignment: Alignment.centerRight,
                width: 180,
                child: const WindowButtons(),
              )
            : const Text(""),
      ),

      // 右侧的实际内容由外层路由传进来
      paneBodyBuilder: (item, child) => widget.child,

      pane: NavigationPane(
        size: const NavigationPaneSize(openWidth: 220),
        displayMode: PaneDisplayMode.open,

        // 左侧选中态：仅由 onChanged 控制（不与路由耦合，稳定）
        selected: topIndex,
        onChanged: (index) => setState(() => topIndex = index),

        items: items,

        // footerItems: [
        //   PaneItem(
        //     enabled: false,
        //     icon: const Icon(FluentIcons.user_window),
        //     title: const Text('用户123321',
        //         style: TextStyle(fontSize: 14, color: Colors.grey)),
        //     body: const SizedBox.shrink(),
        //     onTap: () {
        //       if (router.location != '/settings') {
        //         router.goNamed('settings');
        //       }
        //     },
        //     trailing: MouseRegion(
        //       cursor: SystemMouseCursors.click,
        //       child: IconButton(
        //         icon: const Icon(FluentIcons.settings),
        //         onPressed: () {
        //           showMenu(
        //             context: context,
        //             position: RelativeRect.fromLTRB(
        //               200,
        //               screenSize.height - 280,
        //               screenSize.width - 200,
        //               300,
        //             ),
        //             items: const [
        //               PopupMenuItem(
        //                 height: 44,
        //                 child: Row(children: [
        //                   Text("个人中心",
        //                       style: TextStyle(
        //                           color: Colors.grey,
        //                           fontSize: 14,
        //                           fontFamily: "微软雅黑")),
        //                 ]),
        //               ),
        //               PopupMenuItem(
        //                 height: 44,
        //                 child: Row(children: [
        //                   Text("帮助反馈",
        //                       style: TextStyle(
        //                           color: Colors.grey,
        //                           fontSize: 14,
        //                           fontFamily: "微软雅黑")),
        //                 ]),
        //               ),
        //               PopupMenuItem(
        //                 height: 44,
        //                 child: Row(children: [
        //                   Text("关于",
        //                       style: TextStyle(
        //                           color: Colors.grey,
        //                           fontSize: 14,
        //                           fontFamily: "微软雅黑")),
        //                 ]),
        //               ),
        //               PopupMenuItem(
        //                 height: 44,
        //                 child: Row(children: [
        //                   Text("设置",
        //                       style: TextStyle(
        //                           color: Colors.grey,
        //                           fontSize: 14,
        //                           fontFamily: "微软雅黑")),
        //                 ]),
        //               ),
        //               PopupMenuItem(
        //                 height: 44,
        //                 child: Row(children: [
        //                   Text("退出登录",
        //                       style: TextStyle(
        //                           color: Colors.grey,
        //                           fontSize: 14,
        //                           fontFamily: "微软雅黑")),
        //                 ]),
        //               ),
        //             ],
        //           );
        //         },
        //       ),
        //     ),
        //   ),
        // ],
      ),
    );
  }
}

// 你之前的公共容器，原样保留
class NavigationBodyItem extends StatelessWidget {
  const NavigationBodyItem({Key? key, this.header, this.content})
      : super(key: key);
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
