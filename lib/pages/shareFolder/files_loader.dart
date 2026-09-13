import 'dart:io';

class FilesLoader {
  /// 读取指定目录下的所有文件和文件夹。
  ///
  /// 该接口仍保持同步签名，兼容现有调用方；但尽量减少 SMB/磁盘上的
  /// 同步系统调用次数，避免对每个目录再次 listSync() 造成 N+1 I/O。
  static List<Map<String, String>> loadFilesAndDirectories(
    String sharedFolderPath, {
    String? parentPath,
  }) {
    final sharedDirectory = Directory(sharedFolderPath);
    final filesList = <Map<String, String>>[];

    if (!sharedDirectory.existsSync()) {
      print('Shared directory not found.');
      return filesList;
    }

    try {
      final entities = sharedDirectory.listSync(recursive: false, followLinks: false);

      for (final entity in entities) {
        try {
          final stat = entity.statSync();

          if (entity is File) {
            filesList.add({
              'id': filesList.length.toString(),
              'title': entity.path.split(Platform.pathSeparator).last,
              'updateTime': stat.modified.toString(),
              'size': '${(stat.size / (1024 * 1024)).toStringAsFixed(2)} MB',
              'path': entity.path,
            });
          } else if (entity is Directory) {
            final folderPath = entity.path;
            final path = parentPath != null
                ? '$parentPath${Platform.pathSeparator}$folderPath'
                : folderPath;

            filesList.add({
              'id': filesList.length.toString(),
              'title': entity.path.split(Platform.pathSeparator).last,
              'updateTime': stat.modified.toString(),
              'size': 'Directory',
              'path': path,
            });
          }
        } on FileSystemException {
          // 网络共享目录中单个文件/目录可能瞬时不可访问，跳过即可，
          // 不要因为一个条目失败导致整个目录加载失败。
          continue;
        }
      }
    } on FileSystemException catch (e) {
      print('Failed to list shared directory: $e');
    }

    return filesList;
  }

  /// 读取指定目录下的指定文件。
  static Future<List<Map<String, String>>> searchFiles(
    String directoryPath,
    String fileName,
  ) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      throw Exception('Directory does not exist');
    }

    final searchResults = <Map<String, String>>[];
    await _searchFilesRecursive(directory, fileName, searchResults);
    return searchResults;
  }

  static Future<void> _searchFilesRecursive(
    Directory directory,
    String fileName,
    List<Map<String, String>> searchResults,
  ) async {
    await for (final entity in directory.list(recursive: false, followLinks: false)) {
      if (entity is File && entity.path.contains(fileName)) {
        try {
          final stat = await entity.stat();
          searchResults.add({
            'id': searchResults.length.toString(),
            'title': entity.path.split(Platform.pathSeparator).last,
            'updateTime': stat.modified.toString(),
            'size': '${(stat.size / (1024 * 1024)).toStringAsFixed(2)} MB',
            'path': entity.path,
            'directoryPath': directory.path,
          });
        } on FileSystemException {
          continue;
        }
      } else if (entity is Directory) {
        try {
          await _searchFilesRecursive(entity, fileName, searchResults);
        } on FileSystemException {
          continue;
        }
      }
    }
  }
}
