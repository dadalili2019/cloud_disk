import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart'
    show
        AlertDialog,
        InputDecoration,
        PopupMenuItem,
        TextButton,
        TextField,
        showMenu;

import 'files_loader.dart';
import 'share_folder_grid_view.dart';
import 'share_folder_list_view.dart';

class ShareFolder extends StatefulWidget {
  const ShareFolder({super.key});

  @override
  State<ShareFolder> createState() => _ShareFolderState();
}

class _ShareFolderState extends State<ShareFolder> {
  bool _isGridView = false;

  //文件内容集合
  late List<Map<String, String>> _filesList;

  late String _sharedFolderPath; // 新增字段用于存储共享文件夹路径

  List<File> _selectedFiles = []; // 用于存储选择的文件列表

  //当前目录的顶级目录  如果为空则使用默认地址
  static const String _shareFolderRootPath = r'\\ALPHA\shareFolder';

  static const String _shareFolderUserRootPath = r'\\ALPHA\Users';

  static const Map<String, String> shareFolders = {
    'rootPath': r'\\ALPHA\shareFolder',
    'userRootPath': r'\\ALPHA\Users',
  };

  //文件排序初始化规则
  String _order = "desc"; //倒序
  String _orderType = "modifyTime"; //文件修改时间

  @override
  void initState() {
    super.initState();
    _sharedFolderPath = _shareFolderRootPath; // 初始化共享文件夹路径
    _filesList = FilesLoader.loadFilesAndDirectories(_sharedFolderPath);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.withPadding(
      padding: const EdgeInsets.only(left: 3),
      header: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(30, 20, 20, 10),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _sharedFolderPath, // 使用目标路径值
                  style: const TextStyle(fontSize: 20, fontFamily: "微软雅黑"),
                ),
                SizedBox(
                  width: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: const Icon(
                          FluentIcons.add_connection,
                          size: 17,
                        ),
                        onPressed: () async {
                          String? sharePath = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              String inputText = '';
                              return AlertDialog(
                                title: const Text('更改连接目录地址'),
                                content: TextField(
                                  onChanged: (value) {
                                    inputText = value;
                                  },
                                  decoration: const InputDecoration(
                                    hintText: '输入路径',
                                  ),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    // 修改这里的 FlatButton 为 TextButton
                                    onPressed: () {
                                      Navigator.pop(context); // 关闭对话框
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(inputText);
                                    },
                                    child: Text('确定'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (sharePath != null && sharePath.isNotEmpty) {
                            print('Performing search operation: $sharePath');

                            List<Map<String, String>> filesList =
                                await FilesLoader.loadFilesAndDirectories(
                                    sharePath); // 加载父级目录下的文件列表
                            setState(() {
                              _filesList = filesList; // 更新文件列表
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          FluentIcons.search,
                          size: 17,
                        ),
                        onPressed: () async {
                          String? searchQuery = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              String inputText = '';
                              return AlertDialog(
                                title: const Text('搜索文件'),
                                content: TextField(
                                  onChanged: (value) {
                                    inputText = value;
                                  },
                                  decoration: const InputDecoration(
                                    hintText: '输入文件名',
                                  ),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    // 修改这里的 FlatButton 为 TextButton
                                    onPressed: () {
                                      Navigator.pop(context); // 关闭对话框
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(inputText);
                                    },
                                    child: Text('搜索'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (searchQuery != null && searchQuery.isNotEmpty) {
                            // 根据搜索查询执行搜索操作
                            print('Performing search operation: $searchQuery');
                            _sharedFolderPath = searchQuery;
                            List<Map<String, String>> searchResults =
                                await FilesLoader.searchFiles(
                                    _sharedFolderPath, searchQuery);
                            _updateSearchResults(searchResults);
                          }
                        },
                      ),
                      // _addButtonWidget(context),
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
                  width: 160,
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
                      Text("  共 ${_filesList.length} 项"),
                      const SizedBox(width: 10),
                      IconButton(
                          icon: const Icon(
                            FluentIcons.home,
                            size: 15,
                          ),
                          onPressed: () {
                            _goRootpath();
                          }),
                      IconButton(
                          icon: const Icon(
                            FluentIcons.refresh,
                            size: 15,
                          ),
                          onPressed: () {
                            _refresh();
                          }),
                      // const SizedBox(width: 5),
                      IconButton(
                        icon: const Icon(
                          FluentIcons.chevron_left_med,
                          size: 15,
                        ),
                        onPressed: shareFolders.containsValue(_sharedFolderPath)
                            ? null // 如果当前路径是 顶级目录，则禁用按钮
                            : goToParentDirectory, // 否则允许点击执行 goToParentDirectory 方法
                      ),
                    ],
                  ),
                ),
                //右侧
                SizedBox(
                  width: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      //文件排序组件
                      _sortButtonWidget(context),
                      // MouseRegion(
                      // cursor: SystemMouseCursors.click,
                      // child: Padding(
                      // padding: const EdgeInsets.only(right: 10),
                      // child: _isGridView
                      // ? IconButton(
                      //     icon: const Icon(
                      //       FluentIcons.collapse_menu,
                      //       size: 16,
                      //     ),
                      //     onPressed: _toggleGridView,
                      //   )
                      // : IconButton(
                      //     icon: const Icon(
                      //       FluentIcons.table,
                      //       size: 16,
                      //     ),
                      //     onPressed: _toggleGridView,
                      //     // onPressed: (){},
                      //   ),
                      // ),
                      // )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
      content: _isGridView
          ? gridViewWidget(_filesList)
          : listViewWidget(_filesList, (folderPath) {
              setState(() {
                _sharedFolderPath = folderPath; // 更新共享文件夹路径
                _filesList =
                    FilesLoader.loadFilesAndDirectories(_sharedFolderPath);
              });
            },
              _sharedFolderPath, // 传递当前共享文件夹路径
              _updateFilesList),
    );
  }

  void _goRootpath() {
    setState(() {
      _filesList =
          FilesLoader.loadFilesAndDirectories(_shareFolderRootPath); // 更新文件列表
    });
  }

  void _refresh() {
    setState(() {
      _filesList =
          FilesLoader.loadFilesAndDirectories(_sharedFolderPath); // 更新文件列表
    });
  }

  void _updateSearchResults(List<Map<String, String>> results) {
    setState(() {
      List<String> filePaths =
          results.map((result) => result['directoryPath'] ?? '').toList();
      print(filePaths.first);
      _filesList =
          FilesLoader.loadFilesAndDirectories(filePaths.first); // 更新文件列表
    });
  }

  void _updateFilesList() {
    setState(() {
      _filesList =
          FilesLoader.loadFilesAndDirectories(_sharedFolderPath); // 更新文件列表
    });
  }

  void _toggleGridView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  //鼠标双击进入子目录
  void goToParentDirectory() async {
    String currentPath = _sharedFolderPath; // 获取当前目录路径
    if (currentPath.isNotEmpty) {
      // 确保当前路径非空
      int lastIndex = currentPath.lastIndexOf('\\'); // 找到最后一个 '\\' 的索引
      if (lastIndex != -1) {
        // 如果找到了路径分隔符
        String parentPath = currentPath.substring(0, lastIndex); // 获取父级路径
        setState(() {
          _sharedFolderPath = parentPath; // 更新目标路径为父级路径
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
  }

  Future<void> _openFilePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _selectedFiles = result.files.map((file) => File(file.path!)).toList();
      });
    }
  }

  Future<void> _uploadFiles() async {
    List<Map<String, String>> newFiles = _selectedFiles.map((file) {
      return {
        'id': _filesList.length.toString(),
        'title': file.path.split('\\').last,
        'updateTime': DateTime.now().toString(),
        'size': '${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
        'path': file.path,
      };
    }).toList();

    setState(() {
      _filesList.addAll(newFiles);
    });
  }

  Future<void> _copyFiles() async {
    for (var file in _selectedFiles) {
      // 构建目标目录中的文件路径，使用文件的名称作为新的文件名
      // String newFilePath = 'C:/path/to/target/directory/${file.path.split(Platform.pathSeparator).last}';
      print("上传的文件目录为: ${_sharedFolderPath}");
      String newFilePath = _sharedFolderPath;

      Map<String, String> fileInfo = new Map<String, String>();

      bool flag = true;

      try {
        // 创建目标文件对象
        File newFile = File(newFilePath);

        FileStat fileStat = await file.stat();

        // 输出文件权限信息
        print('文件权限信息：');
        print('类型：${fileStat.type}');
        print('权限：${fileStat.modeString()}');
        print('大小：${fileStat.size} bytes');
        print('修改时间：${fileStat.modified}');
        print('访问时间：${fileStat.accessed}');

        // 拷贝文件到目标目录
        // TODO 目前发现copy事件会发生 PathAccessException: Cannot copy file to '\\ALPHA\shareFolder', path = 'C:\Users\12814\Desktop\VPN.txt' (OS Error: 拒绝访问)。的错误。
        // 待修复
        await file.copy(newFilePath);

        // 构建新文件的信息
        fileInfo = {
          'id': _filesList.length.toString(),
          'title': newFile.path.split(Platform.pathSeparator).last,
          'updateTime': DateTime.now().toString(),
          'size':
              '${(newFile.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
          'path': newFile.path,
        };
      } catch (e) {
        // 发生异常时弹窗提示异常信息
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('文件复制失败'),
              content: Text('$e'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('确定'),
                ),
              ],
            );
          },
        );
        print('文件上传失败：$e');
        flag = false;
      }

      //如果发生异常就不进行添加
      if (flag) {
        // 将新文件信息添加到文件列表中
        setState(() {
          _filesList.add(fileInfo);
        });
      }
    }
  }

  Future<void> checkFilePermissions(String filePath) async {}

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
                        onTap: () async {
                          await _openFilePicker(); // 打开文件选择器
                          await _uploadFiles(); // 上传文件并更新文件列表
                          await _copyFiles();
                        },
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
                          Text("添加其他文件",
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
                            "上传图片",
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
                            "上传视频",
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
            items: [
              PopupMenuItem(
                onTap: () {
                  setState(() {
                    _orderType = "updateTime"; // 设置排序类型为按照创建日期
                    _filesList.sort((a, b) =>
                        (a[_orderType] ?? "").compareTo(b[_orderType] ?? ""));
                  });
                },
                height: 44,
                child: const Row(
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
                onTap: () {
                  setState(() {
                    _orderType = "size"; // 设置排序类型为按照文档大小
                    _filesList.sort((a, b) =>
                        (a[_orderType] ?? "").compareTo(b[_orderType] ?? ""));
                  });
                },
                height: 44,
                child: const Row(
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
              const PopupMenuItem(
                enabled: false,
                height: 5,
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () {
                  setState(() {
                    _filesList.sort((a, b) =>
                        _compareDocumentSize(a[_orderType], b[_orderType]));
                  });
                },
                height: 44,
                child: const Row(
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
                onTap: () {
                  setState(() {
                    print(_orderType);
                    _filesList.sort((a, b) => _compareDocumentSizeDescending(
                        a[_orderType], b[_orderType]));
                  });
                },
                height: 44,
                child: const Row(
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
                "排序",
                style: TextStyle(fontSize: 12, fontFamily: "微软雅黑"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _compareDocumentSize(String? a, String? b) {
    double sizeA = double.tryParse(a ?? "0") ?? 0;
    double sizeB = double.tryParse(b ?? "0") ?? 0;
    return sizeB.compareTo(sizeA); // 反转返回值以实现升序排序
  }

  int _compareDocumentSizeDescending(String? a, String? b) {
    double sizeA = double.tryParse(a ?? "0") ?? 0;
    double sizeB = double.tryParse(b ?? "0") ?? 0;
    return sizeA.compareTo(sizeB); // 反转返回值以实现降序排序
  }
}
