import '../core/developer_models.dart';
import '../core/workbench_database.dart';
import '../domain/developer_snippet_repository.dart';

class SqliteDeveloperSnippetRepository implements DeveloperSnippetRepository {
  const SqliteDeveloperSnippetRepository(this.db);

  final WorkbenchSqlExecutor db;

  @override
  Future<List<DeveloperSnippetModel>> listByWorkspace(String workspaceId) async {
    final rows = await db.select(
      '''
SELECT * FROM developer_snippets
WHERE workspace_id = ? AND archived_at IS NULL
ORDER BY is_pinned DESC, updated_at DESC
''',
      [workspaceId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<DeveloperSnippetModel>> listByProject(String projectId) async {
    final rows = await db.select(
      '''
SELECT * FROM developer_snippets
WHERE project_id = ? AND archived_at IS NULL
ORDER BY is_pinned DESC, updated_at DESC
''',
      [projectId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<DeveloperSnippetModel?> getById(String id) async {
    final rows = await db.select(
      'SELECT * FROM developer_snippets WHERE id = ? LIMIT 1',
      [id],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<List<DeveloperSnippetModel>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await db.select(
      '''
SELECT * FROM developer_snippets
WHERE id IN ($placeholders) AND archived_at IS NULL
ORDER BY is_pinned DESC, updated_at DESC
''',
      ids,
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> insert(DeveloperSnippetModel snippet) async {
    await db.insert(
      '''
INSERT INTO developer_snippets (
  id, workspace_id, project_id, title, language, content, notes,
  is_pinned, created_at, updated_at, archived_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        snippet.id,
        snippet.workspaceId,
        snippet.projectId,
        snippet.title,
        snippet.language,
        snippet.content,
        snippet.notes,
        snippet.isPinned ? 1 : 0,
        snippet.createdAt.toUtc().toIso8601String(),
        snippet.updatedAt.toUtc().toIso8601String(),
        snippet.archivedAt?.toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<void> update(DeveloperSnippetModel snippet) async {
    final count = await db.update(
      '''
UPDATE developer_snippets
SET project_id = ?, title = ?, language = ?, content = ?, notes = ?,
    is_pinned = ?, updated_at = ?, archived_at = ?
WHERE id = ? AND workspace_id = ?
''',
      [
        snippet.projectId,
        snippet.title,
        snippet.language,
        snippet.content,
        snippet.notes,
        snippet.isPinned ? 1 : 0,
        snippet.updatedAt.toUtc().toIso8601String(),
        snippet.archivedAt?.toUtc().toIso8601String(),
        snippet.id,
        snippet.workspaceId,
      ],
    );
    if (count != 1) {
      throw StateError('Developer snippet not found: ${snippet.id}');
    }
  }
}

DeveloperSnippetModel _fromRow(Map<String, Object?> row) {
  DateTime? dateOrNull(Object? value) {
    if (value == null) return null;
    return DateTime.parse(value as String).toUtc();
  }

  return DeveloperSnippetModel(
    id: row['id']! as String,
    workspaceId: row['workspace_id']! as String,
    projectId: row['project_id'] as String?,
    title: row['title']! as String,
    language: row['language']! as String,
    content: row['content']! as String,
    notes: row['notes']! as String,
    isPinned: (row['is_pinned']! as int) == 1,
    createdAt: DateTime.parse(row['created_at']! as String).toUtc(),
    updatedAt: DateTime.parse(row['updated_at']! as String).toUtc(),
    archivedAt: dateOrNull(row['archived_at']),
  );
}
