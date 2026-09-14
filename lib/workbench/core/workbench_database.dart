import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

abstract interface class WorkbenchSqlExecutor {
  Future<List<Map<String, Object?>>> select(
    String statement, [
    List<Object?> args = const [],
  ]);

  Future<int> insert(
    String statement, [
    List<Object?> args = const [],
  ]);

  Future<int> update(
    String statement, [
    List<Object?> args = const [],
  ]);

  Future<int> delete(
    String statement, [
    List<Object?> args = const [],
  ]);

  Future<void> custom(
    String statement, [
    List<Object?> args = const [],
  ]);
}

class WorkbenchDatabase implements WorkbenchSqlExecutor {
  WorkbenchDatabase._(this._executor, this._executorUser);

  static const int schemaVersion = 2;

  final QueryExecutor _executor;
  final _WorkbenchExecutorUser _executorUser;

  static Future<WorkbenchDatabase> open(String databasePath) async {
    final executor = NativeDatabase.createInBackground(File(databasePath));
    final user = _WorkbenchExecutorUser();
    await executor.ensureOpen(user);
    return WorkbenchDatabase._(executor, user);
  }

  @override
  Future<List<Map<String, Object?>>> select(
    String statement, [
    List<Object?> args = const [],
  ]) {
    return _executor.runSelect(statement, args);
  }

  @override
  Future<int> insert(
    String statement, [
    List<Object?> args = const [],
  ]) {
    return _executor.runInsert(statement, args);
  }

  @override
  Future<int> update(
    String statement, [
    List<Object?> args = const [],
  ]) {
    return _executor.runUpdate(statement, args);
  }

  @override
  Future<int> delete(
    String statement, [
    List<Object?> args = const [],
  ]) {
    return _executor.runDelete(statement, args);
  }

  @override
  Future<void> custom(
    String statement, [
    List<Object?> args = const [],
  ]) {
    return _executor.runCustom(statement, args);
  }

  Future<T> transaction<T>(
    Future<T> Function(WorkbenchSqlExecutor tx) action,
  ) async {
    final transaction = _executor.beginTransaction();
    await transaction.ensureOpen(_executorUser);
    final session = _TransactionSession(transaction);

    try {
      final result = await action(session);
      await transaction.send();
      return result;
    } catch (_) {
      await transaction.rollback();
      rethrow;
    }
  }

  Future<void> close() => _executor.close();
}

class _TransactionSession implements WorkbenchSqlExecutor {
  const _TransactionSession(this._executor);

  final TransactionExecutor _executor;

  @override
  Future<List<Map<String, Object?>>> select(
    String statement, [
    List<Object?> args = const [],
  ]) => _executor.runSelect(statement, args);

  @override
  Future<int> insert(
    String statement, [
    List<Object?> args = const [],
  ]) => _executor.runInsert(statement, args);

  @override
  Future<int> update(
    String statement, [
    List<Object?> args = const [],
  ]) => _executor.runUpdate(statement, args);

  @override
  Future<int> delete(
    String statement, [
    List<Object?> args = const [],
  ]) => _executor.runDelete(statement, args);

  @override
  Future<void> custom(
    String statement, [
    List<Object?> args = const [],
  ]) => _executor.runCustom(statement, args);
}

class _WorkbenchExecutorUser extends QueryExecutorUser {
  @override
  int get schemaVersion => WorkbenchDatabase.schemaVersion;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {
    await executor.ensureOpen(this);

    await executor.runCustom('PRAGMA foreign_keys = ON');
    await executor.runCustom('PRAGMA busy_timeout = 5000');
    await executor.runCustom('PRAGMA journal_mode = WAL');

    final from = details.versionBefore;
    if (from == null) {
      await _createSchema(executor, _schemaV1);
      await _createSchema(executor, _schemaV2);
      return;
    }

    if (from > schemaVersion) {
      throw StateError(
        'workbench.db schema version $from is newer than supported '
        'version $schemaVersion.',
      );
    }

    if (from < schemaVersion) {
      await _migrate(executor, from, schemaVersion);
    }
  }

  Future<void> _migrate(
    QueryExecutor executor,
    int from,
    int to,
  ) async {
    var version = from;
    while (version < to) {
      switch (version) {
        case 0:
          await _createSchema(executor, _schemaV1);
          break;
        case 1:
          await _createSchema(executor, _schemaV2);
          break;
        default:
          throw StateError(
            'No Workbench migration registered for $version -> ${version + 1}.',
          );
      }
      version++;
    }
  }

  Future<void> _createSchema(
    QueryExecutor executor,
    List<String> statements,
  ) async {
    final tx = executor.beginTransaction();
    await tx.ensureOpen(this);
    try {
      for (final statement in statements) {
        await tx.runCustom(statement);
      }
      await tx.send();
    } catch (_) {
      await tx.rollback();
      rethrow;
    }
  }
}

const List<String> _schemaV1 = [
  '''
CREATE TABLE IF NOT EXISTS workspaces (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'active',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT
)
''',
  '''
CREATE TABLE IF NOT EXISTS tasks (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'todo',
  progress INTEGER NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
  next_step TEXT NOT NULL DEFAULT '',
  priority INTEGER NOT NULL DEFAULT 0,
  is_current INTEGER NOT NULL DEFAULT 0 CHECK (is_current IN (0, 1)),
  due_at TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT,
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id)
)
''',
  '''
CREATE UNIQUE INDEX IF NOT EXISTS ux_tasks_current_workspace
ON tasks(workspace_id)
WHERE is_current = 1 AND archived_at IS NULL
''',
  '''
CREATE INDEX IF NOT EXISTS ix_tasks_workspace_updated
ON tasks(workspace_id, updated_at DESC)
''',
  '''
CREATE TABLE IF NOT EXISTS notes (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  title TEXT NOT NULL,
  file_path TEXT NOT NULL UNIQUE,
  is_pinned INTEGER NOT NULL DEFAULT 0 CHECK (is_pinned IN (0, 1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT,
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id)
)
''',
  '''
CREATE INDEX IF NOT EXISTS ix_notes_workspace_updated
ON notes(workspace_id, updated_at DESC)
''',
  '''
CREATE TABLE IF NOT EXISTS entity_links (
  id TEXT PRIMARY KEY,
  from_type TEXT NOT NULL,
  from_id TEXT NOT NULL,
  to_type TEXT NOT NULL,
  to_id TEXT NOT NULL,
  relation_type TEXT NOT NULL,
  created_at TEXT NOT NULL,
  UNIQUE (from_type, from_id, to_type, to_id, relation_type)
)
''',
  '''
CREATE INDEX IF NOT EXISTS ix_entity_links_to
ON entity_links(to_type, to_id, relation_type)
''',
  '''
CREATE INDEX IF NOT EXISTS ix_entity_links_from
ON entity_links(from_type, from_id, relation_type)
''',
  '''
CREATE TABLE IF NOT EXISTS activity_events (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  entity_type TEXT,
  entity_id TEXT,
  event_type TEXT NOT NULL,
  summary TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL,
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id)
)
''',
  '''
CREATE INDEX IF NOT EXISTS ix_activity_workspace_created
ON activity_events(workspace_id, created_at DESC)
''',
];

const List<String> _schemaV2 = [
  '''
CREATE TABLE IF NOT EXISTS issues (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  title TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open',
  severity TEXT NOT NULL DEFAULT 'medium',
  impact TEXT NOT NULL DEFAULT '',
  hypothesis TEXT NOT NULL DEFAULT '',
  next_investigation_step TEXT NOT NULL DEFAULT '',
  resolution TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT,
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id)
)
''',
  '''
CREATE INDEX IF NOT EXISTS ix_issues_workspace_status_updated
ON issues(workspace_id, status, updated_at DESC)
''',
  '''
CREATE TABLE IF NOT EXISTS resources (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  name TEXT NOT NULL,
  resource_type TEXT NOT NULL DEFAULT 'other',
  uri TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  is_pinned INTEGER NOT NULL DEFAULT 0 CHECK (is_pinned IN (0, 1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT,
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id)
)
''',
  '''
CREATE INDEX IF NOT EXISTS ix_resources_workspace_updated
ON resources(workspace_id, is_pinned DESC, updated_at DESC)
''',
  '''
CREATE TABLE IF NOT EXISTS decisions (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  title TEXT NOT NULL,
  decision_text TEXT NOT NULL DEFAULT '',
  rationale TEXT NOT NULL DEFAULT '',
  revisit_condition TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'active',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT,
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id)
)
''',
  '''
CREATE INDEX IF NOT EXISTS ix_decisions_workspace_status_updated
ON decisions(workspace_id, status, updated_at DESC)
''',
];
