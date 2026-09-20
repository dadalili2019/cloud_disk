import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:cloud_disk/workbench/application/backup_archive_validator.dart';
import 'package:cloud_disk/workbench/application/backup_service.dart';
import 'package:cloud_disk/workbench/core/workbench_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = BackupArchiveValidator();

  group('BackupArchiveValidator', () {
    test('accepts compatible Personal Workbench backup manifest', () {
      final archive = _validArchive();

      final result = validator.validateArchive(archive);

      expect(result.schemaVersion, WorkbenchDatabase.schemaVersion);
      expect(result.appVersion, '1.0.0+1');
      expect(result.backupKind, 'manual');
      expect(result.createdAt, isNotNull);
    });

    test('rejects archive path traversal', () {
      final archive = _validArchive();
      archive.addFile(ArchiveFile('../escape.txt', 3, [1, 2, 3]));

      expect(
        () => validator.validateArchive(archive),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('路径穿越'),
          ),
        ),
      );
    });

    test('rejects absolute archive paths', () {
      final archive = _validArchive();
      archive.addFile(ArchiveFile('C:/escape.txt', 3, [1, 2, 3]));

      expect(
        () => validator.validateArchive(archive),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('绝对路径'),
          ),
        ),
      );
    });

    test('rejects missing manifest or database snapshot', () {
      final archive = Archive()
        ..addFile(ArchiveFile('manifest.json', 2, utf8.encode('{}')));

      expect(
        () => validator.validateArchive(archive),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('缺少 manifest 或数据库快照'),
          ),
        ),
      );
    });

    test('rejects unsupported backup format version', () {
      final archive = _validArchive(
        formatVersion: BackupService.formatVersion + 1,
      );

      expect(
        () => validator.validateArchive(archive),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('format_version'),
          ),
        ),
      );
    });

    test('rejects backup from newer database schema', () {
      final archive = _validArchive(
        schemaVersion: WorkbenchDatabase.schemaVersion + 1,
      );

      expect(
        () => validator.validateArchive(archive),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('来自更新的数据结构'),
          ),
        ),
      );
    });

    test('rejects corrupted zip file', () async {
      final directory = await Directory.systemTemp.createTemp(
        'workbench_restore_validator_',
      );
      final file = File(
        '${directory.path}${Platform.pathSeparator}bad.zip',
      );

      try {
        await file.writeAsBytes([1, 2, 3, 4, 5], flush: true);

        await expectLater(
          validator.validateFile(file),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('无法读取 Backup ZIP'),
            ),
          ),
        );
      } finally {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      }
    });
  });
}

Archive _validArchive({
  int formatVersion = BackupService.formatVersion,
  int schemaVersion = WorkbenchDatabase.schemaVersion,
}) {
  final manifest = jsonEncode({
    'format_version': formatVersion,
    'backup_kind': 'manual',
    'app_version': '1.0.0+1',
    'schema_version': schemaVersion,
    'created_at': '2026-09-20T09:00:00.000Z',
    'included_paths': [
      'data/workbench.db',
    ],
  });
  final manifestBytes = utf8.encode(manifest);

  return Archive()
    ..addFile(
      ArchiveFile(
        'manifest.json',
        manifestBytes.length,
        manifestBytes,
      ),
    )
    ..addFile(
      ArchiveFile(
        'data/workbench.db',
        4,
        [0, 1, 2, 3],
      ),
    );
}
