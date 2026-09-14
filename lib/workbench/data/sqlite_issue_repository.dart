import '../core/models.dart';
import '../core/workbench_database.dart';
import '../domain/issue_repository.dart';

class SqliteIssueRepository implements IssueRepository {
  const SqliteIssueRepository(this.db);

  final WorkbenchSqlExecutor db;

  @override
  Future<List<IssueModel>> listByWorkspace(String workspaceId) async {
    final rows = await db.select(
      '''
SELECT * FROM issues
WHERE workspace_id = ? AND archived_at IS NULL
ORDER BY
  CASE status
    WHEN 'open' THEN 0
    WHEN 'investigating' THEN 1
    WHEN 'resolved' THEN 2
    ELSE 3
  END,
  updated_at DESC
''',
      [workspaceId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<IssueModel?> getById(String id) async {
    final rows = await db.select(
      'SELECT * FROM issues WHERE id = ? LIMIT 1',
      [id],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<List<IssueModel>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await db.select(
      '''
SELECT * FROM issues
WHERE id IN ($placeholders) AND archived_at IS NULL
ORDER BY updated_at DESC
''',
      ids,
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> insert(IssueModel issue) async {
    await db.insert(
      '''
INSERT INTO issues (
  id, workspace_id, title, status, severity, impact, hypothesis,
  next_investigation_step, resolution, created_at, updated_at, archived_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        issue.id,
        issue.workspaceId,
        issue.title,
        issue.status,
        issue.severity,
        issue.impact,
        issue.hypothesis,
        issue.nextInvestigationStep,
        issue.resolution,
        issue.createdAt.toUtc().toIso8601String(),
        issue.updatedAt.toUtc().toIso8601String(),
        issue.archivedAt?.toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<void> update(IssueModel issue) async {
    final count = await db.update(
      '''
UPDATE issues
SET title = ?, status = ?, severity = ?, impact = ?, hypothesis = ?,
    next_investigation_step = ?, resolution = ?, updated_at = ?, archived_at = ?
WHERE id = ? AND workspace_id = ?
''',
      [
        issue.title,
        issue.status,
        issue.severity,
        issue.impact,
        issue.hypothesis,
        issue.nextInvestigationStep,
        issue.resolution,
        issue.updatedAt.toUtc().toIso8601String(),
        issue.archivedAt?.toUtc().toIso8601String(),
        issue.id,
        issue.workspaceId,
      ],
    );
    if (count != 1) {
      throw StateError('Issue not found: ${issue.id}');
    }
  }
}

IssueModel _fromRow(Map<String, Object?> row) {
  DateTime? dateOrNull(Object? value) {
    if (value == null) return null;
    return DateTime.parse(value as String).toUtc();
  }

  return IssueModel(
    id: row['id']! as String,
    workspaceId: row['workspace_id']! as String,
    title: row['title']! as String,
    status: row['status']! as String,
    severity: row['severity']! as String,
    impact: row['impact']! as String,
    hypothesis: row['hypothesis']! as String,
    nextInvestigationStep: row['next_investigation_step']! as String,
    resolution: row['resolution']! as String,
    createdAt: DateTime.parse(row['created_at']! as String).toUtc(),
    updatedAt: DateTime.parse(row['updated_at']! as String).toUtc(),
    archivedAt: dateOrNull(row['archived_at']),
  );
}
