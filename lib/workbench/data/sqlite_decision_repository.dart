import '../core/models.dart';
import '../core/workbench_database.dart';
import '../domain/decision_repository.dart';

class SqliteDecisionRepository implements DecisionRepository {
  const SqliteDecisionRepository(this.db);

  final WorkbenchSqlExecutor db;

  @override
  Future<List<DecisionModel>> listByWorkspace(String workspaceId) async {
    final rows = await db.select(
      '''
SELECT * FROM decisions
WHERE workspace_id = ? AND archived_at IS NULL
ORDER BY
  CASE status
    WHEN 'active' THEN 0
    WHEN 'superseded' THEN 1
    ELSE 2
  END,
  updated_at DESC
''',
      [workspaceId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<DecisionModel?> getById(String id) async {
    final rows = await db.select('SELECT * FROM decisions WHERE id = ? LIMIT 1', [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<List<DecisionModel>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await db.select(
      '''
SELECT * FROM decisions
WHERE id IN ($placeholders) AND archived_at IS NULL
ORDER BY updated_at DESC
''',
      ids,
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> insert(DecisionModel decision) async {
    await db.insert(
      '''
INSERT INTO decisions (
  id, workspace_id, title, decision_text, rationale, revisit_condition,
  status, created_at, updated_at, archived_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        decision.id,
        decision.workspaceId,
        decision.title,
        decision.decisionText,
        decision.rationale,
        decision.revisitCondition,
        decision.status,
        decision.createdAt.toUtc().toIso8601String(),
        decision.updatedAt.toUtc().toIso8601String(),
        decision.archivedAt?.toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<void> update(DecisionModel decision) async {
    final count = await db.update(
      '''
UPDATE decisions
SET title = ?, decision_text = ?, rationale = ?, revisit_condition = ?,
    status = ?, updated_at = ?, archived_at = ?
WHERE id = ? AND workspace_id = ?
''',
      [
        decision.title,
        decision.decisionText,
        decision.rationale,
        decision.revisitCondition,
        decision.status,
        decision.updatedAt.toUtc().toIso8601String(),
        decision.archivedAt?.toUtc().toIso8601String(),
        decision.id,
        decision.workspaceId,
      ],
    );
    if (count != 1) throw StateError('Decision not found: ${decision.id}');
  }
}

DecisionModel _fromRow(Map<String, Object?> row) {
  DateTime? dateOrNull(Object? value) =>
      value == null ? null : DateTime.parse(value as String).toUtc();

  return DecisionModel(
    id: row['id']! as String,
    workspaceId: row['workspace_id']! as String,
    title: row['title']! as String,
    decisionText: row['decision_text']! as String,
    rationale: row['rationale']! as String,
    revisitCondition: row['revisit_condition']! as String,
    status: row['status']! as String,
    createdAt: DateTime.parse(row['created_at']! as String).toUtc(),
    updatedAt: DateTime.parse(row['updated_at']! as String).toUtc(),
    archivedAt: dateOrNull(row['archived_at']),
  );
}
