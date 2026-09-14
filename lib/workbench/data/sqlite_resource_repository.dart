import '../core/models.dart';
import '../core/workbench_database.dart';
import '../domain/resource_repository.dart';

class SqliteResourceRepository implements ResourceRepository {
  const SqliteResourceRepository(this.db);

  final WorkbenchSqlExecutor db;

  @override
  Future<List<ResourceModel>> listByWorkspace(String workspaceId) async {
    final rows = await db.select(
      '''
SELECT * FROM resources
WHERE workspace_id = ? AND archived_at IS NULL
ORDER BY is_pinned DESC, updated_at DESC
''',
      [workspaceId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<ResourceModel?> getById(String id) async {
    final rows = await db.select(
      'SELECT * FROM resources WHERE id = ? LIMIT 1',
      [id],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<List<ResourceModel>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await db.select(
      '''
SELECT * FROM resources
WHERE id IN ($placeholders) AND archived_at IS NULL
ORDER BY is_pinned DESC, updated_at DESC
''',
      ids,
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> insert(ResourceModel resource) async {
    await db.insert(
      '''
INSERT INTO resources (
  id, workspace_id, name, resource_type, uri, description, is_pinned,
  created_at, updated_at, archived_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        resource.id,
        resource.workspaceId,
        resource.name,
        resource.resourceType,
        resource.uri,
        resource.description,
        resource.isPinned ? 1 : 0,
        resource.createdAt.toUtc().toIso8601String(),
        resource.updatedAt.toUtc().toIso8601String(),
        resource.archivedAt?.toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<void> update(ResourceModel resource) async {
    final count = await db.update(
      '''
UPDATE resources
SET name = ?, resource_type = ?, uri = ?, description = ?, is_pinned = ?,
    updated_at = ?, archived_at = ?
WHERE id = ? AND workspace_id = ?
''',
      [
        resource.name,
        resource.resourceType,
        resource.uri,
        resource.description,
        resource.isPinned ? 1 : 0,
        resource.updatedAt.toUtc().toIso8601String(),
        resource.archivedAt?.toUtc().toIso8601String(),
        resource.id,
        resource.workspaceId,
      ],
    );
    if (count != 1) {
      throw StateError('Resource not found: ${resource.id}');
    }
  }
}

ResourceModel _fromRow(Map<String, Object?> row) {
  DateTime? dateOrNull(Object? value) {
    if (value == null) return null;
    return DateTime.parse(value as String).toUtc();
  }

  return ResourceModel(
    id: row['id']! as String,
    workspaceId: row['workspace_id']! as String,
    name: row['name']! as String,
    resourceType: row['resource_type']! as String,
    uri: row['uri']! as String,
    description: row['description']! as String,
    isPinned: (row['is_pinned']! as int) == 1,
    createdAt: DateTime.parse(row['created_at']! as String).toUtc(),
    updatedAt: DateTime.parse(row['updated_at']! as String).toUtc(),
    archivedAt: dateOrNull(row['archived_at']),
  );
}
