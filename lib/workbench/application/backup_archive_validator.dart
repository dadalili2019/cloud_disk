import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

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

class BackupArchiveValidator {
  const BackupArchiveValidator();

  Future<RestoreValidationResult> validateFile(File zipFile) async {
    if (!await zipFile.exists()) {
      throw StateError('选择的备份文件不存在。');
    }
    final archive = await decodeFile(zipFile);
    return validateArchive(archive);
  }

  Future<Archive> decodeFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return ZipDecoder().decodeBytes(bytes, verify: true);
    } catch (error) {
      throw StateError('无法读取 Backup ZIP：${error}');
    }
  }

  RestoreValidationResult validateArchive(Archive archive) {
    for (final entry in archive.files) {
      safeRelative(entry.name);
    }

    final manifestFile = findFile(archive, 'manifest.json');
    final databaseFile = findFile(archive, 'data/workbench.db');
    if (manifestFile == null || databaseFile == null) {
      throw StateError(
        '这不是有效的 Personal Workbench Backup：缺少 manifest 或数据库快照。',
      );
    }

    final manifestText = utf8.decode(bytes(manifestFile));
    final decoded = jsonDecode(manifestText);
    if (decoded is! Map) {
      throw StateError('Backup manifest 格式无效。');
    }

    final formatVersion = asInt(decoded['format_version']);
    if (formatVersion != BackupService.formatVersion) {
      throw StateError(
        '不支持的 Backup format_version：$formatVersion。'
        '当前仅支持 ${BackupService.formatVersion}。',
      );
    }

    final schemaVersion = asInt(decoded['schema_version']);
    if (schemaVersion <= 0) {
      throw StateError('Backup schema_version 无效。');
    }
    if (schemaVersion > WorkbenchDatabase.schemaVersion) {
      throw StateError(
        '该备份来自更新的数据结构（schema v$schemaVersion），'
        '当前应用只支持 v${WorkbenchDatabase.schemaVersion}。',
      );
    }

    return RestoreValidationResult(
      createdAt: DateTime.tryParse('${decoded['created_at'] ?? ''}')?.toLocal(),
      schemaVersion: schemaVersion,
      appVersion: '${decoded['app_version'] ?? ''}',
      backupKind: '${decoded['backup_kind'] ?? 'manual'}',
    );
  }

  String safeRelative(String value) {
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

  ArchiveFile? findFile(Archive archive, String name) {
    for (final file in archive.files) {
      if (file.isFile && safeRelative(file.name) == name) {
        return file;
      }
    }
    return null;
  }

  List<int> bytes(ArchiveFile entry) {
    final content = entry.content;
    if (content is List<int>) return content;
    throw StateError('Backup 文件 ${entry.name} 内容无效。');
  }

  int asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? -1;
  }

  bool isRestorablePath(String value) {
    return value == 'manifest.json' ||
        value == 'data/workbench.db' ||
        value == 'settings/settings.json' ||
        value.startsWith('workspaces/') ||
        value.startsWith('knowledge/') ||
        value.startsWith('attachments/');
  }
}
