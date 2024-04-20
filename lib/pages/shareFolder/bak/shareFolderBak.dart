import 'package:fluent_ui/fluent_ui.dart';

import '../files_loader.dart';
import '../share_folder_grid_view.dart';
import 'share_folder_headerBak.dart';
import '../share_folder_list_view.dart';

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
    _filesList = FilesLoader.loadFilesAndDirectories(_sharedFolderPath);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.withPadding(
      padding: const EdgeInsets.only(left: 3),
      header: HeaderWidget(
        isGridView: _isGridView,
        filesList: _filesList,
        onGridViewToggle: _toggleGridView,
        sharedFolderPath: _sharedFolderPath,
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
}
