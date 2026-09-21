import 'dart:io';

import 'package:cloud_disk/workbench/application/backup_service.dart';
import 'package:cloud_disk/workbench/application/restore_service.dart';
import 'package:cloud_disk/workbench/application/search_service.dart';
import 'package:cloud_disk/workbench/core/app_paths.dart';
import 'package:cloud_disk/workbench/core/models.dart';
import 'package:cloud_disk/workbench/core/workbench_database.dart';
import 'package:cloud_disk/workbench/data/markdown_store.dart';
import 'package:cloud_disk/workbench/data/sqlite_decision_repository.dart';
import 'package:cloud_disk/workbench/data/sqlite_developer_command_repository.dart';
import 'package:cloud_disk/workbench/data/sqlite_developer_project_repository.dart';
import 'package:cloud_disk/workbench/data/sqlite_developer_snippet_repository.dart';
import 'package:cloud_disk/workbench/data/sqlite_issue_repository.dart';
import 'package:cloud_disk/workbench/data/sqlite_knowledge_repository.dart';
import 'package:cloud_disk/workbench/data/sqlite_repositories.dart';
import 'package:cloud_disk/workbench/data/sqlite_resource_repository.dart';
import 'package:cloud_disk/workbench/domain/search_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

const _runScale = bool.fromEnvironment(
  'WORKBENCH_SCALE_VERIFY',
  defaultValue: false,
);
const _workspaceCount = int.fromEnvironment(
  'WORKBENCH_SCALE_WORKSPACES',
  defaultValue: 5,
);
const _tasksPerWorkspace = int.fromEnvironment(
  'WORKBENCH_SCALE_TASKS_PER_WORKSPACE',
  defaultValue: 500,
);
const _notesPerWorkspace = int.fromEnvironment(
  'WORKBENCH_SCALE_NOTES_PER_WORKSPACE',
  defaultValue: 100,
);
const _noteBodyBytes = int.fromEnvironment(
  'WORKBENCH_SCALE_NOTE_BODY_BYTES',
  defaultValue: 2048,
);

void main() {
  test(
    'synthetic Search / Backup / Restore scale verification',
    () async {
      expect(_workspaceCount, greaterThan(0));
      expect(_tasksPerWorkspace, greaterThanOrEqualTo(0));
      expect(_notesPerWorkspace, greaterThanOrEqualTo(0));
      expect(_noteBodyBytes, greaterThan(0));

      SharedPreferences.setMockInitialValues({});

      final temp = await Directory.systemTemp.createTemp(
        'personal_workbench_scale_',
      );
      final sourcePaths = await AppPaths.createAt(
        Directory(p.join(temp.path, 'source')),
      );
      final targetPaths = await AppPaths.createAt(
        Directory(p.join(temp.path, 'target')),
      );

      WorkbenchDatabase? sourceDatabase;
      WorkbenchDatabase? restoredDatabase;

      try {
        sourceDatabase = await WorkbenchDatabase.openFileForTesting(
          sourcePaths.databasePath,
        );

        final seedWatch = Stopwatch()..start();
        await _seedSyntheticData(sourceDatabase, sourcePaths);
        seedWatch.stop();

        final searchIndex = _CountingSearchIndexRepository();
        final searchService = SearchService(
          workspaces: SqliteWorkspaceRepository(sourceDatabase),
          tasks: SqliteTaskRepository(sourceDatabase),
          notes: SqliteNoteRepository(sourceDatabase),
          issues: SqliteIssueRepository(sourceDatabase),
          resources: SqliteResourceRepository(sourceDatabase),
          decisions: SqliteDecisionRepository(sourceDatabase),
          knowledge: SqliteKnowledgeRepository(sourceDatabase),
          developerProjects: SqliteDeveloperProjectRepository(sourceDatabase),
          developerCommands: SqliteDeveloperCommandRepository(sourceDatabase),
          developerSnippets: SqliteDeveloperSnippetRepository(sourceDatabase),
          markdownStore: MarkdownStore(sourcePaths),
          index: searchIndex,
        );

        final searchWatch = Stopwatch()..start();
        await searchService.rebuildIndex();
        searchWatch.stop();

        final expectedSearchEntries =
            _workspaceCount * (_tasksPerWorkspace + _notesPerWorkspace);
        expect(searchIndex.entryCount, expectedSearchEntries);

        final backupService = BackupService(
          paths: sourcePaths,
          database: sourceDatabase,
        );
        final backupWatch = Stopwatch()..start();
        final backup = await backupService.createManualBackup();
        backupWatch.stop();

        expect(await backup.file.exists(), isTrue);
        final backupBytes = await backup.file.length();

        final targetDatabase = await WorkbenchDatabase.openFileForTesting(
          targetPaths.databasePath,
        );
        final targetBackupService = BackupService(
          paths: targetPaths,
          database: targetDatabase,
        );
        final restoreService = RestoreService(
          paths: targetPaths,
          backupService: targetBackupService,
        );

        final stageWatch = Stopwatch()..start();
        await restoreService.stageRestore(backup.file);
        stageWatch.stop();

        await targetDatabase.close();

        final applyWatch = Stopwatch()..start();
        final applied = await RestoreService.applyPendingRestoreIfPresent(
          targetPaths,
        );
        applyWatch.stop();
        expect(applied, isTrue);

        restoredDatabase = await WorkbenchDatabase.openFileForTesting(
          targetPaths.databasePath,
        );

        final workspaceRows = await restoredDatabase.select(
          'SELECT COUNT(*) AS count FROM workspaces',
        );
        final taskRows = await restoredDatabase.select(
          'SELECT COUNT(*) AS count FROM tasks',
        );
        final noteRows = await restoredDatabase.select(
          'SELECT COUNT(*) AS count FROM notes',
        );

        expect(workspaceRows.single['count'], _workspaceCount);
        expect(
          taskRows.single['count'],
          _workspaceCount * _tasksPerWorkspace,
        );
        expect(
          noteRows.single['count'],
          _workspaceCount * _notesPerWorkspace,
        );

        final restoredNote = File(
          targetPaths.resolveRelative(
            p.posix.join('workspaces', 'workspace-0', 'notes', 'note-0.md'),
          ),
        );
        expect(await restoredNote.exists(), isTrue);

        stdout.writeln('Personal Workbench synthetic scale verification');
        stdout.writeln('----------------------------------------------');
        stdout.writeln('Workspaces: $_workspaceCount');
        stdout.writeln(
          'Tasks: ${_workspaceCount * _tasksPerWorkspace}',
        );
        stdout.writeln(
          'Notes: ${_workspaceCount * _notesPerWorkspace}',
        );
        stdout.writeln('Note body bytes: $_noteBodyBytes');
        stdout.writeln('Search entries: ${searchIndex.entryCount}');
        stdout.writeln('Seed: ${seedWatch.elapsedMilliseconds} ms');
        stdout.writeln(
          'Search rebuild collection: ${searchWatch.elapsedMilliseconds} ms',
        );
        stdout.writeln('Backup: ${backupWatch.elapsedMilliseconds} ms');
        stdout.writeln('Backup size: $backupBytes bytes');
        stdout.writeln(
          'Restore stage: ${stageWatch.elapsedMilliseconds} ms',
        );
        stdout.writeln(
          'Restore apply: ${applyWatch.elapsedMilliseconds} ms',
        );
        stdout.writeln('RESULT: PASS');
      } finally {
        await restoredDatabase?.close();
        await sourceDatabase?.close();
        await _deleteWithRetry(temp);
      }
    },
    skip: _runScale
        ? false
        : 'Manual scale verification. Enable with '
            '--dart-define=WORKBENCH_SCALE_VERIFY=true.',
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

Future<void> _seedSyntheticData(
  WorkbenchDatabase database,
  AppPaths paths,
) async {
  final now = DateTime.utc(2026, 9, 21, 7).toIso8601String();

  await database.transaction((tx) async {
    for (var workspaceIndex = 0;
        workspaceIndex < _workspaceCount;
        workspaceIndex++) {
      final workspaceId = 'workspace-$workspaceIndex';
      final slug = 'workspace-$workspaceIndex';

      await tx.insert(
        '''
INSERT INTO workspaces (
  id, name, slug, status, created_at, updated_at
) VALUES (?, ?, ?, 'active', ?, ?)
''',
        [
          workspaceId,
          'Scale Workspace $workspaceIndex',
          slug,
          now,
          now,
        ],
      );

      for (var taskIndex = 0;
          taskIndex < _tasksPerWorkspace;
          taskIndex++) {
        await tx.insert(
          '''
INSERT INTO tasks (
  id, workspace_id, title, description, status, progress,
  next_step, priority, is_current, created_at, updated_at
) VALUES (?, ?, ?, ?, 'todo', 0, ?, 0, 0, ?, ?)
''',
          [
            'task-$workspaceIndex-$taskIndex',
            workspaceId,
            'Synthetic Task $workspaceIndex-$taskIndex',
            'Synthetic task description for search rebuild verification.',
            'Next step for task $taskIndex',
            now,
            now,
          ],
        );
      }

      for (var noteIndex = 0;
          noteIndex < _notesPerWorkspace;
          noteIndex++) {
        final relativePath = p.posix.join(
          'workspaces',
          slug,
          'notes',
          'note-$noteIndex.md',
        );

        await tx.insert(
          '''
INSERT INTO notes (
  id, workspace_id, title, file_path, is_pinned, created_at, updated_at
) VALUES (?, ?, ?, ?, 0, ?, ?)
''',
          [
            'note-$workspaceIndex-$noteIndex',
            workspaceId,
            'Synthetic Note $workspaceIndex-$noteIndex',
            relativePath,
            now,
            now,
          ],
        );
      }
    }
  });

  final body = _noteBody(_noteBodyBytes);
  for (var workspaceIndex = 0;
      workspaceIndex < _workspaceCount;
      workspaceIndex++) {
    final slug = 'workspace-$workspaceIndex';
    final notesDirectory = paths.workspaceNotesDirectory(slug);
    await notesDirectory.create(recursive: true);

    for (var noteIndex = 0;
        noteIndex < _notesPerWorkspace;
        noteIndex++) {
      await File(
        p.join(notesDirectory.path, 'note-$noteIndex.md'),
      ).writeAsString(
        '# Synthetic Note $workspaceIndex-$noteIndex\n\n$body',
        flush: true,
      );
    }
  }
}

String _noteBody(int targetBytes) {
  const seed =
      'Personal Workbench synthetic note body for search, backup and restore. ';
  final buffer = StringBuffer();
  while (buffer.length < targetBytes) {
    buffer.write(seed);
  }
  return buffer.toString().substring(0, targetBytes);
}

Future<void> _deleteWithRetry(Directory directory) async {
  if (!await directory.exists()) return;

  Object? lastError;
  for (var attempt = 0; attempt < 5; attempt++) {
    try {
      await directory.delete(recursive: true);
      return;
    } catch (error) {
      lastError = error;
      await Future<void>.delayed(
        Duration(milliseconds: 150 * (attempt + 1)),
      );
    }
  }

  if (Platform.isWindows && lastError is PathAccessException) {
    return;
  }
  if (lastError != null) throw lastError;
}

class _CountingSearchIndexRepository implements SearchIndexRepository {
  int entryCount = 0;

  @override
  Future<void> clear() async {
    entryCount = 0;
  }

  @override
  Future<void> rebuild(List<SearchIndexEntry> entries) async {
    entryCount = entries.length;
  }

  @override
  Future<void> replace({
    required String entityType,
    required String entityId,
    String? workspaceId,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> remove({
    required String entityType,
    required String entityId,
  }) async {}

  @override
  Future<List<SearchResultModel>> search(
    String query, {
    Set<String>? entityTypes,
    String? workspaceId,
    int limit = 50,
  }) async {
    return const [];
  }
}
