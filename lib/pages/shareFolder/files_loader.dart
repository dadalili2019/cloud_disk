import 'dart:io';

class FilesLoader {
  /// 读取指定目录下的所有文件和文件夹
  static List<Map<String, String>> loadFilesAndDirectories(
      String sharedFolderPath,
      {String? parentPath}) {
    var sharedDirectory = Directory(sharedFolderPath);
    List<Map<String, String>> filesList = [];

    if (sharedDirectory.existsSync()) {
      //sharedDirectory.listSync(recursive: true) 表示从 sharedDirectory 这个目录开始，递归地获取所有文件和子目录的信息
      var files = sharedDirectory.listSync(recursive: false);

      for (var entity in files) {
        if (entity is File) {
          filesList.add({
            "id": filesList.length.toString(),
            "title": entity.path.split(Platform.pathSeparator).last,
            "updateTime": entity.lastModifiedSync().toString(),
            "size":
                '${(entity.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
            "path": entity.path, // 添加文件路径信息
          });
        } else if (entity is Directory) {
          String folderPath = entity.path;
          String path = parentPath != null
              ? '$parentPath${Platform.pathSeparator}$folderPath'
              : folderPath;
          filesList.add({
            "id": filesList.length.toString(),
            "title": entity.path.split(Platform.pathSeparator).last,
            "updateTime": _getLastModifiedTime(entity),
            "size": 'Directory',
            "path": path, // 添加文件夹路径信息
          });
        }
      }
    } else {
      print('Shared directory not found.');
    }
    return filesList;
  }

  ///读取指定目录下的指定文件
  static Future<List<Map<String, String>>> searchFiles(
      String directoryPath, String fileName) async {
    Directory directory = Directory(directoryPath);
    if (!await directory.exists()) {
      throw Exception('Directory does not exist');
    }

    List<Map<String, String>> searchResults = [];
    await _searchFilesRecursive(directory, fileName, searchResults);
    return searchResults;
  }

  static Future<void> _searchFilesRecursive(Directory directory,
      String fileName, List<Map<String, String>> searchResults) async {
    await for (FileSystemEntity entity in directory.list(recursive: false)) {
      if (entity is File && entity.path.contains(fileName)) {
        Map<String, String> fileInfo = {
          'id': searchResults.length.toString(),
          'title': entity.path.split(Platform.pathSeparator).last,
          'updateTime': entity.lastModifiedSync().toString(),
          'size':
          '${(entity.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
          'path': entity.path,
          'directoryPath': directory.path, // 添加文件所在的目录路径地址
        };
        searchResults.add(fileInfo);
      } else if (entity is Directory) {
        await _searchFilesRecursive(entity, fileName, searchResults);
      }
    }
  }

  static String _getLastModifiedTime(Directory directory) {
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
}
