import '../core/app_paths.dart';
import '../core/models.dart';
import '../core/workbench_utils.dart';
import '../data/markdown_store.dart';
import '../domain/repositories.dart';

class WorkspaceService {
  const WorkspaceService({
    required this.paths,
    required this.workspaces,
    required this.activities,
  });

  final AppPaths paths;
  final WorkspaceRepository workspaces;
  final ActivityRepository activities;

  Future<List<WorkspaceModel>> listActive() => workspaces.listActive();

  Future<WorkspaceModel?> getById(String id) => workspaces.getById(id);

  Future<WorkspaceModel> create({
    required String name,
    String? slug,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Workspace name is required.');
    }

    final resolvedSlug = slugifyWorkspace(
      slug?.trim().isNotEmpty == true ? slug!.trim() : trimmedName,
    );
    final existing = await workspaces.getBySlug(resolvedSlug);
    if (existing != null) {
      throw StateError('Workspace slug already exists: $resolvedSlug');
    }

    final now = DateTime.now().toUtc();
    final workspace = WorkspaceModel(
      id: newWorkbenchId(),
      name: trimmedName,
      slug: resolvedSlug,
      status: 'active',
      createdAt: now,
      updatedAt: now,
    );

    await paths.ensureWorkspaceDirectories(resolvedSlug);
    await workspaces.insert(workspace);
    await activities.insert(
      ActivityEventModel(
        id: newWorkbenchId(),
        workspaceId: workspace.id,
        entityType: 'workspace',
        entityId: workspace.id,
        eventType: 'workspace_created',
        summary: 'Created workspace ${workspace.name}',
        createdAt: now,
      ),
    );
    return workspace;
  }
}

class TaskService {
  const TaskService({
    required this.tasks,
    required this.activities,
  });

  final TaskRepository tasks;
  final ActivityRepository activities;

  Future<List<TaskModel>> listByWorkspace(String workspaceId) =>
      tasks.listByWorkspace(workspaceId);

  Future<TaskModel?> getCurrent(String workspaceId) =>
      tasks.getCurrent(workspaceId);

  Future<TaskModel?> getById(String taskId) => tasks.getById(taskId);

  Future<TaskModel> create({
    required String workspaceId,
    required String title,
    String description = '',
    String nextStep = '',
    int priority = 0,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Task title is required.');
    }

    final now = DateTime.now().toUtc();
    final task = TaskModel(
      id: newWorkbenchId(),
      workspaceId: workspaceId,
      title: trimmedTitle,
      description: description.trim(),
      status: 'todo',
      progress: 0,
      nextStep: nextStep.trim(),
      priority: priority,
      isCurrent: false,
      createdAt: now,
      updatedAt: now,
    );

    await tasks.insert(task);
    await activities.insert(
      ActivityEventModel(
        id: newWorkbenchId(),
        workspaceId: workspaceId,
        entityType: 'task',
        entityId: task.id,
        eventType: 'task_created',
        summary: task.title,
        createdAt: now,
      ),
    );
    return task;
  }

  Future<TaskModel> update({
    required TaskModel task,
    required String title,
    required String status,
    required int progress,
    required String nextStep,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Task title is required.');
    }
    if (!const {'todo', 'doing', 'done'}.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Unsupported task status.');
    }
    if (progress < 0 || progress > 100) {
      throw ArgumentError.value(progress, 'progress', 'Progress must be 0-100.');
    }

    var normalizedProgress = progress;
    if (status == 'done') normalizedProgress = 100;

    final now = DateTime.now().toUtc();
    final updatedTask = TaskModel(
      id: task.id,
      workspaceId: task.workspaceId,
      title: trimmedTitle,
      description: task.description,
      status: status,
      progress: normalizedProgress,
      nextStep: nextStep.trim(),
      priority: task.priority,
      isCurrent: status == 'done' ? false : task.isCurrent,
      dueAt: task.dueAt,
      createdAt: task.createdAt,
      updatedAt: now,
      archivedAt: task.archivedAt,
    );

    await tasks.update(updatedTask);
    await activities.insert(
      ActivityEventModel(
        id: newWorkbenchId(),
        workspaceId: task.workspaceId,
        entityType: 'task',
        entityId: task.id,
        eventType: status == 'done' ? 'task_completed' : 'task_updated',
        summary: updatedTask.title,
        createdAt: now,
      ),
    );
    return updatedTask;
  }

  Future<void> setCurrent(String workspaceId, String taskId) async {
    await tasks.setCurrent(workspaceId, taskId);
    final task = await tasks.getById(taskId);
    if (task == null) return;
    await activities.insert(
      ActivityEventModel(
        id: newWorkbenchId(),
        workspaceId: workspaceId,
        entityType: 'task',
        entityId: taskId,
        eventType: 'task_set_current',
        summary: task.title,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }
}

class EntityLinkService {
  const EntityLinkService(this.links);

  final EntityLinkRepository links;

  Future<void> linkNoteToTask(String noteId, String taskId) {
    return links.link(
      id: newWorkbenchId(),
      fromType: 'note',
      fromId: noteId,
      relationType: 'linked_to',
      toType: 'task',
      toId: taskId,
      createdAt: DateTime.now().toUtc(),
    );
  }

  Future<List<String>> linkedNoteIds(String taskId) {
    return links.listFromIds(
      toType: 'task',
      toId: taskId,
      relationType: 'linked_to',
      fromType: 'note',
    );
  }

  Future<List<String>> linkedTaskIds(String noteId) {
    return links.listToIds(
      fromType: 'note',
      fromId: noteId,
      relationType: 'linked_to',
      toType: 'task',
    );
  }
}

class NoteService {
  const NoteService({
    required this.paths,
    required this.store,
    required this.workspaces,
    required this.tasks,
    required this.notes,
    required this.links,
    required this.activities,
  });

  final AppPaths paths;
  final MarkdownStore store;
  final WorkspaceRepository workspaces;
  final TaskRepository tasks;
  final NoteRepository notes;
  final EntityLinkService links;
  final ActivityRepository activities;

  Future<List<NoteModel>> listByWorkspace(String workspaceId) =>
      notes.listByWorkspace(workspaceId);

  Future<String> readContent(NoteModel note) => store.read(note.filePath);

  Future<List<TaskModel>> linkedTasks(NoteModel note) async {
    final ids = await links.linkedTaskIds(note.id);
    if (ids.isEmpty) return const [];
    final result = <TaskModel>[];
    for (final id in ids) {
      final task = await tasks.getById(id);
      if (task != null) result.add(task);
    }
    return result;
  }

  Future<NoteModel> create({
    required String workspaceId,
    required String title,
    String? fileName,
    String initialContent = '',
    bool linkToCurrentTask = true,
  }) async {
    final workspace = await workspaces.getById(workspaceId);
    if (workspace == null) {
      throw StateError('Workspace not found: $workspaceId');
    }

    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Note title is required.');
    }

    await paths.ensureWorkspaceDirectories(workspace.slug);
    final noteId = newWorkbenchId();
    final requestedFileName = normalizeMarkdownFileName(
      fileName ?? '',
      fallbackTitle: trimmedTitle,
    );
    var resolvedFileName = requestedFileName;
    var relativePath = paths.workspaceNoteRelativePath(
      workspace.slug,
      resolvedFileName,
    );

    if (await store.exists(relativePath)) {
      final suffix = noteId.substring(0, 8);
      final stem = requestedFileName.toLowerCase().endsWith('.md')
          ? requestedFileName.substring(0, requestedFileName.length - 3)
          : requestedFileName;
      resolvedFileName = '$stem-$suffix.md';
      relativePath = paths.workspaceNoteRelativePath(
        workspace.slug,
        resolvedFileName,
      );
    }

    final now = DateTime.now().toUtc();
    final note = NoteModel(
      id: noteId,
      workspaceId: workspaceId,
      title: trimmedTitle,
      filePath: relativePath,
      isPinned: false,
      createdAt: now,
      updatedAt: now,
    );

    await store.writeAtomic(relativePath, initialContent);
    try {
      await notes.insert(note);
    } catch (_) {
      await store.deleteIfExists(relativePath);
      rethrow;
    }

    if (linkToCurrentTask) {
      final current = await tasks.getCurrent(workspaceId);
      if (current != null) {
        await links.linkNoteToTask(note.id, current.id);
      }
    }

    await activities.insert(
      ActivityEventModel(
        id: newWorkbenchId(),
        workspaceId: workspaceId,
        entityType: 'note',
        entityId: note.id,
        eventType: 'note_created',
        summary: note.title,
        createdAt: now,
      ),
    );
    return note;
  }

  Future<void> saveContent(NoteModel note, String markdown) async {
    await store.writeAtomic(note.filePath, markdown);
    await notes.touchUpdatedAt(note.id, DateTime.now().toUtc());
  }
}
