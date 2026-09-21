import '../core/models.dart';
import '../core/workbench_database.dart';
import '../domain/knowledge_repository.dart';

class SqliteKnowledgeRepository implements KnowledgeRepository {
  const SqliteKnowledgeRepository(this.db);

  final WorkbenchSqlExecutor db;

  @override
  Future<List<KnowledgeModel>> listActive({String? category}) async {
    final normalized = category?.trim();
    final rows = normalized == null || normalized.isEmpty
        ? await db.select(
            '''
SELECT * FROM knowledge
WHERE archived_at IS NULL
ORDER BY is_pinned DESC, updated_at DESC
''',
          )
        : await db.select(
            '''
SELECT * FROM knowledge
WHERE archived_at IS NULL AND category = ?
ORDER BY is_pinned DESC, updated_at DESC
''',
            [normalized],
          );
    return rows.map(_knowledgeFromRow).toList();
  }

  @override
  Future<KnowledgeModel?> getById(String id) async {
    final rows = await db.select(
      'SELECT * FROM knowledge WHERE id = ? LIMIT 1',
      [id],
    );
    return rows.isEmpty ? null : _knowledgeFromRow(rows.first);
  }

  @override
  Future<List<KnowledgeModel>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await db.select(
      '''
SELECT * FROM knowledge
WHERE id IN ($placeholders) AND archived_at IS NULL
ORDER BY is_pinned DESC, updated_at DESC
''',
      ids,
    );
    return rows.map(_knowledgeFromRow).toList();
  }

  @override
  Future<void> insert(KnowledgeModel knowledge) async {
    await db.insert(
      '''
INSERT INTO knowledge (
  id, title, category, summary, use_when, file_path, is_pinned,
  created_at, updated_at, archived_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        knowledge.id,
        knowledge.title,
        knowledge.category,
        knowledge.summary,
        knowledge.useWhen,
        knowledge.filePath,
        knowledge.isPinned ? 1 : 0,
        knowledge.createdAt.toUtc().toIso8601String(),
        knowledge.updatedAt.toUtc().toIso8601String(),
        knowledge.archivedAt?.toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<void> delete(String id) async {
    await db.delete(
      'DELETE FROM knowledge WHERE id = ?',
      [id],
    );
  }

  @override
  Future<void> update(KnowledgeModel knowledge) async {
    final count = await db.update(
      '''
UPDATE knowledge
SET title = ?, category = ?, summary = ?, use_when = ?, file_path = ?,
    is_pinned = ?, updated_at = ?, archived_at = ?
WHERE id = ?
''',
      [
        knowledge.title,
        knowledge.category,
        knowledge.summary,
        knowledge.useWhen,
        knowledge.filePath,
        knowledge.isPinned ? 1 : 0,
        knowledge.updatedAt.toUtc().toIso8601String(),
        knowledge.archivedAt?.toUtc().toIso8601String(),
        knowledge.id,
      ],
    );
    if (count != 1) throw StateError('Knowledge not found: ${knowledge.id}');
  }
}

KnowledgeModel _knowledgeFromRow(Map<String, Object?> row) {
  return KnowledgeModel(
    id: row['id']! as String,
    title: row['title']! as String,
    category: row['category']! as String,
    summary: row['summary']! as String,
    useWhen: row['use_when']! as String,
    filePath: row['file_path']! as String,
    isPinned: (row['is_pinned']! as int) == 1,
    createdAt: DateTime.parse(row['created_at']! as String).toUtc(),
    updatedAt: DateTime.parse(row['updated_at']! as String).toUtc(),
    archivedAt: _dateOrNull(row['archived_at']),
  );
}

DateTime? _dateOrNull(Object? value) {
  if (value == null) return null;
  return DateTime.parse(value as String).toUtc();
}
