import '../core/models.dart';
import '../core/workbench_database.dart';
import '../domain/repositories.dart';

class SqliteFocusSessionRepository implements FocusSessionRepository {
  const SqliteFocusSessionRepository(this.db);

  final WorkbenchSqlExecutor db;

  @override
  Future<FocusSessionModel?> getActive() async {
    final rows = await db.select(
      '''
SELECT * FROM focus_sessions
WHERE ended_at IS NULL
ORDER BY started_at DESC
LIMIT 1
''',
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<List<FocusSessionModel>> listBetween(
    DateTime startInclusive,
    DateTime endExclusive,
  ) async {
    final rows = await db.select(
      '''
SELECT * FROM focus_sessions
WHERE started_at >= ? AND started_at < ?
ORDER BY started_at DESC
''',
      [
        startInclusive.toUtc().toIso8601String(),
        endExclusive.toUtc().toIso8601String(),
      ],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> insert(FocusSessionModel session) async {
    await db.insert(
      '''
INSERT INTO focus_sessions (
  id, workspace_id, task_id, started_at, ended_at,
  duration_seconds, note, created_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        session.id,
        session.workspaceId,
        session.taskId,
        session.startedAt.toUtc().toIso8601String(),
        session.endedAt?.toUtc().toIso8601String(),
        session.durationSeconds,
        session.note,
        session.createdAt.toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<void> finish({
    required String id,
    required DateTime endedAt,
    required int durationSeconds,
    String note = '',
  }) async {
    final count = await db.update(
      '''
UPDATE focus_sessions
SET ended_at = ?, duration_seconds = ?, note = ?
WHERE id = ? AND ended_at IS NULL
''',
      [
        endedAt.toUtc().toIso8601String(),
        durationSeconds,
        note.trim(),
        id,
      ],
    );
    if (count != 1) {
      throw StateError('Focus session not found or already ended: $id');
    }
  }

  FocusSessionModel _fromRow(Map<String, Object?> row) {
    return FocusSessionModel(
      id: row['id']! as String,
      workspaceId: row['workspace_id']! as String,
      taskId: row['task_id']! as String,
      startedAt: DateTime.parse(row['started_at']! as String),
      endedAt: row['ended_at'] == null
          ? null
          : DateTime.parse(row['ended_at']! as String),
      durationSeconds: (row['duration_seconds'] as num).toInt(),
      note: row['note']! as String,
      createdAt: DateTime.parse(row['created_at']! as String),
    );
  }
}
