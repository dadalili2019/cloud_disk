import '../core/models.dart';
import '../core/workbench_database.dart';
import '../domain/repositories.dart';

class SqliteWorkspaceRepository implements WorkspaceRepository {
  const SqliteWorkspaceRepository(this.db);

  final WorkbenchSqlExecutor db;

  @override
  Future<List<WorkspaceModel>> listActive() async {
    final rows = await db.select(
      '''
SELECT * FROM workspaces
WHERE archived_at IS NULL AND status = 'active'
ORDER BY updated_at DESC
''',
    );
    return rows.map(_workspaceFromRow).toList();
  }

  @override
  Future<WorkspaceModel?> getById(String id) async {
    final rows = await db.select(
      'SELECT * FROM workspaces WHERE id = ? LIMIT 1',
      [id],
    );
    return rows.isEmpty ? null : _workspaceFromRow(rows.first);
  }

  @override
  Future<WorkspaceModel?> getBySlug(String slug) async {
    final rows = await db.select(
      'SELECT * FROM workspaces WHERE slug = ? LIMIT 1',
      [slug],
    );
    return rows.isEmpty ? null : _workspaceFromRow(rows.first);
  }

  @override
  Future<void> insert(WorkspaceModel workspace) async {
    await db.insert(
      '''
INSERT INTO workspaces (
  id, name, slug, status, created_at, updated_at, archived_at
) VALUES (?, ?, ?, ?, ?, ?, ?)
''',
      [
        workspace.id,
        workspace.name,
        workspace.slug,
        workspace.status,
        workspace.createdAt.toUtc().toIso8601String(),
        workspace.updatedAt.toUtc().toIso8601String(),
        workspace.archivedAt?.toUtc().toIso8601String(),
      ],
    );
  }
}

class SqliteTaskRepository implements TaskRepository {
  SqliteTaskRepository(this.database);

  final WorkbenchDatabase database;

  @override
  Future<List<TaskModel>> listByWorkspace(String workspaceId) async {
    final rows = await database.select(
      '''
SELECT * FROM tasks
WHERE workspace_id = ? AND archived_at IS NULL
ORDER BY is_current DESC, updated_at DESC
''',
      [workspaceId],
    );
    return rows.map(_taskFromRow).toList();
  }

  @override
  Future<TaskModel?> getById(String id) async {
    final rows = await database.select(
      'SELECT * FROM tasks WHERE id = ? LIMIT 1',
      [id],
    );
    return rows.isEmpty ? null : _taskFromRow(rows.first);
  }

  @override
  Future<TaskModel?> getCurrent(String workspaceId) async {
    final rows = await database.select(
      '''
SELECT * FROM tasks
WHERE workspace_id = ? AND is_current = 1 AND archived_at IS NULL
LIMIT 1
''',
      [workspaceId],
    );
    return rows.isEmpty ? null : _taskFromRow(rows.first);
  }

  @override
  Future<void> insert(TaskModel task) async {
    await database.insert(
      '''
INSERT INTO tasks (
  id, workspace_id, title, description, status, progress, next_step,
  priority, is_current, due_at, created_at, updated_at, archived_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        task.id,
        task.workspaceId,
        task.title,
        task.description,
        task.status,
        task.progress,
        task.nextStep,
        task.priority,
        task.isCurrent ? 1 : 0,
        task.dueAt?.toUtc().toIso8601String(),
        task.createdAt.toUtc().toIso8601String(),
        task.updatedAt.toUtc().toIso8601String(),
        task.archivedAt?.toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<void> update(TaskModel task) async {
    final updated = await database.update(
      '''
UPDATE tasks
SET title = ?, description = ?, status = ?, progress = ?, next_step = ?,
    priority = ?, due_at = ?, updated_at = ?
WHERE id = ? AND workspace_id = ? AND archived_at IS NULL
''',
      [
        task.title,
        task.description,
        task.status,
        task.progress,
        task.nextStep,
        task.priority,
        task.dueAt?.toUtc().toIso8601String(),
        task.updatedAt.toUtc().toIso8601String(),
        task.id,
        task.workspaceId,
      ],
    );
    if (updated != 1) {
      throw StateError('Task not found or archived: ${task.id}');
    }
  }

  @override
  Future<void> setCurrent(String workspaceId, String taskId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await database.transaction((tx) async {
      await tx.update(
        '''
UPDATE tasks
SET is_current = 0, updated_at = ?
WHERE workspace_id = ? AND is_current = 1
''',
        [now, workspaceId],
      );
      final updated = await tx.update(
        '''
UPDATE tasks
SET is_current = 1,
    status = CASE WHEN status = 'todo' THEN 'doing' ELSE status END,
    updated_at = ?
WHERE id = ? AND workspace_id = ? AND archived_at IS NULL
''',
        [now, taskId, workspaceId],
      );
      if (updated != 1) {
        throw StateError('Task not found or archived: $taskId');
      }
    });
  }
}

class SqliteNoteRepository implements NoteRepository {
  const SqliteNoteRepository(this.db);

  final WorkbenchSqlExecutor db;

  @override
  Future<List<NoteModel>> listByWorkspace(String workspaceId) async {
    final rows = await db.select(
      '''
SELECT * FROM notes
WHERE workspace_id = ? AND archived_at IS NULL
ORDER BY is_pinned DESC, updated_at DESC
''',
      [workspaceId],
    );
    return rows.map(_noteFromRow).toList();
  }

  @override
  Future<NoteModel?> getById(String id) async {
    final rows = await db.select(
      'SELECT * FROM notes WHERE id = ? LIMIT 1',
      [id],
    );
    return rows.isEmpty ? null : _noteFromRow(rows.first);
  }

  @override
  Future<List<NoteModel>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await db.select(
      '''
SELECT * FROM notes
WHERE id IN ($placeholders) AND archived_at IS NULL
ORDER BY updated_at DESC
''',
      ids,
    );
    return rows.map(_noteFromRow).toList();
  }

  @override
  Future<void> insert(NoteModel note) async {
    await db.insert(
      '''
INSERT INTO notes (
  id, workspace_id, title, file_path, is_pinned,
  created_at, updated_at, archived_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        note.id,
        note.workspaceId,
        note.title,
        note.filePath,
        note.isPinned ? 1 : 0,
        note.createdAt.toUtc().toIso8601String(),
        note.updatedAt.toUtc().toIso8601String(),
        note.archivedAt?.toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<void> touchUpdatedAt(String noteId, DateTime updatedAt) async {
    final count = await db.update(
      'UPDATE notes SET updated_at = ? WHERE id = ?',
      [updatedAt.toUtc().toIso8601String(), noteId],
    );
    if (count != 1) {
      throw StateError('Note not found: $noteId');
    }
  }
}

class SqliteEntityLinkRepository implements EntityLinkRepository {
  const SqliteEntityLinkRepository(this.db);

  final WorkbenchSqlExecutor db;

  @override
  Future<void> link({
    required String id,
    required String fromType,
    required String fromId,
    required String relationType,
    required String toType,
    required String toId,
    required DateTime createdAt,
  }) async {
    await db.insert(
      '''
INSERT OR IGNORE INTO entity_links (
  id, from_type, from_id, to_type, to_id, relation_type, created_at
) VALUES (?, ?, ?, ?, ?, ?, ?)
''',
      [
        id,
        fromType,
        fromId,
        toType,
        toId,
        relationType,
        createdAt.toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<List<String>> listFromIds({
    required String toType,
    required String toId,
    required String relationType,
    required String fromType,
  }) async {
    final rows = await db.select(
      '''
SELECT from_id FROM entity_links
WHERE to_type = ? AND to_id = ? AND relation_type = ? AND from_type = ?
ORDER BY created_at DESC
''',
      [toType, toId, relationType, fromType],
    );
    return rows.map((row) => row['from_id']! as String).toList();
  }
}

class SqliteActivityRepository implements ActivityRepository {
  const SqliteActivityRepository(this.db);

  final WorkbenchSqlExecutor db;

  @override
  Future<void> insert(ActivityEventModel event) async {
    await db.insert(
      '''
INSERT INTO activity_events (
  id, workspace_id, entity_type, entity_id, event_type, summary, created_at
) VALUES (?, ?, ?, ?, ?, ?, ?)
''',
      [
        event.id,
        event.workspaceId,
        event.entityType,
        event.entityId,
        event.eventType,
        event.summary,
        event.createdAt.toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<List<ActivityEventModel>> listRecent(
    String workspaceId, {
    int limit = 10,
  }) async {
    final safeLimit = limit.clamp(1, 100);
    final rows = await db.select(
      '''
SELECT * FROM activity_events
WHERE workspace_id = ?
ORDER BY created_at DESC
LIMIT ?
''',
      [workspaceId, safeLimit],
    );
    return rows.map(_activityFromRow).toList();
  }
}

WorkspaceModel _workspaceFromRow(Map<String, Object?> row) {
  return WorkspaceModel(
    id: row['id']! as String,
    name: row['name']! as String,
    slug: row['slug']! as String,
    status: row['status']! as String,
    createdAt: DateTime.parse(row['created_at']! as String).toUtc(),
    updatedAt: DateTime.parse(row['updated_at']! as String).toUtc(),
    archivedAt: _dateOrNull(row['archived_at']),
  );
}

TaskModel _taskFromRow(Map<String, Object?> row) {
  return TaskModel(
    id: row['id']! as String,
    workspaceId: row['workspace_id']! as String,
    title: row['title']! as String,
    description: row['description']! as String,
    status: row['status']! as String,
    progress: row['progress']! as int,
    nextStep: row['next_step']! as String,
    priority: row['priority']! as int,
    isCurrent: (row['is_current']! as int) == 1,
    dueAt: _dateOrNull(row['due_at']),
    createdAt: DateTime.parse(row['created_at']! as String).toUtc(),
    updatedAt: DateTime.parse(row['updated_at']! as String).toUtc(),
    archivedAt: _dateOrNull(row['archived_at']),
  );
}

NoteModel _noteFromRow(Map<String, Object?> row) {
  return NoteModel(
    id: row['id']! as String,
    workspaceId: row['workspace_id']! as String,
    title: row['title']! as String,
    filePath: row['file_path']! as String,
    isPinned: (row['is_pinned']! as int) == 1,
    createdAt: DateTime.parse(row['created_at']! as String).toUtc(),
    updatedAt: DateTime.parse(row['updated_at']! as String).toUtc(),
    archivedAt: _dateOrNull(row['archived_at']),
  );
}

ActivityEventModel _activityFromRow(Map<String, Object?> row) {
  return ActivityEventModel(
    id: row['id']! as String,
    workspaceId: row['workspace_id']! as String,
    entityType: row['entity_type'] as String?,
    entityId: row['entity_id'] as String?,
    eventType: row['event_type']! as String,
    summary: row['summary']! as String,
    createdAt: DateTime.parse(row['created_at']! as String).toUtc(),
  );
}

DateTime? _dateOrNull(Object? value) {
  if (value == null) return null;
  return DateTime.parse(value as String).toUtc();
}
