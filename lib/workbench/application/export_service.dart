import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import '../core/app_paths.dart';
import '../core/workbench_database.dart';

class ExportResult {
  const ExportResult({
    required this.file,
    required this.createdAt,
    required this.includedFiles,
  });

  final File file;
  final DateTime createdAt;
  final int includedFiles;
}

class ExportService {
  ExportService({
    required this.paths,
    required this.database,
  });

  final AppPaths paths;
  final WorkbenchDatabase database;

  static const int formatVersion = 1;
  static const String appVersion = '1.0.0+1';

  String suggestedFileName([DateTime? now]) {
    final createdAt = now ?? DateTime.now();
    return 'PersonalWorkbench_Export_${_timestamp(createdAt)}.zip';
  }

  Future<ExportResult> exportAll({
    bool includeAttachments = true,
    String? destinationPath,
  }) async {
    await paths.ensureBaseDirectories();
    final createdAt = DateTime.now();
    final stamp = _timestamp(createdAt);
    final normalizedDestination = destinationPath?.trim();
    final output = File(
      normalizedDestination == null || normalizedDestination.isEmpty
          ? p.join(paths.exportsDirectory.path, suggestedFileName(createdAt))
          : _ensureZipExtension(normalizedDestination),
    );
    final staging = Directory(
      p.join(paths.exportsDirectory.path, '.staging_export_$stamp'),
    );

    if (await staging.exists()) await staging.delete(recursive: true);
    await staging.create(recursive: true);

    try {
      final metadataDir = Directory(p.join(staging.path, 'metadata'));
      await metadataDir.create(recursive: true);

      final tables = <String>[
        'workspaces',
        'tasks',
        'notes',
        'issues',
        'resources',
        'decisions',
        'knowledge',
        'focus_sessions',
        'entity_links',
        'activity_events',
        'ai_threads',
        'ai_messages',
        'developer_projects',
        'developer_commands',
        'developer_snippets',
      ];

      final counts = <String, int>{};
      for (final table in tables) {
        final rows = await database.select('SELECT * FROM $table');
        counts[table] = rows.length;
        await File(p.join(metadataDir.path, '$table.json')).writeAsString(
          const JsonEncoder.withIndent('  ').convert(rows),
          flush: true,
        );
      }

      await _copyWorkspaceContent(
        sourceRoot: paths.workspacesDirectory,
        targetRoot: Directory(p.join(staging.path, 'workspaces')),
        includeAttachments: includeAttachments,
      );
      await _copyDirectoryIfExists(
        paths.knowledgeDirectory,
        Directory(p.join(staging.path, 'knowledge')),
      );
      if (includeAttachments) {
        await _copyDirectoryIfExists(
          paths.attachmentsDirectory,
          Directory(p.join(staging.path, 'attachments')),
        );
      }

      final manifest = <String, Object?>{
        'format_version': formatVersion,
        'export_type': 'portable',
        'app_version': appVersion,
        'schema_version': WorkbenchDatabase.schemaVersion,
        'created_at': createdAt.toUtc().toIso8601String(),
        'platform': Platform.operatingSystem,
        'include_attachments': includeAttachments,
        'record_counts': counts,
        'restore_supported': false,
      };
      await File(p.join(staging.path, 'export_manifest.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert(manifest),
        flush: true,
      );

      final includedFiles = await _fileCount(staging);
      await _zipDirectory(staging, output);
      return ExportResult(
        file: output,
        createdAt: createdAt,
        includedFiles: includedFiles,
      );
    } finally {
      if (await staging.exists()) {
        await staging.delete(recursive: true);
      }
    }
  }
}

Future<void> _copyWorkspaceContent({
  required Directory sourceRoot,
  required Directory targetRoot,
  required bool includeAttachments,
}) async {
  if (!await sourceRoot.exists()) return;
  await targetRoot.create(recursive: true);

  await for (final workspace in sourceRoot.list(followLinks: false)) {
    if (workspace is! Directory) continue;
    final workspaceName = p.basename(workspace.path);
    final targetWorkspace = Directory(p.join(targetRoot.path, workspaceName));

    final notes = Directory(p.join(workspace.path, 'notes'));
    await _copyDirectoryIfExists(
      notes,
      Directory(p.join(targetWorkspace.path, 'notes')),
    );

    if (includeAttachments) {
      final attachments = Directory(p.join(workspace.path, 'attachments'));
      await _copyDirectoryIfExists(
        attachments,
        Directory(p.join(targetWorkspace.path, 'attachments')),
      );
    }
  }
}

Future<void> _copyDirectoryIfExists(Directory source, Directory target) async {
  if (!await source.exists()) return;
  await target.create(recursive: true);
  await for (final entity in source.list(recursive: false, followLinks: false)) {
    final destinationPath = p.join(target.path, p.basename(entity.path));
    if (entity is Directory) {
      await _copyDirectoryIfExists(entity, Directory(destinationPath));
    } else if (entity is File) {
      await entity.copy(destinationPath);
    }
  }
}

Future<int> _fileCount(Directory root) async {
  var count = 0;
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is File) count++;
  }
  return count;
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

String _ensureZipExtension(String value) {
  return value.toLowerCase().endsWith('.zip') ? value : '$value.zip';
}

String _timestamp(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}${two(value.month)}${two(value.day)}_${two(value.hour)}${two(value.minute)}${two(value.second)}';
}
