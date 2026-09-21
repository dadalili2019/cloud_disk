import 'dart:io';

import 'package:cloud_disk/workbench/core/workbench_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('WorkbenchDatabase schema', () {
    WorkbenchDatabase? database;

    tearDown(() async {
      await database?.close();
      database = null;
    });

    test('fresh database creates current schema and required objects', () async {
      database = await WorkbenchDatabase.openInMemoryForTesting();

      expect(await _userVersion(database!), WorkbenchDatabase.schemaVersion);

      final objects = await _schemaObjects(database!);
      expect(
        objects.tables,
        containsAll(<String>[
          'workspaces',
          'tasks',
          'notes',
          'entity_links',
          'activity_events',
          'issues',
          'resources',
          'decisions',
          'focus_sessions',
          'knowledge',
          'search_index',
          'ai_threads',
          'ai_messages',
          'developer_projects',
          'developer_commands',
          'developer_snippets',
        ]),
      );
      expect(
        objects.indexes,
        containsAll(<String>[
          'ux_tasks_current_workspace',
          'ix_tasks_workspace_updated',
          'ix_knowledge_category_updated',
          'ix_ai_threads_updated',
          'ux_developer_projects_primary_workspace',
          'ix_developer_commands_workspace_updated',
          'ix_developer_snippets_workspace_updated',
        ]),
      );

      await database!.insert(
        '''
INSERT INTO search_index (
  entity_type, entity_id, workspace_id, title, body
) VALUES (?, ?, ?, ?, ?)
''',
        ['knowledge', 'knowledge-1', '', '迁移测试', '数据库 migration'],
      );
      final searchRows = await database!.select(
        '''
SELECT entity_id
FROM search_index
WHERE search_index MATCH ?
''',
        ['migration'],
      );
      expect(
        searchRows.map((row) => row['entity_id']),
        contains('knowledge-1'),
      );
    });

    for (var startVersion = 1;
        startVersion < WorkbenchDatabase.schemaVersion;
        startVersion++) {
      test('migrates v$startVersion to current schema without losing data',
          () async {
        final tempDirectory = await Directory.systemTemp.createTemp(
          'personal_workbench_migration_v${startVersion}_',
        );
        final databasePath = p.join(tempDirectory.path, 'workbench.db');

        try {
          database = await WorkbenchDatabase.openFileForTesting(
            databasePath,
            targetSchemaVersion: startVersion,
          );
          await _seedLegacyData(database!, startVersion);
          expect(await _userVersion(database!), startVersion);

          await database!.close();
          database = null;

          database = await WorkbenchDatabase.openFileForTesting(
            databasePath,
          );

          expect(
            await _userVersion(database!),
            WorkbenchDatabase.schemaVersion,
          );

          final workspaceRows = await database!.select(
            'SELECT name, slug FROM workspaces WHERE id = ?',
            ['workspace-legacy'],
          );
          expect(workspaceRows, hasLength(1));
          expect(workspaceRows.single['name'], 'Legacy Workspace');
          expect(workspaceRows.single['slug'], 'legacy-workspace');

          final taskRows = await database!.select(
            'SELECT title, is_current FROM tasks WHERE id = ?',
            ['task-legacy'],
          );
          expect(taskRows, hasLength(1));
          expect(taskRows.single['title'], 'Legacy Task');
          expect(taskRows.single['is_current'], 1);

          await _expectVersionSpecificDataPreserved(
            database!,
            startVersion,
          );

          final objects = await _schemaObjects(database!);
          expect(objects.tables, contains('search_index'));
          expect(objects.tables, contains('ai_threads'));
          expect(objects.tables, contains('developer_projects'));
          expect(
            objects.indexes,
            contains('ux_tasks_current_workspace'),
          );
          expect(
            objects.indexes,
            contains('ux_developer_projects_primary_workspace'),
          );

          await _expectCurrentTaskConstraint(database!);
          await _expectDeveloperPrimaryConstraint(database!);
        } finally {
          await database?.close();
          database = null;
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        }
      });
    }

    test('testing entry rejects unsupported target schema versions', () async {
      expect(
        () => WorkbenchDatabase.openInMemoryForTesting(
          targetSchemaVersion: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => WorkbenchDatabase.openInMemoryForTesting(
          targetSchemaVersion: WorkbenchDatabase.schemaVersion + 1,
        ),
        throwsArgumentError,
      );
    });
  });
}

Future<void> _seedLegacyData(
  WorkbenchDatabase database,
  int schemaVersion,
) async {
  const createdAt = '2026-09-21T09:00:00.000Z';

  await database.insert(
    '''
INSERT INTO workspaces (
  id, name, slug, status, created_at, updated_at
) VALUES (?, ?, ?, ?, ?, ?)
''',
    [
      'workspace-legacy',
      'Legacy Workspace',
      'legacy-workspace',
      'active',
      createdAt,
      createdAt,
    ],
  );

  await database.insert(
    '''
INSERT INTO tasks (
  id, workspace_id, title, description, status, progress,
  next_step, priority, is_current, created_at, updated_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
    [
      'task-legacy',
      'workspace-legacy',
      'Legacy Task',
      'Keep this task',
      'doing',
      40,
      'Continue migration',
      1,
      1,
      createdAt,
      createdAt,
    ],
  );

  if (schemaVersion >= 2) {
    await database.insert(
      '''
INSERT INTO issues (
  id, workspace_id, title, status, severity,
  impact, hypothesis, next_investigation_step, resolution,
  created_at, updated_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        'issue-legacy',
        'workspace-legacy',
        'Legacy Issue',
        'open',
        'medium',
        'impact',
        'hypothesis',
        'investigate',
        '',
        createdAt,
        createdAt,
      ],
    );
  }

  if (schemaVersion >= 3) {
    await database.insert(
      '''
INSERT INTO focus_sessions (
  id, workspace_id, task_id, started_at,
  duration_seconds, note, created_at
) VALUES (?, ?, ?, ?, ?, ?, ?)
''',
      [
        'focus-legacy',
        'workspace-legacy',
        'task-legacy',
        createdAt,
        120,
        'Legacy focus',
        createdAt,
      ],
    );
  }

  if (schemaVersion >= 4) {
    await database.insert(
      '''
INSERT INTO knowledge (
  id, title, category, summary, use_when, file_path,
  is_pinned, created_at, updated_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        'knowledge-legacy',
        'Legacy Knowledge',
        'reference',
        'summary',
        'migration',
        'knowledge/legacy.md',
        0,
        createdAt,
        createdAt,
      ],
    );
  }

  if (schemaVersion >= 5) {
    await database.insert(
      '''
INSERT INTO ai_threads (
  id, scope, title, workspace_id, created_at, updated_at
) VALUES (?, ?, ?, ?, ?, ?)
''',
      [
        'thread-legacy',
        'workspace',
        'Legacy Thread',
        'workspace-legacy',
        createdAt,
        createdAt,
      ],
    );
  }
}

Future<void> _expectVersionSpecificDataPreserved(
  WorkbenchDatabase database,
  int startVersion,
) async {
  if (startVersion >= 2) {
    final rows = await database.select(
      'SELECT title FROM issues WHERE id = ?',
      ['issue-legacy'],
    );
    expect(rows.single['title'], 'Legacy Issue');
  }

  if (startVersion >= 3) {
    final rows = await database.select(
      'SELECT note FROM focus_sessions WHERE id = ?',
      ['focus-legacy'],
    );
    expect(rows.single['note'], 'Legacy focus');
  }

  if (startVersion >= 4) {
    final rows = await database.select(
      'SELECT title FROM knowledge WHERE id = ?',
      ['knowledge-legacy'],
    );
    expect(rows.single['title'], 'Legacy Knowledge');
  }

  if (startVersion >= 5) {
    final rows = await database.select(
      'SELECT title FROM ai_threads WHERE id = ?',
      ['thread-legacy'],
    );
    expect(rows.single['title'], 'Legacy Thread');
  }
}

Future<void> _expectCurrentTaskConstraint(
  WorkbenchDatabase database,
) async {
  const createdAt = '2026-09-21T09:00:00.000Z';

  await expectLater(
    database.insert(
      '''
INSERT INTO tasks (
  id, workspace_id, title, description, status, progress,
  next_step, priority, is_current, created_at, updated_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        'task-second-current',
        'workspace-legacy',
        'Second Current',
        '',
        'doing',
        10,
        '',
        0,
        1,
        createdAt,
        createdAt,
      ],
    ),
    throwsA(anything),
  );
}

Future<void> _expectDeveloperPrimaryConstraint(
  WorkbenchDatabase database,
) async {
  const createdAt = '2026-09-21T09:00:00.000Z';

  await database.insert(
    '''
INSERT INTO developer_projects (
  id, workspace_id, name, is_primary, created_at, updated_at
) VALUES (?, ?, ?, ?, ?, ?)
''',
    [
      'developer-primary-1',
      'workspace-legacy',
      'Primary One',
      1,
      createdAt,
      createdAt,
    ],
  );

  await expectLater(
    database.insert(
      '''
INSERT INTO developer_projects (
  id, workspace_id, name, is_primary, created_at, updated_at
) VALUES (?, ?, ?, ?, ?, ?)
''',
      [
        'developer-primary-2',
        'workspace-legacy',
        'Primary Two',
        1,
        createdAt,
        createdAt,
      ],
    ),
    throwsA(anything),
  );
}

Future<int> _userVersion(WorkbenchDatabase database) async {
  final rows = await database.select('PRAGMA user_version');
  return rows.single['user_version']! as int;
}

Future<_SchemaObjects> _schemaObjects(
  WorkbenchDatabase database,
) async {
  final rows = await database.select(
    '''
SELECT type, name
FROM sqlite_master
WHERE type IN ('table', 'index')
  AND name NOT LIKE 'sqlite_%'
''',
  );

  return _SchemaObjects(
    tables: rows
        .where((row) => row['type'] == 'table')
        .map((row) => row['name']! as String)
        .toSet(),
    indexes: rows
        .where((row) => row['type'] == 'index')
        .map((row) => row['name']! as String)
        .toSet(),
  );
}

class _SchemaObjects {
  const _SchemaObjects({
    required this.tables,
    required this.indexes,
  });

  final Set<String> tables;
  final Set<String> indexes;
}
