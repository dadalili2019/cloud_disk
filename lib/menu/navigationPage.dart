import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';

//引入material UI库使用里面的方法和组件
import 'package:flutter/material.dart' show showMenu, PopupMenuItem;

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
    PaneItem(
        icon: const Icon(FluentIcons.home),
        title: const Text(
          '首页',
          style: TextStyle(fontSize: 14, fontFamily: "微软雅黑"),
        ),
        body: const SizedBox.shrink(),
        onTap: () {
          if (router.location != '/home') {
            router.goNamed('home');
          }
        }),
    PaneItem(
        icon: const Icon(FluentIcons.developer_tools),
        title: const Text(
          '工具箱',
          style: TextStyle(fontSize: 14, fontFamily: "微软雅黑"),
        ),
        body: const SizedBox.shrink(),
        onTap: () {
          if (router.location != '/tools') {
            router.goNamed('tools');
          }
        }),
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
        PaneItem(
          icon: const Icon(FluentIcons.people_external_share),
          title: const Text(
            '共享文件夹',
            style: TextStyle(fontSize: 14, fontFamily: "微软雅黑"),
          ),
          body: const SizedBox.shrink(),
          onTap: () {
            if (router.location != '/shareFolder') {
              router.goNamed('shareFolder');
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
      icon: const Icon(FluentIcons.chevron_unfold10),
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
    ),
    PaneItem(
      enabled: false,
      icon: const Text(
        '36.7GB/100GB',
        style: TextStyle(fontSize: 12, fontFamily: "微软雅黑", color: Colors.grey),
      ),
      body: const SizedBox.shrink(),
      trailing: Padding(
        padding: const EdgeInsets.only(right: 32),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent, // 在 GestureDetector 上添加这个属性
          onTap: () {
            if (router.location != '/capacityInformation') {
              router.goNamed('capacityInformation');
            }
          },
          child: Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  "容量信息",
                  style: TextStyle(
                      fontSize: 11, fontFamily: "微软雅黑", color: Colors.blue),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    ),
    PaneItem(
      enabled: false,
      icon: const Padding(
        padding: EdgeInsets.only(left: 2),
        child: SizedBox(
          width: 160, //使 ProgressBar 更长
          child: ProgressBar(value: 60),
        ),
      ),
      body: const SizedBox.shrink(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    //获取屏幕的宽度高度  窗口最大化 最小化的时候会重新出发build方法
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

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
        size: const NavigationPaneSize(openWidth: 220),
        //配置左侧宽度
        selected: topIndex,
        onChanged: (index) => setState(() => topIndex = index),
        displayMode: PaneDisplayMode.open,
        items: items,
        footerItems: [
          PaneItem(
              enabled: false,
              icon: const Icon(FluentIcons.user_window),
              title: const Text(
                '用户123321',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              body: const SizedBox.shrink(),
              onTap: () {
                if (router.location != '/settings') {
                  router.goNamed('settings');
                }
              },
              trailing: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: IconButton(
                    icon: const Icon(FluentIcons.settings),
                    onPressed: () {
                      print("设置");
                      showMenu(
                          context: context,
                          position: RelativeRect.fromLTRB(
                              200, screenHeight - 280, screenWidth - 200, 300),
                          items: const [
                            PopupMenuItem(
                              height: 44,
                              child: Row(
                                children: [
                                  Text("个人中心",
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                          fontFamily: "微软雅黑"))
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              height: 44,
                              child: Row(
                                children: [
                                  Text("帮助反馈",
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                          fontFamily: "微软雅黑"))
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              height: 44,
                              child: Row(
                                children: [
                                  Text("关于",
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                          fontFamily: "微软雅黑"))
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              height: 44,
                              child: Row(
                                children: [
                                  Text("设置",
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                          fontFamily: "微软雅黑"))
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              height: 44,
                              child: Row(
                                children: [
                                  Text("退出登录",
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                          fontFamily: "微软雅黑"))
                                ],
                              ),
                            ),
                          ]);
                    }),
              )),
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
