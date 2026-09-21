import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:cloud_disk/workbench/application/backup_service.dart';
import 'package:cloud_disk/workbench/core/app_paths.dart';
import 'package:cloud_disk/workbench/core/workbench_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('BackupService', () {
    late Directory tempDirectory;
    late AppPaths paths;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'personal_workbench_backup_',
      );
      paths = await AppPaths.createAt(
        Directory(p.join(tempDirectory.path, 'root')),
      );
      SharedPreferences.setMockInitialValues({
        'workbench.general.compact_mode': true,
        'workbench.notes.font_size': 14,
        'theme.mode': 'dark',
        'workbench.ai.api_key': 'must-not-leak',
        'workbench.secret': 'must-not-leak',
        'workbench.token': 'must-not-leak',
        'other.app.setting': 'ignore-me',
      });

      final note = File(
        p.join(
          paths.workspacesDirectory.path,
          'alpha',
          'notes',
          'note.md',
        ),
      );
      await note.parent.create(recursive: true);
      await note.writeAsString('# Note');

      final knowledge = File(
        p.join(paths.knowledgeDirectory.path, 'knowledge.md'),
      );
      await knowledge.writeAsString('# Knowledge');

      final attachment = File(
        p.join(paths.attachmentsDirectory.path, 'sample.txt'),
      );
      await attachment.writeAsString('attachment');
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('backup contains manifest, data and portable settings only', () async {
      final service = BackupService(
        paths: paths,
        database: _SnapshotSqlExecutor(),
      );

      final result = await service.createManualBackup();

      expect(await result.file.exists(), isTrue);

      final archive = ZipDecoder().decodeBytes(
        await result.file.readAsBytes(),
        verify: true,
      );
      final files = {
        for (final entry in archive.files)
          if (entry.isFile) entry.name: entry,
      };

      expect(files, contains('manifest.json'));
      expect(files, contains('data/workbench.db'));
      expect(files, contains('settings/settings.json'));
      expect(files, contains('workspaces/alpha/notes/note.md'));
      expect(files, contains('knowledge/knowledge.md'));
      expect(files, contains('attachments/sample.txt'));

      final manifest = jsonDecode(
        utf8.decode(_bytes(files['manifest.json']!)),
      ) as Map<String, dynamic>;
      expect(manifest['format_version'], BackupService.formatVersion);
      expect(manifest['backup_kind'], 'manual');
      expect(manifest['app_version'], BackupService.appVersion);
      expect(
        manifest['schema_version'],
        WorkbenchDatabase.schemaVersion,
      );
      expect(
        manifest['included_paths'],
        containsAll([
          'data/workbench.db',
          'settings/settings.json',
          'workspaces/alpha/notes/note.md',
          'knowledge/knowledge.md',
          'attachments/sample.txt',
        ]),
      );

      final settings = jsonDecode(
        utf8.decode(_bytes(files['settings/settings.json']!)),
      ) as Map<String, dynamic>;
      expect(settings['workbench.general.compact_mode'], isTrue);
      expect(settings['workbench.notes.font_size'], 14);
      expect(settings['theme.mode'], 'dark');
      expect(settings, isNot(contains('workbench.ai.api_key')));
      expect(settings, isNot(contains('workbench.secret')));
      expect(settings, isNot(contains('workbench.token')));
      expect(settings, isNot(contains('other.app.setting')));
    });


    test('falls back to a locked file snapshot when VACUUM INTO is unsupported',
        () async {
      final source = File(paths.databasePath);
      await source.parent.create(recursive: true);
      await source.writeAsBytes([9, 8, 7, 6], flush: true);

      final executor = _LegacySnapshotSqlExecutor(journalMode: 'delete');
      final service = BackupService(
        paths: paths,
        database: executor,
      );

      final result = await service.createManualBackup();

      expect(await result.file.exists(), isTrue);
      expect(executor.beginImmediateCount, 1);
      expect(executor.rollbackCount, 1);

      final archive = ZipDecoder().decodeBytes(
        await result.file.readAsBytes(),
        verify: true,
      );
      final databaseEntry = archive.files.singleWhere(
        (entry) => entry.name == 'data/workbench.db',
      );
      expect(_bytes(databaseEntry), [9, 8, 7, 6]);
    });

    test('does not use unsafe file-copy fallback for WAL databases', () async {
      final source = File(paths.databasePath);
      await source.parent.create(recursive: true);
      await source.writeAsBytes([1, 2, 3], flush: true);

      final service = BackupService(
        paths: paths,
        database: _LegacySnapshotSqlExecutor(journalMode: 'wal'),
      );

      await expectLater(
        service.createManualBackup(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Refusing an unsafe file-copy snapshot'),
          ),
        ),
      );
    });
  });
}

List<int> _bytes(ArchiveFile file) {
  final content = file.content;
  if (content is List<int>) return content;
  throw StateError('Archive entry ${file.name} has invalid content.');
}

class _SnapshotSqlExecutor implements WorkbenchSqlExecutor {
  @override
  Future<void> custom(
    String statement, [
    List<Object?> args = const [],
  ]) async {
    final match = RegExp(r"VACUUM INTO '(.*)'").firstMatch(statement);
    if (match == null) {
      throw StateError('Unexpected SQL: $statement');
    }
    final path = match.group(1)!.replaceAll("''", "'");
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes([1, 2, 3, 4], flush: true);
  }

  @override
  Future<int> delete(
    String statement, [
    List<Object?> args = const [],
  ]) => throw UnimplementedError();

  @override
  Future<int> insert(
    String statement, [
    List<Object?> args = const [],
  ]) => throw UnimplementedError();

  @override
  Future<List<Map<String, Object?>>> select(
    String statement, [
    List<Object?> args = const [],
  ]) => throw UnimplementedError();

  @override
  Future<int> update(
    String statement, [
    List<Object?> args = const [],
  ]) => throw UnimplementedError();
}


class _LegacySnapshotSqlExecutor implements WorkbenchSqlExecutor {
  _LegacySnapshotSqlExecutor({required this.journalMode});

  final String journalMode;
  int beginImmediateCount = 0;
  int rollbackCount = 0;

  @override
  Future<void> custom(
    String statement, [
    List<Object?> args = const [],
  ]) async {
    if (statement.startsWith('VACUUM INTO')) {
      throw StateError('near "INTO": syntax error');
    }
    if (statement == 'BEGIN IMMEDIATE') {
      beginImmediateCount += 1;
      return;
    }
    if (statement == 'ROLLBACK') {
      rollbackCount += 1;
      return;
    }
    throw StateError('Unexpected SQL: $statement');
  }

  @override
  Future<List<Map<String, Object?>>> select(
    String statement, [
    List<Object?> args = const [],
  ]) async {
    if (statement == 'PRAGMA journal_mode') {
      return [
        {'journal_mode': journalMode},
      ];
    }
    throw StateError('Unexpected SQL: $statement');
  }

  @override
  Future<int> delete(
    String statement, [
    List<Object?> args = const [],
  ]) => throw UnimplementedError();

  @override
  Future<int> insert(
    String statement, [
    List<Object?> args = const [],
  ]) => throw UnimplementedError();

  @override
  Future<int> update(
    String statement, [
    List<Object?> args = const [],
  ]) => throw UnimplementedError();
}
