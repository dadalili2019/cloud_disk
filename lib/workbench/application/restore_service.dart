import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_paths.dart';
import '../core/workbench_database.dart';
import 'backup_service.dart';

class RestoreValidationResult {
  const RestoreValidationResult({
    required this.createdAt,
    required this.schemaVersion,
    required this.appVersion,
    required this.backupKind,
  });

  final DateTime? createdAt;
  final int schemaVersion;
  final String appVersion;
  final String backupKind;
}

class RestoreStageResult {
  const RestoreStageResult({
    required this.validation,
    required this.safetyBackup,
  });

  final RestoreValidationResult validation;
  final File safetyBackup;
}

class RestoreService {
  RestoreService({
    required this.paths,
    required this.backupService,
  });

  final AppPaths paths;
  final BackupService backupService;

  Directory get _pendingDirectory =>
      Directory(p.join(paths.root.path, '.pending_restore'));

  Future<RestoreValidationResult> validateBackup(File zipFile) async {
    if (!await zipFile.exists()) {
      throw StateError('选择的备份文件不存在。');
    }
    final archive = await _decode(zipFile);
    _validateArchivePaths(archive);
    final manifestFile = _findFile(archive, 'manifest.json');
    final databaseFile = _findFile(archive, 'data/workbench.db');
    if (manifestFile == null || databaseFile == null) {
      throw StateError('这不是有效的 Personal Workbench Backup：缺少 manifest 或数据库快照。');
    }

    final manifestText = utf8.decode(_bytes(manifestFile));
    final decoded = jsonDecode(manifestText);
    if (decoded is! Map) {
      throw StateError('Backup manifest 格式无效。');
    }

    final formatVersion = _asInt(decoded['format_version']);
    if (formatVersion != BackupService.formatVersion) {
      throw StateError(
        '不支持的 Backup format_version：$formatVersion。当前仅支持 ${BackupService.formatVersion}。',
      );
    }

    final schemaVersion = _asInt(decoded['schema_version']);
    if (schemaVersion <= 0) {
      throw StateError('Backup schema_version 无效。');
    }
    if (schemaVersion > WorkbenchDatabase.schemaVersion) {
      throw StateError(
        '该备份来自更新的数据结构（schema v$schemaVersion），当前应用只支持 v${WorkbenchDatabase.schemaVersion}。',
      );
    }

    return RestoreValidationResult(
      createdAt: DateTime.tryParse('${decoded['created_at'] ?? ''}')?.toLocal(),
      schemaVersion: schemaVersion,
      appVersion: '${decoded['app_version'] ?? ''}',
      backupKind: '${decoded['backup_kind'] ?? 'manual'}',
    );
  }

  Future<RestoreStageResult> stageRestore(File zipFile) async {
    final validation = await validateBackup(zipFile);

    // Current data is protected before any pending restore files are staged.
    final safety = await backupService.createSafetyBackup();

    final archive = await _decode(zipFile);
    if (await _pendingDirectory.exists()) {
      await _pendingDirectory.delete(recursive: true);
    }
    await _pendingDirectory.create(recursive: true);

    try {
      for (final entry in archive.files) {
        if (!entry.isFile) continue;
        final normalized = _safeRelative(entry.name);
        if (!_isRestorablePath(normalized)) continue;
        final target = File(p.joinAll([
          _pendingDirectory.path,
          ...p.posix.split(normalized),
        ]));
        await target.parent.create(recursive: true);
        await target.writeAsBytes(_bytes(entry), flush: true);
      }

      final pendingDatabase =
          File(p.join(_pendingDirectory.path, 'data', 'workbench.db'));
      if (!await pendingDatabase.exists()) {
        throw StateError('Restore staging 缺少 workbench.db。');
      }

      await File(p.join(_pendingDirectory.path, 'restore_ready.json'))
          .writeAsString(
        jsonEncode({
          'staged_at': DateTime.now().toUtc().toIso8601String(),
          'source': zipFile.path,
          'safety_backup': safety.file.path,
        }),
        flush: true,
      );

      return RestoreStageResult(
        validation: validation,
        safetyBackup: safety.file,
      );
    } catch (_) {
      if (await _pendingDirectory.exists()) {
        await _pendingDirectory.delete(recursive: true);
      }
      rethrow;
    }
  }

  static Future<bool> applyPendingRestoreIfPresent(AppPaths paths) async {
    final pending = Directory(p.join(paths.root.path, '.pending_restore'));
    final marker = File(p.join(pending.path, 'restore_ready.json'));
    if (!await marker.exists()) return false;

    final pendingDatabase = File(p.join(pending.path, 'data', 'workbench.db'));
    if (!await pendingDatabase.exists()) {
      await pending.delete(recursive: true);
      throw StateError('Pending Restore 无有效数据库快照。');
    }

    await paths.ensureBaseDirectories();

    for (final suffix in ['', '-wal', '-shm']) {
      final current = File('${paths.databasePath}$suffix');
      if (await current.exists()) await current.delete();
    }
    await pendingDatabase.copy(paths.databasePath);

    await _replaceDirectory(
      Directory(p.join(pending.path, 'workspaces')),
      paths.workspacesDirectory,
    );
    await _replaceDirectory(
      Directory(p.join(pending.path, 'knowledge')),
      paths.knowledgeDirectory,
    );
    await _replaceDirectory(
      Directory(p.join(pending.path, 'attachments')),
      paths.attachmentsDirectory,
    );

    final settingsFile =
        File(p.join(pending.path, 'settings', 'settings.json'));
    if (await settingsFile.exists()) {
      await _restorePreferences(settingsFile);
    }

    await pending.delete(recursive: true);
    return true;
  }
}

Future<Archive> _decode(File file) async {
  try {
    final bytes = await file.readAsBytes();
    return ZipDecoder().decodeBytes(bytes, verify: true);
  } catch (error) {
    throw StateError('无法读取 Backup ZIP：$error');
  }
}

void _validateArchivePaths(Archive archive) {
  for (final entry in archive.files) {
    _safeRelative(entry.name);
  }
}

String _safeRelative(String value) {
  final normalized = value.replaceAll('\\', '/');
  if (normalized.startsWith('/') ||
      RegExp(r'^[A-Za-z]:').hasMatch(normalized)) {
    throw StateError('Backup 包含非法绝对路径。');
  }
  final parts = p.posix.split(p.posix.normalize(normalized));
  if (parts.any((part) => part == '..')) {
    throw StateError('Backup 包含非法路径穿越内容。');
  }
  return p.posix.joinAll(parts.where((part) => part != '.'));
}

ArchiveFile? _findFile(Archive archive, String name) {
  for (final file in archive.files) {
    if (file.isFile && _safeRelative(file.name) == name) return file;
  }
  return null;
}

List<int> _bytes(ArchiveFile entry) {
  final content = entry.content;
  if (content is List<int>) return content;
  throw StateError('Backup 文件 ${entry.name} 内容无效。');
}

int _asInt(Object? value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? -1;
}

bool _isRestorablePath(String value) {
  return value == 'manifest.json' ||
      value == 'data/workbench.db' ||
      value == 'settings/settings.json' ||
      value.startsWith('workspaces/') ||
      value.startsWith('knowledge/') ||
      value.startsWith('attachments/');
}

Future<void> _replaceDirectory(Directory source, Directory target) async {
  if (await target.exists()) await target.delete(recursive: true);
  await target.create(recursive: true);
  if (!await source.exists()) return;

  await for (final entity in source.list(recursive: false, followLinks: false)) {
    final destination = p.join(target.path, p.basename(entity.path));
    if (entity is Directory) {
      await _copyDirectory(entity, Directory(destination));
    } else if (entity is File) {
      await entity.copy(destination);
    }
  }
}

Future<void> _copyDirectory(Directory source, Directory target) async {
  await target.create(recursive: true);
  await for (final entity in source.list(recursive: false, followLinks: false)) {
    final destination = p.join(target.path, p.basename(entity.path));
    if (entity is Directory) {
      await _copyDirectory(entity, Directory(destination));
    } else if (entity is File) {
      await entity.copy(destination);
    }
  }
}

Future<void> _restorePreferences(File source) async {
  final decoded = jsonDecode(await source.readAsString());
  if (decoded is! Map) {
    throw StateError('Backup settings.json 格式无效。');
  }

  final preferences = await SharedPreferences.getInstance();
  final removable = preferences
      .getKeys()
      .where((key) => key.startsWith('workbench.') || key.startsWith('theme.'))
      .toList(growable: false);
  for (final key in removable) {
    await preferences.remove(key);
  }

  for (final entry in decoded.entries) {
    final key = '${entry.key}';
    if (!key.startsWith('workbench.') && !key.startsWith('theme.')) continue;
    final lower = key.toLowerCase();
    if (lower.contains('api_key') ||
        lower.contains('apikey') ||
        lower.contains('secret') ||
        lower.contains('token')) {
      continue;
    }
    final value = entry.value;
    if (value is String) {
      await preferences.setString(key, value);
    } else if (value is bool) {
      await preferences.setBool(key, value);
    } else if (value is int) {
      await preferences.setInt(key, value);
    } else if (value is double) {
      await preferences.setDouble(key, value);
    } else if (value is List) {
      final strings = value.map((item) => '$item').toList(growable: false);
      await preferences.setStringList(key, strings);
    }
  }
}
