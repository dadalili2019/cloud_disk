import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';

import 'share_folder_grid_view.dart';
import 'share_folder_header.dart';
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


  @override
  void initState() {
    super.initState();
    _sharedFolderPath = r'\\ALPHA\shareFolder'; // 初始化共享文件夹路径
    _loadFilesAndDirectories();
  }

  void _loadFilesAndDirectories() {
    // var sharedFolderPath = r'\\ALPHA\shareFolder';
    var sharedDirectory = Directory(_sharedFolderPath);

    if (sharedDirectory.existsSync()) {
      var files = sharedDirectory.listSync(recursive: true);
      _filesList = [];

      for (var entity in files) {
        if (entity is File) {
          _filesList.add({
            "id": _filesList.length.toString(),
            "title": entity.path.split('\\').last,
            "updateTime": entity.lastModifiedSync().toString(),
            "size":
                '${(entity.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
          });
        } else if (entity is Directory) {
          _filesList.add({
            "id": _filesList.length.toString(),
            "title": entity.path.split('\\').last,
            "updateTime": _getLastModifiedTime(entity),
            "size": 'Directory',
          });
        }
      }
    } else {
      print('Shared directory not found.');
      _filesList = [];
    }

    setState(() {}); // 更新界面显示
  }

  String _getLastModifiedTime(Directory directory) {
    var latestModifiedTime = DateTime(1900); // 初始时间设置为较早的时间
    directory.listSync().forEach((entity) {
      if (entity is File) {
        var fileModifiedTime = entity.lastModifiedSync();
        if (fileModifiedTime.isAfter(latestModifiedTime)) {
          latestModifiedTime = fileModifiedTime;
        }
      }
    });
    return latestModifiedTime.toString();
  }
  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.withPadding(
      padding: const EdgeInsets.only(left: 3),
      header: HeaderWidget(
        isGridView: _isGridView,
        filesList: _filesList,
        onGridViewToggle: _toggleGridView,
        sharedFolderPath: _sharedFolderPath, // 将 sharedFolderPath 的值传递给 HeaderWidget
      ), // 使用 HeaderWidget 类
      content: _isGridView
          ? gridViewWidget(_filesList)
          : listViewWidget(_filesList), // 使用导入的 list view 或 grid view widget
    );
  }

  void _toggleGridView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }
}
