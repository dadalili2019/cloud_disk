import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:cloud_disk/workbench/application/backup_service.dart';
import 'package:cloud_disk/workbench/application/restore_service.dart';
import 'package:cloud_disk/workbench/core/app_paths.dart';
import 'package:cloud_disk/workbench/core/workbench_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('RestoreService staging and apply', () {
    late Directory tempDirectory;
    late AppPaths paths;
    late BackupService backupService;
    late RestoreService restoreService;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'personal_workbench_restore_',
      );
      paths = await AppPaths.createAt(
        Directory(p.join(tempDirectory.path, 'app')),
      );
      SharedPreferences.setMockInitialValues({
        'workbench.old_setting': 'old',
        'theme.mode': 'dark',
        'other.app.setting': 'keep',
      });
      backupService = BackupService(
        paths: paths,
        database: _SnapshotSqlExecutor(),
      );
      restoreService = RestoreService(
        paths: paths,
        backupService: backupService,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('stage creates safety backup and sanitized pending restore', () async {
      final source = await _createRestoreZip(tempDirectory);

      final result = await restoreService.stageRestore(source);

      expect(await result.safetyBackup.exists(), isTrue);
      expect(
        p.basename(result.safetyBackup.path),
        startsWith('PersonalWorkbench_SafetyBackup_'),
      );

      final pending = Directory(
        p.join(paths.root.path, '.pending_restore'),
      );
      expect(await pending.exists(), isTrue);
      expect(
        await File(p.join(pending.path, 'data', 'workbench.db')).readAsString(),
        'restored-db',
      );
      expect(
        await File(
          p.join(
            pending.path,
            'workspaces',
            'alpha',
            'notes',
            'restored.md',
          ),
        ).readAsString(),
        '# Restored note',
      );
      expect(
        await File(p.join(pending.path, 'exports', 'ignored.txt')).exists(),
        isFalse,
      );

      final settings = jsonDecode(
        await File(
          p.join(pending.path, 'settings', 'settings.json'),
        ).readAsString(),
      ) as Map<String, dynamic>;
      expect(settings['workbench.general.compact_mode'], isFalse);
      expect(settings['theme.mode'], 'light');
      expect(settings, isNot(contains('workbench.ai.api_key')));
      expect(settings, isNot(contains('workbench.secret')));

      final marker = jsonDecode(
        await File(
          p.join(pending.path, 'restore_ready.json'),
        ).readAsString(),
      ) as Map<String, dynamic>;
      expect(marker['source'], source.path);
      expect(marker['safety_backup'], result.safetyBackup.path);
    });

    test('next-start apply replaces data and portable settings', () async {
      await File(paths.databasePath).writeAsString('current-db');
      await File('${paths.databasePath}-wal').writeAsString('wal');
      await File('${paths.databasePath}-shm').writeAsString('shm');

      final oldNote = File(
        p.join(
          paths.workspacesDirectory.path,
          'legacy',
          'notes',
          'old.md',
        ),
      );
      await oldNote.parent.create(recursive: true);
      await oldNote.writeAsString('# Old');

      final source = await _createRestoreZip(tempDirectory);
      await restoreService.stageRestore(source);

      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('workbench.old_setting', 'changed-after-stage');
      await preferences.setString('theme.mode', 'changed-after-stage');

      final applied = await RestoreService.applyPendingRestoreIfPresent(paths);

      expect(applied, isTrue);
      expect(await File(paths.databasePath).readAsString(), 'restored-db');
      expect(await File('${paths.databasePath}-wal').exists(), isFalse);
      expect(await File('${paths.databasePath}-shm').exists(), isFalse);
      expect(await oldNote.exists(), isFalse);
      expect(
        await File(
          p.join(
            paths.workspacesDirectory.path,
            'alpha',
            'notes',
            'restored.md',
          ),
        ).readAsString(),
        '# Restored note',
      );
      expect(
        await File(
          p.join(paths.knowledgeDirectory.path, 'restored.md'),
        ).readAsString(),
        '# Restored knowledge',
      );
      expect(
        await File(
          p.join(paths.attachmentsDirectory.path, 'restored.txt'),
        ).readAsString(),
        'restored attachment',
      );

      final restoredPreferences = await SharedPreferences.getInstance();
      expect(
        restoredPreferences.getBool('workbench.general.compact_mode'),
        isFalse,
      );
      expect(restoredPreferences.getString('theme.mode'), 'light');
      expect(restoredPreferences.containsKey('workbench.old_setting'), isFalse);
      expect(restoredPreferences.containsKey('workbench.ai.api_key'), isFalse);
      expect(restoredPreferences.getString('other.app.setting'), 'keep');

      expect(
        await Directory(
          p.join(paths.root.path, '.pending_restore'),
        ).exists(),
        isFalse,
      );
      expect(
        await RestoreService.applyPendingRestoreIfPresent(paths),
        isFalse,
      );
    });

    test('stage rejects malformed settings and removes pending data', () async {
      final source = await _createRestoreZip(
        tempDirectory,
        malformedSettings: true,
      );

      await expectLater(
        restoreService.stageRestore(source),
        throwsA(
          isA<FormatException>(),
        ),
      );

      expect(
        await Directory(
          p.join(paths.root.path, '.pending_restore'),
        ).exists(),
        isFalse,
      );
    });

    test('apply preflight failure keeps current data untouched', () async {
      await File(paths.databasePath).writeAsString('current-db');

      final pending = Directory(
        p.join(paths.root.path, '.pending_restore'),
      );
      await File(
        p.join(pending.path, 'restore_ready.json'),
      ).create(recursive: true);
      await File(
        p.join(pending.path, 'data', 'workbench.db'),
      )
        ..createSync(recursive: true)
        ..writeAsStringSync('pending-db');
      await File(
        p.join(pending.path, 'settings', 'settings.json'),
      )
        ..createSync(recursive: true)
        ..writeAsStringSync('{broken json');

      await expectLater(
        RestoreService.applyPendingRestoreIfPresent(paths),
        throwsA(isA<FormatException>()),
      );

      expect(await File(paths.databasePath).readAsString(), 'current-db');
      expect(await pending.exists(), isFalse);
    });

    test('apply removes invalid pending restore without database', () async {
      await File(paths.databasePath).writeAsString('current-db');

      final pending = Directory(
        p.join(paths.root.path, '.pending_restore'),
      );
      await File(
        p.join(pending.path, 'restore_ready.json'),
      ).create(recursive: true);

      await expectLater(
        RestoreService.applyPendingRestoreIfPresent(paths),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('无有效数据库快照'),
          ),
        ),
      );

      expect(await File(paths.databasePath).readAsString(), 'current-db');
      expect(await pending.exists(), isFalse);
    });
  });
}

Future<File> _createRestoreZip(
  Directory root, {
  bool malformedSettings = false,
}) async {
  final staging = Directory(
    p.join(
      root.path,
      malformedSettings ? 'source_bad_settings' : 'source_valid',
    ),
  );
  if (await staging.exists()) {
    await staging.delete(recursive: true);
  }
  await staging.create(recursive: true);

  Future<void> write(String relative, String content) async {
    final file = File(
      p.joinAll([staging.path, ...p.posix.split(relative)]),
    );
    await file.parent.create(recursive: true);
    await file.writeAsString(content, flush: true);
  }

  await write('data/workbench.db', 'restored-db');
  await write(
    'workspaces/alpha/notes/restored.md',
    '# Restored note',
  );
  await write('knowledge/restored.md', '# Restored knowledge');
  await write('attachments/restored.txt', 'restored attachment');
  await write('exports/ignored.txt', 'must not be staged');
  await write(
    'settings/settings.json',
    malformedSettings
        ? '{broken json'
        : jsonEncode({
            'workbench.general.compact_mode': false,
            'theme.mode': 'light',
            'workbench.ai.api_key': 'must-not-restore',
            'workbench.secret': 'must-not-restore',
            'other.app.setting': 'ignore-me',
          }),
  );

  final manifest = {
    'format_version': BackupService.formatVersion,
    'backup_kind': 'manual',
    'app_version': BackupService.appVersion,
    'schema_version': WorkbenchDatabase.schemaVersion,
    'created_at': '2026-09-21T09:00:00.000Z',
    'platform': Platform.operatingSystem,
    'included_paths': [
      'data/workbench.db',
      'workspaces/alpha/notes/restored.md',
      'knowledge/restored.md',
      'attachments/restored.txt',
      'settings/settings.json',
    ],
  };
  await write('manifest.json', jsonEncode(manifest));

  final output = File(
    p.join(
      root.path,
      malformedSettings ? 'restore_bad_settings.zip' : 'restore_valid.zip',
    ),
  );
  if (await output.exists()) await output.delete();

  final encoder = ZipFileEncoder();
  encoder.create(output.path);
  await for (final entity in staging.list(recursive: true)) {
    if (entity is! File) continue;
    final relative = p
        .relative(entity.path, from: staging.path)
        .replaceAll('\\', '/');
    encoder.addFile(entity, relative);
  }
  encoder.close();
  return output;
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
