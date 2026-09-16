import '../core/developer_models.dart';
import '../core/workbench_database.dart';
import '../domain/developer_command_repository.dart';

class SqliteDeveloperCommandRepository implements DeveloperCommandRepository {
  const SqliteDeveloperCommandRepository(this.db);

  final WorkbenchSqlExecutor db;

  @override
  Future<List<DeveloperCommandModel>> listByWorkspace(String workspaceId) async {
    final rows = await db.select(
      '''
SELECT * FROM developer_commands
WHERE workspace_id = ? AND archived_at IS NULL
ORDER BY is_pinned DESC, updated_at DESC
''',
      [workspaceId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<DeveloperCommandModel>> listByProject(String projectId) async {
    final rows = await db.select(
      '''
SELECT * FROM developer_commands
WHERE project_id = ? AND archived_at IS NULL
ORDER BY is_pinned DESC, updated_at DESC
''',
      [projectId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<DeveloperCommandModel?> getById(String id) async {
    final rows = await db.select(
      'SELECT * FROM developer_commands WHERE id = ? LIMIT 1',
      [id],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<List<DeveloperCommandModel>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await db.select(
      '''
SELECT * FROM developer_commands
WHERE id IN ($placeholders) AND archived_at IS NULL
ORDER BY is_pinned DESC, updated_at DESC
''',
      ids,
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> insert(DeveloperCommandModel command) async {
    await db.insert(
      '''
INSERT INTO developer_commands (
  id, workspace_id, project_id, name, command, working_directory,
  category, notes, is_pinned, created_at, updated_at, archived_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        command.id,
        command.workspaceId,
        command.projectId,
        command.name,
        command.command,
        command.workingDirectory,
        command.category,
        command.notes,
        command.isPinned ? 1 : 0,
        command.createdAt.toUtc().toIso8601String(),
        command.updatedAt.toUtc().toIso8601String(),
        command.archivedAt?.toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<void> update(DeveloperCommandModel command) async {
    final count = await db.update(
      '''
UPDATE developer_commands
SET project_id = ?, name = ?, command = ?, working_directory = ?,
    category = ?, notes = ?, is_pinned = ?, updated_at = ?, archived_at = ?
WHERE id = ? AND workspace_id = ?
''',
      [
        command.projectId,
        command.name,
        command.command,
        command.workingDirectory,
        command.category,
        command.notes,
        command.isPinned ? 1 : 0,
        command.updatedAt.toUtc().toIso8601String(),
        command.archivedAt?.toUtc().toIso8601String(),
        command.id,
        command.workspaceId,
      ],
    );
    if (count != 1) {
      throw StateError('Developer command not found: ${command.id}');
    }
  }
}

DeveloperCommandModel _fromRow(Map<String, Object?> row) {
  DateTime? dateOrNull(Object? value) {
    if (value == null) return null;
    return DateTime.parse(value as String).toUtc();
  }

  return DeveloperCommandModel(
    id: row['id']! as String,
    workspaceId: row['workspace_id']! as String,
    projectId: row['project_id'] as String?,
    name: row['name']! as String,
    command: row['command']! as String,
    workingDirectory: row['working_directory'] as String?,
    category: row['category']! as String,
    notes: row['notes']! as String,
    isPinned: (row['is_pinned']! as int) == 1,
    createdAt: DateTime.parse(row['created_at']! as String).toUtc(),
    updatedAt: DateTime.parse(row['updated_at']! as String).toUtc(),
    archivedAt: dateOrNull(row['archived_at']),
  );
}
