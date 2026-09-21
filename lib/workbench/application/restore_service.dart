import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_paths.dart';
import 'backup_archive_validator.dart';
import 'backup_service.dart';

export 'backup_archive_validator.dart' show RestoreValidationResult;

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
    this.validator = const BackupArchiveValidator(),
  });

  final AppPaths paths;
  final BackupService backupService;
  final BackupArchiveValidator validator;

  Directory get _pendingDirectory =>
      Directory(p.join(paths.root.path, '.pending_restore'));

  Future<RestoreValidationResult> validateBackup(File zipFile) {
    return validator.validateFile(zipFile);
  }

  Future<RestoreStageResult> stageRestore(File zipFile) async {
    final validation = await validateBackup(zipFile);

    // Current data is protected before any pending restore files are staged.
    final safety = await backupService.createSafetyBackup();

    final archive = await validator.decodeFile(zipFile);
    if (await _pendingDirectory.exists()) {
      await _pendingDirectory.delete(recursive: true);
    }
    await _pendingDirectory.create(recursive: true);

    try {
      for (final entry in archive.files) {
        if (!entry.isFile) continue;
        final normalized = validator.safeRelative(entry.name);
        if (!validator.isRestorablePath(normalized)) continue;
        final target = File(p.joinAll([
          _pendingDirectory.path,
          ...p.posix.split(normalized),
        ]));
        await target.parent.create(recursive: true);
        await target.writeAsBytes(validator.bytes(entry), flush: true);
      }

      final pendingDatabase =
          File(p.join(_pendingDirectory.path, 'data', 'workbench.db'));
      if (!await pendingDatabase.exists()) {
        throw StateError('Restore staging 缺少 workbench.db。');
      }

      final pendingSettings =
          File(p.join(_pendingDirectory.path, 'settings', 'settings.json'));
      if (await pendingSettings.exists()) {
        final portableSettings = await _readPortablePreferences(pendingSettings);
        await pendingSettings.writeAsString(
          jsonEncode(portableSettings),
          flush: true,
        );
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

    final settingsFile =
        File(p.join(pending.path, 'settings', 'settings.json'));
    Map<String, Object?>? portableSettings;
    if (await settingsFile.exists()) {
      try {
        portableSettings = await _readPortablePreferences(settingsFile);
      } catch (_) {
        await pending.delete(recursive: true);
        rethrow;
      }
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

    if (portableSettings != null) {
      await _applyPortablePreferences(portableSettings);
    }

    await pending.delete(recursive: true);
    return true;
  }
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

Future<Map<String, Object?>> _readPortablePreferences(File source) async {
  final decoded = jsonDecode(await source.readAsString());
  if (decoded is! Map) {
    throw StateError('Backup settings.json 格式无效。');
  }

  final result = <String, Object?>{};
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
    if (value is String ||
        value is bool ||
        value is int ||
        value is double) {
      result[key] = value;
    } else if (value is List) {
      result[key] = value.map((item) => '$item').toList(growable: false);
    }
  }
  return result;
}

Future<void> _applyPortablePreferences(
  Map<String, Object?> values,
) async {
  final preferences = await SharedPreferences.getInstance();
  final removable = preferences
      .getKeys()
      .where((key) => key.startsWith('workbench.') || key.startsWith('theme.'))
      .toList(growable: false);
  for (final key in removable) {
    await preferences.remove(key);
  }

  for (final entry in values.entries) {
    final key = entry.key;
    final value = entry.value;
    if (value is String) {
      await preferences.setString(key, value);
    } else if (value is bool) {
      await preferences.setBool(key, value);
    } else if (value is int) {
      await preferences.setInt(key, value);
    } else if (value is double) {
      await preferences.setDouble(key, value);
    } else if (value is List<String>) {
      await preferences.setStringList(key, value);
    }
  }
}
