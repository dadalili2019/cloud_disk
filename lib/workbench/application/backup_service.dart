import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_paths.dart';
import '../core/workbench_database.dart';

class BackupResult {
  const BackupResult({
    required this.file,
    required this.createdAt,
    required this.includedFiles,
  });

  final File file;
  final DateTime createdAt;
  final int includedFiles;
}

class BackupService {
  BackupService({
    required this.paths,
    required this.database,
  });

  final AppPaths paths;
  final WorkbenchSqlExecutor database;

  static const int formatVersion = 1;
  static const String appVersion = '1.0.0+1';

  Future<BackupResult> createManualBackup() =>
      _createBackup(kind: 'manual');

  Future<BackupResult> createSafetyBackup() =>
      _createBackup(kind: 'safety');

  Future<BackupResult> createAutoBackup() =>
      _createBackup(kind: 'auto');

  Future<List<FileSystemEntity>> listBackups() async {
    await paths.backupsDirectory.create(recursive: true);
    final items = await paths.backupsDirectory
        .list()
        .where((entity) =>
            entity is File && entity.path.toLowerCase().endsWith('.zip'))
        .toList();
    items.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return items;
  }

  Future<void> pruneAutoBackups({int keep = 10}) async {
    if (keep < 1) return;
    final files = await paths.backupsDirectory
        .list()
        .where((entity) =>
            entity is File &&
            p.basename(entity.path).startsWith('PersonalWorkbench_AutoBackup_') &&
            entity.path.toLowerCase().endsWith('.zip'))
        .cast<File>()
        .toList();
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    for (final file in files.skip(keep)) {
      if (await file.exists()) await file.delete();
    }
  }

  Future<BackupResult> _createBackup({required String kind}) async {
    await paths.ensureBaseDirectories();
    final createdAt = DateTime.now();
    final stamp = _timestamp(createdAt);
    final label = switch (kind) {
      'auto' => 'AutoBackup',
      'safety' => 'SafetyBackup',
      _ => 'Backup',
    };
    final output = File(
      p.join(paths.backupsDirectory.path, 'PersonalWorkbench_${label}_$stamp.zip'),
    );
    final staging = Directory(
      p.join(paths.backupsDirectory.path, '.staging_${kind}_$stamp'),
    );

    if (await staging.exists()) await staging.delete(recursive: true);
    await staging.create(recursive: true);

    try {
      final dataDir = Directory(p.join(staging.path, 'data'));
      final settingsDir = Directory(p.join(staging.path, 'settings'));
      await dataDir.create(recursive: true);
      await settingsDir.create(recursive: true);

      final snapshot = File(p.join(dataDir.path, 'workbench.db'));
      await _createDatabaseSnapshot(snapshot);

      await _copyDirectoryIfExists(
        paths.workspacesDirectory,
        Directory(p.join(staging.path, 'workspaces')),
      );
      await _copyDirectoryIfExists(
        paths.knowledgeDirectory,
        Directory(p.join(staging.path, 'knowledge')),
      );
      await _copyDirectoryIfExists(
        paths.attachmentsDirectory,
        Directory(p.join(staging.path, 'attachments')),
      );

      final preferences = await _portablePreferences();
      await File(p.join(settingsDir.path, 'settings.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert(preferences),
        flush: true,
      );

      final includedPaths = await _relativeFiles(staging);
      final manifest = <String, Object?>{
        'format_version': formatVersion,
        'backup_kind': kind,
        'app_version': appVersion,
        'schema_version': WorkbenchDatabase.schemaVersion,
        'created_at': createdAt.toUtc().toIso8601String(),
        'platform': Platform.operatingSystem,
        'included_paths': includedPaths,
      };
      await File(p.join(staging.path, 'manifest.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert(manifest),
        flush: true,
      );

      final finalFiles = await _relativeFiles(staging);
      await _zipDirectory(staging, output);

      return BackupResult(
        file: output,
        createdAt: createdAt,
        includedFiles: finalFiles.length,
      );
    } finally {
      if (await staging.exists()) {
        await staging.delete(recursive: true);
      }
    }
  }

  Future<void> _createDatabaseSnapshot(File target) async {
    if (await target.exists()) await target.delete();
    final escaped = target.path.replaceAll("'", "''");
    await database.custom("VACUUM INTO '$escaped'");
    if (!await target.exists()) {
      throw StateError('Database snapshot was not created.');
    }
  }

  Future<Map<String, Object?>> _portablePreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final result = <String, Object?>{};
    for (final key in preferences.getKeys()) {
      if (!key.startsWith('workbench.') && !key.startsWith('theme.')) {
        continue;
      }
      final lower = key.toLowerCase();
      if (lower.contains('api_key') ||
          lower.contains('apikey') ||
          lower.contains('secret') ||
          lower.contains('token')) {
        continue;
      }
      final value = preferences.get(key);
      if (value is String ||
          value is bool ||
          value is int ||
          value is double ||
          value is List<String>) {
        result[key] = value;
      }
    }
    return result;
  }
}

Future<void> _copyDirectoryIfExists(Directory source, Directory target) async {
  if (!await source.exists()) return;
  await target.create(recursive: true);
  await for (final entity in source.list(recursive: false, followLinks: false)) {
    final name = p.basename(entity.path);
    final destinationPath = p.join(target.path, name);
    if (entity is Directory) {
      await _copyDirectoryIfExists(entity, Directory(destinationPath));
    } else if (entity is File) {
      await File(destinationPath).parent.create(recursive: true);
      await entity.copy(destinationPath);
    }
  }
}

Future<List<String>> _relativeFiles(Directory root) async {
  final result = <String>[];
  if (!await root.exists()) return result;
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    result.add(p.relative(entity.path, from: root.path).replaceAll('\\', '/'));
  }
  result.sort();
  return result;
}

Future<void> _zipDirectory(Directory source, File output) async {
  if (await output.exists()) await output.delete();
  await output.parent.create(recursive: true);
  final encoder = ZipFileEncoder();
  encoder.create(output.path);
  await for (final entity in source.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final relative = p.relative(entity.path, from: source.path).replaceAll('\\', '/');
    encoder.addFile(entity, relative);
  }
  encoder.close();
}

String _timestamp(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}${two(value.month)}${two(value.day)}_${two(value.hour)}${two(value.minute)}${two(value.second)}';
}
