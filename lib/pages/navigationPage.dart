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
  int topIndex = 0; //第几个选中
  //左侧的选项卡 以及选项卡对应的页面
  List<NavigationPaneItem> items = [
    PaneItemExpander(
      icon: const Icon(
        FluentIcons.folder_open,
      ),
      title: const Text(
        '文件',
        style: TextStyle(fontSize: 14, fontFamily: "微软雅黑"),
      ),
      body: const SizedBox.shrink(),
      onTap: () {
        if (router.location != '/file') {
          router.goNamed('file');
        }
      },
      items: [
        PaneItem(
          icon: const Icon(FluentIcons.reminder_time),
          title: const Text(
            '最近播放',
            style: TextStyle(fontSize: 14, fontFamily: "微软雅黑"),
          ),
          body: const SizedBox.shrink(),
          onTap: () {
            if (router.location != '/recentlyPlayed') {
              router.goNamed('recentlyPlayed');
            }
          },
        ),
        PaneItem(
          icon: const Icon(FluentIcons.document_set),
          title: const Text(
            '我的资料',
            style: TextStyle(fontSize: 14, fontFamily: "微软雅黑"),
          ),
          body: const SizedBox.shrink(),
          onTap: () {
            if (router.location != '/myProfile') {
              router.goNamed('myProfile');
            }
          },
        ),
      ],
    ),
    PaneItem(
        icon: const Icon(FluentIcons.photo_collection),
        title: const Text(
          '相册',
          style: TextStyle(fontSize: 14, fontFamily: "微软雅黑"),
        ),
        body: const SizedBox.shrink(),
        onTap: () {
          if (router.location != '/photo') {
            router.goNamed('photo');
          }
        }),
    PaneItem(
        icon: const Icon(FluentIcons.heart),
        title: const Text(
          '收藏夹',
          style: TextStyle(fontSize: 14, fontFamily: "微软雅黑"),
        ),
        body: const SizedBox.shrink(),
        onTap: () {
          if (router.location != '/favorites') {
            router.goNamed('favorites');
          }
        }),
    PaneItem(
        icon: const Icon(FluentIcons.password_field),
        title: const Text(
          '密码箱',
          style: TextStyle(fontSize: 14, fontFamily: "微软雅黑"),
        ),
        body: const SizedBox.shrink(),
        onTap: () {
          if (router.location != '/password') {
            router.goNamed('password');
          }
        }),
    PaneItem(
        icon: const Icon(FluentIcons.subscribe),
        title: const Text(
          '订阅',
          style: TextStyle(fontSize: 14, fontFamily: "微软雅黑"),
        ),
        body: const SizedBox.shrink(),
        onTap: () {
          if (router.location != '/subscribe') {
            router.goNamed('subscribe');
          }
        }),
    PaneItem(
        icon: const Icon(FluentIcons.empty_recycle_bin),
        title: const Text(
          '回收站',
          style: TextStyle(fontSize: 14, fontFamily: "微软雅黑"),
        ),
        body: const SizedBox.shrink(),
        onTap: () {
          if (router.location != '/recycle') {
            router.goNamed('recycle');
          }
        }),
    PaneItemSeparator(),
    PaneItem(
      icon: const Icon(FluentIcons.account_management),
      title: const Text(
        '传输列表',
        style: TextStyle(fontSize: 14, fontFamily: "微软雅黑"),
      ),
      body: const SizedBox.shrink(),
      onTap: () {
        if (router.location != '/transferList') {
          router.goNamed('transferList');
        }
      },
    )
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
          // backgroundColor: Colors.red,  //导航背景颜色
          height: 36,
          leading: const Text(""),
          title: WindowTitleBarBox(child: MoveWindow()),
          actions: Platform.isWindows
              ? Container(
                  alignment: Alignment.centerRight,
                  width: 140,
                  child: const WindowButtons(),
                )
              : Text("")),
      //右侧区域
      paneBodyBuilder: (item, child) {
        return widget.child;
      },
      pane: NavigationPane(
        size: const NavigationPaneSize(openWidth: 220), //配置左侧宽度
        selected: topIndex,
        onChanged: (index) => setState(() => topIndex = index),
        displayMode: PaneDisplayMode.open,
        items: items,
        footerItems: [
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('Settings'),
            body: const SizedBox.shrink(),
            onTap: () {
              if (router.location != '/settings') {
                router.goNamed('settings');
              }
            },
          ),
          PaneItemAction(
            icon: const Icon(FluentIcons.add),
            title: const Text('Add New Item'),
            onTap: () {
              // Your Logic to Add New `NavigationPaneItem`
              items.add(
                PaneItem(
                  icon: const Icon(FluentIcons.new_folder),
                  title: const Text('New Item'),
                  body: const Center(
                    child: Text(
                      'This is a newly added Item',
                    ),
                  ),
                ),
              );
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

//定义的公共组件
class NavigationBodyItem extends StatelessWidget {
  const NavigationBodyItem({
    Key? key,
    this.header,
    this.content,
  }) : super(key: key);

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
