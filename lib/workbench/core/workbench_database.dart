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

  static const int schemaVersion = 6;

  final QueryExecutor _executor;
  final _WorkbenchExecutorUser _executorUser;

  static Future<WorkbenchDatabase> open(String databasePath) {
    return _open(
      NativeDatabase.createInBackground(File(databasePath)),
      _WorkbenchExecutorUser(),
    );
  }

  static Future<WorkbenchDatabase> openInMemoryForTesting({
    int targetSchemaVersion = schemaVersion,
  }) {
    _validateTargetSchemaVersion(targetSchemaVersion);
    return _open(
      NativeDatabase.memory(),
      _WorkbenchExecutorUser(
        targetSchemaVersion: targetSchemaVersion,
        enableWal: false,
      ),
    );
  }

  static Future<WorkbenchDatabase> openFileForTesting(
    String databasePath, {
    int targetSchemaVersion = schemaVersion,
  }) {
    _validateTargetSchemaVersion(targetSchemaVersion);
    return _open(
      NativeDatabase(
        File(databasePath),
        cachePreparedStatements: false,
      ),
      _WorkbenchExecutorUser(
        targetSchemaVersion: targetSchemaVersion,
        enableWal: false,
      ),
    );
  }

  static void _validateTargetSchemaVersion(int targetSchemaVersion) {
    if (targetSchemaVersion < 1 || targetSchemaVersion > schemaVersion) {
      throw ArgumentError.value(
        targetSchemaVersion,
        'targetSchemaVersion',
        'must be between 1 and $schemaVersion',
      );
    }
  }

  static Future<WorkbenchDatabase> _open(
    QueryExecutor executor,
    _WorkbenchExecutorUser user,
  ) async {
    await executor.ensureOpen(user);
    return WorkbenchDatabase._(executor, user);
  }

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
  _WorkbenchExecutorUser({
    this.targetSchemaVersion = WorkbenchDatabase.schemaVersion,
    this.enableWal = true,
  });

  final int targetSchemaVersion;
  final bool enableWal;

  @override
  int get schemaVersion => targetSchemaVersion;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {
    await executor.ensureOpen(this);
    await executor.runCustom('PRAGMA foreign_keys = ON');
    await executor.runCustom('PRAGMA busy_timeout = 5000');
    if (enableWal) {
      await executor.runCustom('PRAGMA journal_mode = WAL');
    }

    final from = details.versionBefore;
    if (from == null) {
      for (var version = 1; version <= schemaVersion; version++) {
        await _createSchema(executor, _schemaForVersion(version));
      }
      return;
    }

    if (from > schemaVersion) {
      throw StateError(
        'workbench.db schema version $from is newer than supported version $schemaVersion.',
      );
    }

    if (from < schemaVersion) {
      await _migrate(executor, from, schemaVersion);
    }
  }

  Future<void> _migrate(QueryExecutor executor, int from, int to) async {
    var version = from;
    while (version < to) {
      final nextVersion = version + 1;
      await _createSchema(executor, _schemaForVersion(nextVersion));
      version = nextVersion;
    }
  }

  List<String> _schemaForVersion(int version) {
    switch (version) {
      case 1:
        return _schemaV1;
      case 2:
        return _schemaV2;
      case 3:
        return _schemaV3;
      case 4:
        return _schemaV4;
      case 5:
        return _schemaV5;
      case 6:
        return _schemaV6;
      default:
        throw StateError('No Workbench schema registered for v$version.');
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

const List<String> _schemaV3 = [
  '''
CREATE TABLE IF NOT EXISTS focus_sessions (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  task_id TEXT NOT NULL,
  started_at TEXT NOT NULL,
  ended_at TEXT,
  duration_seconds INTEGER NOT NULL DEFAULT 0,
  note TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL,
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id),
  FOREIGN KEY (task_id) REFERENCES tasks(id)
)
''',
  '''
CREATE INDEX IF NOT EXISTS ix_focus_sessions_started
ON focus_sessions(started_at DESC)
''',
  '''
CREATE INDEX IF NOT EXISTS ix_focus_sessions_task
ON focus_sessions(task_id, started_at DESC)
''',
];

const List<String> _schemaV4 = [
  '''
CREATE TABLE IF NOT EXISTS knowledge (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT '',
  summary TEXT NOT NULL DEFAULT '',
  use_when TEXT NOT NULL DEFAULT '',
  file_path TEXT NOT NULL UNIQUE,
  is_pinned INTEGER NOT NULL DEFAULT 0 CHECK (is_pinned IN (0, 1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT
)
''',
  '''
CREATE INDEX IF NOT EXISTS ix_knowledge_category_updated
ON knowledge(category, is_pinned DESC, updated_at DESC)
''',
  '''
CREATE VIRTUAL TABLE IF NOT EXISTS search_index USING fts5(
  entity_type UNINDEXED,
  entity_id UNINDEXED,
  workspace_id UNINDEXED,
  title,
  body,
  tokenize = 'unicode61'
)
''',
];

const List<String> _schemaV5 = [
  '''
CREATE TABLE IF NOT EXISTS ai_threads (
  id TEXT PRIMARY KEY,
  scope TEXT NOT NULL CHECK (scope IN ('task', 'workspace', 'knowledge', 'global')),
  title TEXT NOT NULL DEFAULT '',
  workspace_id TEXT,
  task_id TEXT,
  knowledge_id TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT,
  CHECK (
    (scope = 'task' AND task_id IS NOT NULL) OR
    (scope = 'workspace' AND workspace_id IS NOT NULL) OR
    (scope = 'knowledge' AND knowledge_id IS NOT NULL) OR
    scope = 'global'
  ),
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id),
  FOREIGN KEY (task_id) REFERENCES tasks(id),
  FOREIGN KEY (knowledge_id) REFERENCES knowledge(id)
)
''',
  '''
CREATE INDEX IF NOT EXISTS ix_ai_threads_updated
ON ai_threads(archived_at, updated_at DESC)
''',
  '''
CREATE INDEX IF NOT EXISTS ix_ai_threads_task
ON ai_threads(task_id, updated_at DESC)
''',
  '''
CREATE INDEX IF NOT EXISTS ix_ai_threads_workspace
ON ai_threads(workspace_id, updated_at DESC)
''',
  '''
CREATE INDEX IF NOT EXISTS ix_ai_threads_knowledge
ON ai_threads(knowledge_id, updated_at DESC)
''',
  '''
CREATE TABLE IF NOT EXISTS ai_messages (
  id TEXT PRIMARY KEY,
  thread_id TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  context_snapshot_json TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL,
  FOREIGN KEY (thread_id) REFERENCES ai_threads(id) ON DELETE CASCADE
)
''',
  '''
CREATE INDEX IF NOT EXISTS ix_ai_messages_thread_created
ON ai_messages(thread_id, created_at ASC)
''',
];

const List<String> _schemaV6 = [
  '''
CREATE TABLE IF NOT EXISTS developer_projects (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  name TEXT NOT NULL,
  local_path TEXT NOT NULL DEFAULT '',
  repository_url TEXT NOT NULL DEFAULT '',
  branch TEXT NOT NULL DEFAULT '',
  tech_stack TEXT NOT NULL DEFAULT '',
  notes TEXT NOT NULL DEFAULT '',
  is_primary INTEGER NOT NULL DEFAULT 0 CHECK (is_primary IN (0, 1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT,
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id)
)
''',
  '''
CREATE INDEX IF NOT EXISTS ix_developer_projects_workspace_updated
ON developer_projects(workspace_id, is_primary DESC, updated_at DESC)
''',
  '''
CREATE UNIQUE INDEX IF NOT EXISTS ux_developer_projects_primary_workspace
ON developer_projects(workspace_id)
WHERE is_primary = 1 AND archived_at IS NULL
''',
  '''
CREATE TABLE IF NOT EXISTS developer_commands (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  project_id TEXT,
  name TEXT NOT NULL,
  command TEXT NOT NULL,
  working_directory TEXT,
  category TEXT NOT NULL DEFAULT 'other' CHECK (
    category IN ('run', 'build', 'test', 'database', 'docker', 'git', 'other')
  ),
  notes TEXT NOT NULL DEFAULT '',
  is_pinned INTEGER NOT NULL DEFAULT 0 CHECK (is_pinned IN (0, 1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT,
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id),
  FOREIGN KEY (project_id) REFERENCES developer_projects(id)
)
''',
  '''
CREATE INDEX IF NOT EXISTS ix_developer_commands_workspace_updated
ON developer_commands(workspace_id, is_pinned DESC, updated_at DESC)
''',
  '''
CREATE INDEX IF NOT EXISTS ix_developer_commands_project_updated
ON developer_commands(project_id, is_pinned DESC, updated_at DESC)
''',
  '''
CREATE TABLE IF NOT EXISTS developer_snippets (
  id TEXT PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  project_id TEXT,
  title TEXT NOT NULL,
  language TEXT NOT NULL DEFAULT '',
  content TEXT NOT NULL DEFAULT '',
  notes TEXT NOT NULL DEFAULT '',
  is_pinned INTEGER NOT NULL DEFAULT 0 CHECK (is_pinned IN (0, 1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT,
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id),
  FOREIGN KEY (project_id) REFERENCES developer_projects(id)
)
''',
  '''
CREATE INDEX IF NOT EXISTS ix_developer_snippets_workspace_updated
ON developer_snippets(workspace_id, is_pinned DESC, updated_at DESC)
''',
  '''
CREATE INDEX IF NOT EXISTS ix_developer_snippets_project_updated
ON developer_snippets(project_id, is_pinned DESC, updated_at DESC)
''',
];
