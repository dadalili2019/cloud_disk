import '../core/developer_models.dart';
import '../core/workbench_database.dart';
import '../domain/developer_project_repository.dart';

class SqliteDeveloperProjectRepository implements DeveloperProjectRepository {
  const SqliteDeveloperProjectRepository(this.db);

  final WorkbenchSqlExecutor db;

  @override
  Future<List<DeveloperProjectModel>> listByWorkspace(String workspaceId) async {
    final rows = await db.select(
      '''
SELECT * FROM developer_projects
WHERE workspace_id = ? AND archived_at IS NULL
ORDER BY is_primary DESC, updated_at DESC
''',
      [workspaceId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<DeveloperProjectModel?> getById(String id) async {
    final rows = await db.select(
      'SELECT * FROM developer_projects WHERE id = ? LIMIT 1',
      [id],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<DeveloperProjectModel?> getPrimary(String workspaceId) async {
    final rows = await db.select(
      '''
SELECT * FROM developer_projects
WHERE workspace_id = ? AND is_primary = 1 AND archived_at IS NULL
LIMIT 1
''',
      [workspaceId],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<List<DeveloperProjectModel>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await db.select(
      '''
SELECT * FROM developer_projects
WHERE id IN ($placeholders) AND archived_at IS NULL
ORDER BY is_primary DESC, updated_at DESC
''',
      ids,
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> insert(DeveloperProjectModel project) async {
    await db.insert(
      '''
INSERT INTO developer_projects (
  id, workspace_id, name, local_path, repository_url, branch, tech_stack,
  notes, is_primary, created_at, updated_at, archived_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        project.id,
        project.workspaceId,
        project.name,
        project.localPath,
        project.repositoryUrl,
        project.branch,
        project.techStack,
        project.notes,
        project.isPrimary ? 1 : 0,
        project.createdAt.toUtc().toIso8601String(),
        project.updatedAt.toUtc().toIso8601String(),
        project.archivedAt?.toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<void> update(DeveloperProjectModel project) async {
    final count = await db.update(
      '''
UPDATE developer_projects
SET name = ?, local_path = ?, repository_url = ?, branch = ?, tech_stack = ?,
    notes = ?, is_primary = ?, updated_at = ?, archived_at = ?
WHERE id = ? AND workspace_id = ?
''',
      [
        project.name,
        project.localPath,
        project.repositoryUrl,
        project.branch,
        project.techStack,
        project.notes,
        project.isPrimary ? 1 : 0,
        project.updatedAt.toUtc().toIso8601String(),
        project.archivedAt?.toUtc().toIso8601String(),
        project.id,
        project.workspaceId,
      ],
    );
    if (count != 1) {
      throw StateError('Developer project not found: ${project.id}');
    }
  }
}

DeveloperProjectModel _fromRow(Map<String, Object?> row) {
  DateTime? dateOrNull(Object? value) {
    if (value == null) return null;
    return DateTime.parse(value as String).toUtc();
  }

  return DeveloperProjectModel(
    id: row['id']! as String,
    workspaceId: row['workspace_id']! as String,
    name: row['name']! as String,
    localPath: row['local_path']! as String,
    repositoryUrl: row['repository_url']! as String,
    branch: row['branch']! as String,
    techStack: row['tech_stack']! as String,
    notes: row['notes']! as String,
    isPrimary: (row['is_primary']! as int) == 1,
    createdAt: DateTime.parse(row['created_at']! as String).toUtc(),
    updatedAt: DateTime.parse(row['updated_at']! as String).toUtc(),
    archivedAt: dateOrNull(row['archived_at']),
  );
}
