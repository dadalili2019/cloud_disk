import '../core/models.dart';
import '../core/workbench_database.dart';
import '../domain/search_repository.dart';

class SqliteSearchIndexRepository implements SearchIndexRepository {
  const SqliteSearchIndexRepository(this.db);

  final WorkbenchSqlExecutor db;

  @override
  Future<void> clear() => db.delete('DELETE FROM search_index').then((_) {});

  @override
  Future<void> replace({
    required String entityType,
    required String entityId,
    String? workspaceId,
    required String title,
    required String body,
  }) async {
    await remove(entityType: entityType, entityId: entityId);
    await db.insert(
      '''
INSERT INTO search_index (
  entity_type, entity_id, workspace_id, title, body
) VALUES (?, ?, ?, ?, ?)
''',
      [entityType, entityId, workspaceId ?? '', title, body],
    );
  }

  @override
  Future<void> remove({
    required String entityType,
    required String entityId,
  }) async {
    await db.delete(
      'DELETE FROM search_index WHERE entity_type = ? AND entity_id = ?',
      [entityType, entityId],
    );
  }

  @override
  Future<List<SearchResultModel>> search(
    String query, {
    Set<String>? entityTypes,
    String? workspaceId,
    int limit = 50,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return const [];

    final safeLimit = limit.clamp(1, 100);
    final filters = <String>[];
    final filterArgs = <Object?>[];

    if (entityTypes != null && entityTypes.isNotEmpty) {
      final placeholders = List.filled(entityTypes.length, '?').join(', ');
      filters.add('entity_type IN ($placeholders)');
      filterArgs.addAll(entityTypes);
    }
    if (workspaceId != null && workspaceId.trim().isNotEmpty) {
      filters.add('workspace_id = ?');
      filterArgs.add(workspaceId.trim());
    }

    final whereSuffix = filters.isEmpty ? '' : ' AND ${filters.join(' AND ')}';
    final ftsQuery = _toFtsQuery(normalized);

    if (ftsQuery.isNotEmpty) {
      try {
        final rows = await db.select(
          '''
SELECT entity_type, entity_id, workspace_id, title,
       snippet(search_index, 4, '[', ']', ' … ', 18) AS snippet,
       -bm25(search_index) AS score
FROM search_index
WHERE search_index MATCH ?$whereSuffix
ORDER BY bm25(search_index), title
LIMIT ?
''',
          [ftsQuery, ...filterArgs, safeLimit],
        );
        if (rows.isNotEmpty) return rows.map(_searchResultFromRow).toList();
      } catch (_) {
        // Some punctuation-heavy or CJK queries can be awkward for FTS syntax.
        // Fall through to LIKE so search remains useful rather than failing hard.
      }
    }

    final like = '%${_escapeLike(normalized)}%';
    final rows = await db.select(
      '''
SELECT entity_type, entity_id, workspace_id, title,
       substr(body, 1, 220) AS snippet,
       CASE
         WHEN title LIKE ? ESCAPE '\\' THEN 2.0
         ELSE 1.0
       END AS score
FROM search_index
WHERE (title LIKE ? ESCAPE '\\' OR body LIKE ? ESCAPE '\\')$whereSuffix
ORDER BY score DESC, title
LIMIT ?
''',
      [like, like, like, ...filterArgs, safeLimit],
    );
    return rows.map(_searchResultFromRow).toList();
  }
}

String _toFtsQuery(String query) {
  final terms = query
      .split(RegExp(r'\s+'))
      .map((term) => term.trim())
      .where((term) => term.isNotEmpty)
      .map((term) => '"${term.replaceAll('"', '""')}"')
      .toList();
  return terms.join(' AND ');
}

String _escapeLike(String value) {
  return value
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');
}

SearchResultModel _searchResultFromRow(Map<String, Object?> row) {
  final rawScore = row['score'];
  final score = rawScore is num ? rawScore.toDouble() : 0.0;
  final workspace = row['workspace_id'] as String?;
  return SearchResultModel(
    entityType: row['entity_type']! as String,
    entityId: row['entity_id']! as String,
    title: row['title']! as String,
    snippet: (row['snippet'] as String?) ?? '',
    workspaceId: workspace == null || workspace.isEmpty ? null : workspace,
    score: score,
  );
}
