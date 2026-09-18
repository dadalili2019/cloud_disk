import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show showMenu, PopupMenuItem;

class FilePage extends StatefulWidget {
  const FilePage({super.key});

  @override
  State<FilePage> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  bool _isGridView = false;

  //TODO 未来替换为共享磁盘的 文件内容列表
  final List _filesList = [
    {
      "id": "1",
      "title": "Nestjs仿小米商城项目实战视频教程",
      "updateTime": "2021-12-13",
      "size": "128MB",
    },
    {
      "id": "2",
      "title": "Flutter仿小米商城项目实战视频教程",
      "updateTime": "2021-12-13",
      "size": "128MB",
    },
    {
      "id": "3",
      "title": "Linux+Docker运维系列教程",
      "updateTime": "2021-12-13",
      "size": "128MB",
    },
    {
      "id": "4",
      "title": "Golang Beego仿小米商城项目实战视频教程",
      "updateTime": "2021-12-13",
      "size": "128MB",
    },
    {
      "id": "5",
      "title": "Serverless Egg.js Mysql Vue3.x打造全栈无人点餐 无人收银系统",
      "updateTime": "2021-12-13",
      "size": "128MB",
    },
    {
      "id": "6",
      "title": "Vue3教程_Vue3.x+Ts+Antd打造舆情监控系统",
      "updateTime": "2021-12-13",
      "size": "128MB",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.withPadding(
      padding: const EdgeInsets.only(left: 3), // 调整此值以改变左边距
      header: _headerWidget(),
      content: _isGridView ? _gridViewWidget() : _listViewWidget(),
    );
  }

  Widget _headerWidget() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(30, 20, 20, 10),
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "文件",
                style: TextStyle(fontSize: 20, fontFamily: "微软雅黑"),
              ),
              SizedBox(
                width: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                        icon: const Icon(
                          FluentIcons.search,
                          size: 17,
                        ),
                        onPressed: () {}),
                    _addButtonWidget()
                  ],
                ),
              )
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(30, 10, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //左侧
              SizedBox(
                width: 100,
                child: Row(
                  children: [
                    Container(
                      width: 15, // 设置宽度
                      height: 15, // 设置高度
                      child: Checkbox(
                        checked: false,
                        onChanged: (value) {
                          // 处理Checkbox状态变化的逻辑
                        },
                      ),
                    ),
                    const Text("  共10项")
                  ],
                ),
              ),
              //右侧
              SizedBox(
                width: 160,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sortButtonWidget(),
                    // const SizedBox(
                    //   width: 120,
                    //   child: Row(
                    //     children: [
                    //       Icon(
                    //         FluentIcons.sort,
                    //         size: 12,
                    //       ),
                    //       SizedBox(width: 8),
                    //       Text(
                    //         "按照名称排序",
                    //         style: TextStyle(fontSize: 12, fontFamily: "微软雅黑"),
                    //       )
                    //     ],
                    //   ),
                    // ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _isGridView
                            ? IconButton(
                                icon: const Icon(
                                  FluentIcons.collapse_menu,
                                  size: 16,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isGridView = !_isGridView;
                                  });
                                },
                              )
                            : IconButton(
                                icon: const Icon(
                                  FluentIcons.table,
                                  size: 16,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isGridView = !_isGridView;
                                  });
                                },
                              ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _listViewWidget() {
    return ListView.builder(
        padding: const EdgeInsets.only(top: 20),
        itemCount: _filesList.length,
        itemBuilder: (context, index) {
          return HoverButton(
              onPressed: () {}, //必须配置 配置以后才可以监听到state状态
              builder: (context, state) {
                // print(state);
                // print(state.contains(WidgetState.hovered));
                return Container(
                  decoration: BoxDecoration(
                      color: state.contains(WidgetState.hovered)
                          ? const Color.fromRGBO(245, 245, 246, 1)
                          : Colors.white),
                  padding: const EdgeInsets.all(6.0),
                  child: ListTile(
                    leading: const Icon(
                      FluentIcons.fabric_folder_fill,
                      color: Color.fromRGBO(126, 145, 250, 1),
                      size: 28,
                    ),
                    title: Text("${_filesList[index]["title"]}"),
                  ),
                );
              });
        });
  }

  //右侧增加按钮的菜单组件
  Widget _addButtonWidget() {
    return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Listener(
          onPointerDown: (e) {
            print(e.position.dx);
            print(e.position.dy);
            print(e.kind);
            print(e.buttons); //1 表示鼠标的左键  2表示右键
            if (e.kind == PointerDeviceKind.mouse && e.buttons == 1) {
              showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(
                      e.position.dx,
                      e.position.dy - 22,
                      MediaQuery.of(context).size.width - e.position.dx,
                      MediaQuery.of(context).size.height - e.position.dy),
                  items: [
                    const PopupMenuItem(
                      height: 44,
                      enabled: false,
                      child: Row(
                        children: [
                          Text("添加文件",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontFamily: "微软雅黑"))
                        ],
                      ),
                    ),
                    PopupMenuItem(
                        onTap: () async {},
                        height: 44,
                        child: const Row(children: [
                          Padding(
                            padding: EdgeInsets.only(left: 0, right: 5),
                            child: Icon(FluentIcons.open_file),
                          ),
                          Text(
                            "上传文件",
                            style: TextStyle(fontSize: 12, fontFamily: "微软雅黑"),
                          )
                        ])),
                    PopupMenuItem(
                        onTap: () async {},
                        height: 44,
                        child: const Row(children: [
                          Padding(
                            padding: EdgeInsets.only(left: 0, right: 5),
                            child: Icon(FluentIcons.fabric_folder_upload),
                          ),
                          Text(
                            "上传文件夹",
                            style: TextStyle(fontSize: 12, fontFamily: "微软雅黑"),
                          )
                        ])),
                    const PopupMenuItem(
                        height: 44,
                        child: Row(children: [
                          Padding(
                            padding: EdgeInsets.only(left: 0, right: 5),
                            child: Icon(FluentIcons.fabric_new_folder),
                          ),
                          Text(
                            "新建文件夹",
                            style: TextStyle(fontSize: 12, fontFamily: "微软雅黑"),
                          )
                        ])),
                    const PopupMenuItem(
                      enabled: false,
                      height: 44,
                      child: Row(
                        children: [
                          Text("添加到相簿",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontFamily: "微软雅黑"))
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                        height: 44,
                        child: Row(children: [
                          Padding(
                            padding: EdgeInsets.only(left: 0, right: 5),
                            child: Icon(FluentIcons.camera),
                          ),
                          Text(
                            "上传照片视频",
                            style: TextStyle(fontSize: 12, fontFamily: "微软雅黑"),
                          )
                        ])),
                    const PopupMenuItem(
                        height: 44,
                        child: Row(children: [
                          Padding(
                            padding: EdgeInsets.only(left: 0, right: 5),
                            child: Icon(FluentIcons.fabric_folder),
                          ),
                          Text(
                            "照片文件夹",
                            style: TextStyle(fontSize: 12, fontFamily: "微软雅黑"),
                          )
                        ])),
                  ]);
            }
          },
          child: SizedBox(
            width: 30,
            height: 30,
            child: IconButton(
                icon: const Icon(
                  FluentIcons.add,
                  size: 16,
                ),
                style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.blue),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                    shape: WidgetStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)))),
                onPressed: null),
          ),
        ));
  }

  //排序组件
  Widget _sortButtonWidget() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Listener(
        onPointerDown: (e) {
          showMenu(
              color: Colors.white,
              context: context,
              position: RelativeRect.fromLTRB(
                  e.position.dx,
                  e.position.dy - 24,
                  MediaQuery.of(context).size.width - e.position.dx,
                  MediaQuery.of(context).size.height - e.position.dy),
              items: const [
                PopupMenuItem(
                    height: 44,
                    child: Row(children: [
                      Padding(
                        padding: EdgeInsets.only(left: 0, right: 10),
                        child: Icon(
                          FluentIcons.accept,
                          size: 12,
                        ),
                      ),
                      Text(
                        "资源名称",
                        style: TextStyle(fontSize: 12, fontFamily: "微软雅黑"),
                      )
                    ])),
                PopupMenuItem(
                    height: 44,
                    child: Row(children: [
                      Padding(
                        padding: EdgeInsets.only(left: 10, right: 10),
                        child: Text(""),
                      ),
                      Text(
                        "创建时间",
                        style: TextStyle(fontSize: 12, fontFamily: "微软雅黑"),
                      )
                    ])),
                PopupMenuItem(
                    height: 44,
                    child: Row(children: [
                      Padding(
                        padding: EdgeInsets.only(left: 10, right: 10),
                        child: Text(""),
                      ),
                      Text(
                        "修改时间",
                        style: TextStyle(fontSize: 12, fontFamily: "微软雅黑"),
                      )
                    ])),
                PopupMenuItem(
                    height: 44,
                    child: Row(children: [
                      Padding(
                        padding: EdgeInsets.only(left: 10, right: 10),
                        child: Text(""),
                      ),
                      Text(
                        "文档大小",
                        style: TextStyle(fontSize: 12, fontFamily: "微软雅黑"),
                      )
                    ])),
                PopupMenuItem(
                  enabled: false,
                  height: 5,
                  child: Row(
                    children: const [Expanded(child: Divider())],
                  ),
                ),
                PopupMenuItem(
                    height: 44,
                    child: Row(children: [
                      Padding(
                        padding: EdgeInsets.only(left: 0, right: 10),
                        child: Icon(
                          FluentIcons.accept,
                          size: 12,
                        ),
                      ),
                      Text(
                        "升序",
                        style: TextStyle(fontSize: 12, fontFamily: "微软雅黑"),
                      )
                    ])),
                PopupMenuItem(
                    height: 44,
                    child: Row(children: [
                      Padding(
                        padding: EdgeInsets.only(left: 10, right: 10),
                        child: Text(""),
                      ),
                      Text(
                        "降序",
                        style: TextStyle(fontSize: 12, fontFamily: "微软雅黑"),
                      )
                    ])),
              ]);
        },
        child: const SizedBox(
          width: 120,
          child: Row(
            children: [
              Icon(
                FluentIcons.sort,
                size: 12,
              ),
              SizedBox(width: 8),
              Text(
                "按照名称排序",
                style: TextStyle(fontSize: 12, fontFamily: "微软雅黑"),
              )
            ],
          ),
        ),
      ),
    );
  }

  //横向列表展示
  Widget _gridViewWidget() {
    return Padding(
      padding: const EdgeInsets.only(left: 0), // 调整此值以改变左边距
      child: GridView.builder(
        itemCount: _filesList.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          maxCrossAxisExtent: 160,
        ),
        itemBuilder: (context, index) {
          return HoverButton(
            onPressed: () {}, // 必须配置 配置以后才可以监听到state状态
            builder: (context, state) {
              return Container(
                decoration: BoxDecoration(
                  color: state.contains(WidgetState.hovered)
                      ? const Color.fromRGBO(245, 245, 246, 1)
                      : Colors.white,
                ),
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      FluentIcons.fabric_folder_fill,
                      size: 68,
                      color: Color.fromRGBO(126, 145, 250, 1),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      height: 46,
                      width: double.infinity,
                      child: Text(
                        "${_filesList[index]["title"]}",
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
