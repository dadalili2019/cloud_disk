import '../core/models.dart';
import '../core/workbench_utils.dart';
import '../domain/repositories.dart';
import '../domain/resource_repository.dart';

class ResourceService {
  const ResourceService({
    required this.resources,
    required this.tasks,
    required this.links,
    required this.activities,
  });

  final ResourceRepository resources;
  final TaskRepository tasks;
  final EntityLinkRepository links;
  final ActivityRepository activities;

  Future<List<ResourceModel>> listByWorkspace(String workspaceId) =>
      resources.listByWorkspace(workspaceId);

  Future<TaskModel?> currentTask(String workspaceId) =>
      tasks.getCurrent(workspaceId);

  Future<List<TaskModel>> linkedTasks(ResourceModel resource) async {
    final ids = await links.listToIds(
      fromType: 'resource',
      fromId: resource.id,
      relationType: 'supports',
      toType: 'task',
    );
    final result = <TaskModel>[];
    for (final id in ids) {
      final task = await tasks.getById(id);
      if (task != null) result.add(task);
    }
    return result;
  }

  Future<void> linkToCurrentTask(ResourceModel resource) async {
    final currentTask = await tasks.getCurrent(resource.workspaceId);
    if (currentTask == null) {
      throw StateError('当前工作区暂无当前任务，无法建立关联。');
    }
    final now = DateTime.now().toUtc();
    await links.link(
      id: newWorkbenchId(),
      fromType: 'resource',
      fromId: resource.id,
      relationType: 'supports',
      toType: 'task',
      toId: currentTask.id,
      createdAt: now,
    );
    await activities.insert(
      ActivityEventModel(
        id: newWorkbenchId(),
        workspaceId: resource.workspaceId,
        entityType: 'resource',
        entityId: resource.id,
        eventType: 'resource_linked_task',
        summary: '${resource.name} → ${currentTask.title}',
        createdAt: now,
      ),
    );
  }

  Future<ResourceModel> create({
    required String workspaceId,
    required String name,
    required String resourceType,
    String uri = '',
    String description = '',
    bool isPinned = false,
    bool linkToCurrentTask = true,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Resource name is required.');
    }
    const allowed = {
      'repository', 'local_path', 'document', 'service',
      'link', 'design', 'command', 'other'
    };
    if (!allowed.contains(resourceType)) {
      throw ArgumentError.value(resourceType, 'resourceType', 'Unsupported resource type.');
    }

    final now = DateTime.now().toUtc();
    final resource = ResourceModel(
      id: newWorkbenchId(),
      workspaceId: workspaceId,
      name: trimmed,
      resourceType: resourceType,
      uri: uri.trim(),
      description: description.trim(),
      isPinned: isPinned,
      createdAt: now,
      updatedAt: now,
    );
    await resources.insert(resource);

    if (linkToCurrentTask) {
      final current = await tasks.getCurrent(workspaceId);
      if (current != null) {
        await links.link(
          id: newWorkbenchId(),
          fromType: 'resource',
          fromId: resource.id,
          relationType: 'supports',
          toType: 'task',
          toId: current.id,
          createdAt: now,
        );
      }
    }

    await activities.insert(
      ActivityEventModel(
        id: newWorkbenchId(),
        workspaceId: workspaceId,
        entityType: 'resource',
        entityId: resource.id,
        eventType: 'resource_created',
        summary: resource.name,
        createdAt: now,
      ),
    );
    return resource;
  }

  Future<ResourceModel> update({
    required ResourceModel resource,
    required String name,
    required String resourceType,
    required String uri,
    required String description,
    required bool isPinned,
  }) async {
    final updated = ResourceModel(
      id: resource.id,
      workspaceId: resource.workspaceId,
      name: name.trim(),
      resourceType: resourceType,
      uri: uri.trim(),
      description: description.trim(),
      isPinned: isPinned,
      createdAt: resource.createdAt,
      updatedAt: DateTime.now().toUtc(),
      archivedAt: resource.archivedAt,
    );
    await resources.update(updated);
    await activities.insert(
      ActivityEventModel(
        id: newWorkbenchId(),
        workspaceId: resource.workspaceId,
        entityType: 'resource',
        entityId: resource.id,
        eventType: 'resource_updated',
        summary: updated.name,
        createdAt: updated.updatedAt,
      ),
    );
    return updated;
  }
}
