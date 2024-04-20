// share_folder_headerBak.dart
import 'dart:ui';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show showMenu, PopupMenuItem;

import '../files_loader.dart';

class HeaderWidget extends StatefulWidget {
  final bool isGridView;
  final List<Map<String, String>> filesList;
  final VoidCallback onGridViewToggle; // 回调函数，用于切换视图模式
  String sharedFolderPath; // 添加目标路径参数

  HeaderWidget({
    required this.isGridView,
    required this.filesList,
    required this.onGridViewToggle,
    required this.sharedFolderPath, // 接收目标路径参数
  });

  @override
  State<StatefulWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  late List<Map<String, String>> _filesList;

  @override
  void initState() {
    super.initState();
    _filesList = widget.filesList; // 初始化_filesList为初始的文件列表
  }

  void goToParentDirectory() async {
    String currentPath = widget.sharedFolderPath; // 获取当前目录路径
    if (currentPath.isNotEmpty) {
      // 确保当前路径非空
      int lastIndex = currentPath.lastIndexOf('\\'); // 找到最后一个 '\\' 的索引
      if (lastIndex != -1) {
        // 如果找到了路径分隔符
        String parentPath = currentPath.substring(0, lastIndex); // 获取父级路径
        setState(() {
          widget.sharedFolderPath = parentPath; // 更新目标路径为父级路径
        });
        print('上一级目录：$parentPath'); // 输出调试信息
        List<Map<String, String>> filesList =
            await FilesLoader.loadFilesAndDirectories(
                parentPath); // 加载父级目录下的文件列表
        setState(() {
          _filesList = filesList; // 更新文件列表
        });
      }
    }
    print('当前设置的_fileList列表数据为: $_filesList');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(30, 20, 20, 10),
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.sharedFolderPath, // 使用目标路径值
                style: const TextStyle(fontSize: 20, fontFamily: "微软雅黑"),
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
                      onPressed: () {},
                    ),
                    _addButtonWidget(context),
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
                    Text("  共 ${widget.filesList.length} 项"),
                    const SizedBox(width: 7),
                    IconButton(
                      icon: const Icon(
                        FluentIcons.chevron_left_med,
                        size: 15,
                      ),
                      onPressed: goToParentDirectory,
                    ),
                  ],
                ),
              ),
              //右侧
              SizedBox(
                width: 160,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sortButtonWidget(context),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: widget.isGridView
                            ? IconButton(
                                icon: const Icon(
                                  FluentIcons.collapse_menu,
                                  size: 16,
                                ),
                                onPressed: widget.onGridViewToggle,
                              )
                            : IconButton(
                                icon: const Icon(
                                  FluentIcons.table,
                                  size: 16,
                                ),
                                onPressed: widget.onGridViewToggle,
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

//右侧增加按钮的菜单组件
  Widget _addButtonWidget(BuildContext context) {
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
                    backgroundColor: ButtonState.all(Colors.blue),
                    foregroundColor: ButtonState.all(Colors.white),
                    shape: ButtonState.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)))),
                onPressed: null),
          ),
        ));
  }

//排序组件
  Widget _sortButtonWidget(BuildContext context) {
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
              MediaQuery.of(context).size.height - e.position.dy,
            ),
            items: const [
              PopupMenuItem(
                height: 44,
                child: Row(
                  children: [
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
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                height: 44,
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      child: Text(""),
                    ),
                    Text(
                      "创建时间",
                      style: TextStyle(fontSize: 12, fontFamily: "微软雅黑"),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                height: 44,
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      child: Text(""),
                    ),
                    Text(
                      "修改时间",
                      style: TextStyle(fontSize: 12, fontFamily: "微软雅黑"),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                height: 44,
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      child: Text(""),
                    ),
                    Text(
                      "文档大小",
                      style: TextStyle(fontSize: 12, fontFamily: "微软雅黑"),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                enabled: false,
                height: 5,
                child: Row(
                  children: const [
                    Expanded(
                      child: Divider(),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                height: 44,
                child: Row(
                  children: [
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
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                height: 44,
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      child: Text(""),
                    ),
                    Text(
                      "降序",
                      style: TextStyle(fontSize: 12, fontFamily: "微软雅黑"),
                    ),
                  ],
                ),
              ),
            ],
          );
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
