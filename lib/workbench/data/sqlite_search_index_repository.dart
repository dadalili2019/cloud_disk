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

    final safeLimit = limit.clamp(1, 100).toInt();
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
    final merged = <String, SearchResultModel>{};
    final resultOrder = <String>[];
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
        for (final row in rows) {
          final result = _searchResultFromRow(row);
          final key = _resultKey(result);
          if (!merged.containsKey(key)) {
            merged[key] = result;
            resultOrder.add(key);
          }
        }
      } catch (_) {
        // FTS may reject punctuation-heavy or some CJK queries.
        // LIKE below still guarantees a useful fallback path.
      }
    }

    // Always supplement FTS with substring matching. FTS token matching is
    // intentionally strict, so a query such as "123" would otherwise miss
    // titles like "12323213" once any exact-token FTS result exists.
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

    for (final row in rows) {
      final result = _searchResultFromRow(row);
      final key = _resultKey(result);
      if (!merged.containsKey(key)) {
        merged[key] = result;
        resultOrder.add(key);
      }
    }

    return resultOrder
        .take(safeLimit)
        .map((key) => merged[key]!)
        .toList(growable: false);
  }
}

String _resultKey(SearchResultModel result) =>
    '${result.entityType}:${result.entityId}';

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
