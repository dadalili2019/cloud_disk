import '../core/models.dart';
import '../core/workbench_utils.dart';
import '../domain/repositories.dart';

class WorkspaceAdminService {
  const WorkspaceAdminService({
    required this.workspaces,
    required this.activities,
  });

  final WorkspaceRepository workspaces;
  final ActivityRepository activities;

  Future<List<WorkspaceModel>> listArchived() => workspaces.listArchived();

  Future<WorkspaceModel?> getById(String workspaceId) =>
      workspaces.getById(workspaceId);

  Future<WorkspaceModel> rename({
    required WorkspaceModel workspace,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', '工作区名称不能为空。');
    }

    final now = DateTime.now().toUtc();
    final updated = WorkspaceModel(
      id: workspace.id,
      name: trimmed,
      slug: workspace.slug,
      status: workspace.status,
      createdAt: workspace.createdAt,
      updatedAt: now,
      archivedAt: workspace.archivedAt,
    );
    await workspaces.update(updated);
    await activities.insert(
      ActivityEventModel(
        id: newWorkbenchId(),
        workspaceId: workspace.id,
        entityType: 'workspace',
        entityId: workspace.id,
        eventType: 'workspace_renamed',
        summary: updated.name,
        createdAt: now,
      ),
    );
    return updated;
  }

  Future<WorkspaceModel> archive(WorkspaceModel workspace) async {
    final now = DateTime.now().toUtc();
    final updated = WorkspaceModel(
      id: workspace.id,
      name: workspace.name,
      slug: workspace.slug,
      status: 'archived',
      createdAt: workspace.createdAt,
      updatedAt: now,
      archivedAt: now,
    );
    await workspaces.update(updated);
    await activities.insert(
      ActivityEventModel(
        id: newWorkbenchId(),
        workspaceId: workspace.id,
        entityType: 'workspace',
        entityId: workspace.id,
        eventType: 'workspace_archived',
        summary: workspace.name,
        createdAt: now,
      ),
    );
    return updated;
  }

  Future<WorkspaceModel> restore(WorkspaceModel workspace) async {
    final now = DateTime.now().toUtc();
    final updated = WorkspaceModel(
      id: workspace.id,
      name: workspace.name,
      slug: workspace.slug,
      status: 'active',
      createdAt: workspace.createdAt,
      updatedAt: now,
      archivedAt: null,
    );
    await workspaces.update(updated);
    await activities.insert(
      ActivityEventModel(
        id: newWorkbenchId(),
        workspaceId: workspace.id,
        entityType: 'workspace',
        entityId: workspace.id,
        eventType: 'workspace_restored',
        summary: workspace.name,
        createdAt: now,
      ),
    );
    return updated;
  }
}
