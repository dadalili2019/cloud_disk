import '../core/ai_context_models.dart';
import '../core/ai_conversation_models.dart';
import '../core/workbench_database.dart';
import '../domain/ai_conversation_repository.dart';

class SqliteAIThreadRepository implements AIThreadRepository {
  const SqliteAIThreadRepository(this.db);

  final WorkbenchSqlExecutor db;

  @override
  Future<List<AIThreadModel>> listActive({int limit = 50}) async {
    final rows = await db.select(
      '''
SELECT * FROM ai_threads
WHERE archived_at IS NULL
ORDER BY updated_at DESC
LIMIT ?
''',
      [limit],
    );
    return rows.map(_threadFromRow).toList(growable: false);
  }

  @override
  Future<AIThreadModel?> getById(String id) async {
    final rows = await db.select(
      'SELECT * FROM ai_threads WHERE id = ? LIMIT 1',
      [id],
    );
    return rows.isEmpty ? null : _threadFromRow(rows.first);
  }

  @override
  Future<List<AIThreadModel>> listByAnchor({
    String? workspaceId,
    String? taskId,
    String? knowledgeId,
    int limit = 50,
  }) async {
    final clauses = <String>['archived_at IS NULL'];
    final args = <Object?>[];
    if (workspaceId != null) {
      clauses.add('workspace_id = ?');
      args.add(workspaceId);
    }
    if (taskId != null) {
      clauses.add('task_id = ?');
      args.add(taskId);
    }
    if (knowledgeId != null) {
      clauses.add('knowledge_id = ?');
      args.add(knowledgeId);
    }
    args.add(limit);

    final rows = await db.select(
      '''
SELECT * FROM ai_threads
WHERE ${clauses.join(' AND ')}
ORDER BY updated_at DESC
LIMIT ?
''',
      args,
    );
    return rows.map(_threadFromRow).toList(growable: false);
  }

  @override
  Future<void> insert(AIThreadModel thread) async {
    await db.insert(
      '''
INSERT INTO ai_threads (
  id, scope, title, workspace_id, task_id, knowledge_id,
  created_at, updated_at, archived_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        thread.id,
        thread.scope.name,
        thread.title,
        thread.workspaceId,
        thread.taskId,
        thread.knowledgeId,
        thread.createdAt.toUtc().toIso8601String(),
        thread.updatedAt.toUtc().toIso8601String(),
        thread.archivedAt?.toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<void> update(AIThreadModel thread) async {
    final updated = await db.update(
      '''
UPDATE ai_threads
SET title = ?, workspace_id = ?, task_id = ?, knowledge_id = ?,
    updated_at = ?, archived_at = ?
WHERE id = ?
''',
      [
        thread.title,
        thread.workspaceId,
        thread.taskId,
        thread.knowledgeId,
        thread.updatedAt.toUtc().toIso8601String(),
        thread.archivedAt?.toUtc().toIso8601String(),
        thread.id,
      ],
    );
    if (updated != 1) throw StateError('AI thread not found: ${thread.id}');
  }
}

class SqliteAIMessageRepository implements AIMessageRepository {
  const SqliteAIMessageRepository(this.db);

  final WorkbenchSqlExecutor db;

  @override
  Future<List<AIMessageModel>> listByThread(String threadId) async {
    final rows = await db.select(
      '''
SELECT * FROM ai_messages
WHERE thread_id = ?
ORDER BY created_at ASC
''',
      [threadId],
    );
    return rows.map(_messageFromRow).toList(growable: false);
  }

  @override
  Future<void> insert(AIMessageModel message) async {
    await db.insert(
      '''
INSERT INTO ai_messages (
  id, thread_id, role, content, context_snapshot_json, created_at
) VALUES (?, ?, ?, ?, ?, ?)
''',
      [
        message.id,
        message.threadId,
        message.role,
        message.content,
        message.contextSnapshotJson,
        message.createdAt.toUtc().toIso8601String(),
      ],
    );
  }
}

AIThreadModel _threadFromRow(Map<String, Object?> row) {
  return AIThreadModel(
    id: row['id']! as String,
    scope: AIContextScope.fromValue(row['scope']! as String),
    title: row['title']! as String,
    workspaceId: row['workspace_id'] as String?,
    taskId: row['task_id'] as String?,
    knowledgeId: row['knowledge_id'] as String?,
    createdAt: DateTime.parse(row['created_at']! as String),
    updatedAt: DateTime.parse(row['updated_at']! as String),
    archivedAt: row['archived_at'] == null
        ? null
        : DateTime.parse(row['archived_at']! as String),
  );
}

AIMessageModel _messageFromRow(Map<String, Object?> row) {
  return AIMessageModel(
    id: row['id']! as String,
    threadId: row['thread_id']! as String,
    role: row['role']! as String,
    content: row['content']! as String,
    contextSnapshotJson: row['context_snapshot_json']! as String,
    createdAt: DateTime.parse(row['created_at']! as String),
  );
}
