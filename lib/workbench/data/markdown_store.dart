import 'dart:io';

import '../core/app_paths.dart';

class MarkdownStore {
  const MarkdownStore(this.paths);

  final AppPaths paths;

  Future<bool> exists(String relativePath) {
    return File(paths.resolveRelative(relativePath)).exists();
  }

  Future<String> read(String relativePath) async {
    final file = File(paths.resolveRelative(relativePath));
    if (!await file.exists()) return '';
    return file.readAsString();
  }

  Future<void> writeAtomic(String relativePath, String content) async {
    final target = File(paths.resolveRelative(relativePath));
    await target.parent.create(recursive: true);

    final temp = File('${target.path}.tmp');
    final backup = File('${target.path}.bak');

    if (await temp.exists()) await temp.delete();
    if (await backup.exists()) await backup.delete();

    final handle = await temp.open(mode: FileMode.write);
    try {
      await handle.writeString(content);
      await handle.flush();
    } finally {
      await handle.close();
    }

    var movedOriginal = false;
    try {
      if (await target.exists()) {
        await target.rename(backup.path);
        movedOriginal = true;
      }

      await temp.rename(target.path);

      if (movedOriginal && await backup.exists()) {
        await backup.delete();
      }
    } catch (_) {
      if (await temp.exists()) {
        await temp.delete();
      }
      if (movedOriginal && !await target.exists() && await backup.exists()) {
        await backup.rename(target.path);
      }
      rethrow;
    }
  }

  Future<void> deleteIfExists(String relativePath) async {
    final file = File(paths.resolveRelative(relativePath));
    if (await file.exists()) await file.delete();
  }
}
