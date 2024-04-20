import 'dart:io';

/// 读取指定目录下的所有文件和文件夹
class FilesLoader {
  static List<Map<String, String>> loadFilesAndDirectories(
      String sharedFolderPath,
      {String? parentPath}) {
    var sharedDirectory = Directory(sharedFolderPath);
    List<Map<String, String>> filesList = [];

    if (sharedDirectory.existsSync()) {
      var files = sharedDirectory.listSync(recursive: true);

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
          // 递归调用，遍历子文件夹，并传递父目录路径
          filesList
              .addAll(loadFilesAndDirectories(entity.path, parentPath: path));
        }
      }
    } else {
      print('Shared directory not found.');
    }

    return filesList;
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
