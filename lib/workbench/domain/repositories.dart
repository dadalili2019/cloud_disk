import '../core/models.dart';

abstract interface class WorkspaceRepository {
  Future<List<WorkspaceModel>> listActive();
  Future<WorkspaceModel?> getById(String id);
  Future<WorkspaceModel?> getBySlug(String slug);
  Future<void> insert(WorkspaceModel workspace);
}

abstract interface class TaskRepository {
  Future<List<TaskModel>> listByWorkspace(String workspaceId);
  Future<TaskModel?> getById(String id);
  Future<TaskModel?> getCurrent(String workspaceId);
  Future<void> insert(TaskModel task);
  Future<void> update(TaskModel task);
  Future<void> setCurrent(String workspaceId, String taskId);
}

abstract interface class NoteRepository {
  Future<List<NoteModel>> listByWorkspace(String workspaceId);
  Future<NoteModel?> getById(String id);
  Future<List<NoteModel>> getByIds(List<String> ids);
  Future<void> insert(NoteModel note);
  Future<void> touchUpdatedAt(String noteId, DateTime updatedAt);
}

abstract interface class EntityLinkRepository {
  Future<void> link({
    required String id,
    required String fromType,
    required String fromId,
    required String relationType,
    required String toType,
    required String toId,
    required DateTime createdAt,
  });

  Future<List<String>> listFromIds({
    required String toType,
    required String toId,
    required String relationType,
    required String fromType,
  });

  Future<List<String>> listToIds({
    required String fromType,
    required String fromId,
    required String relationType,
    required String toType,
  });
}

abstract interface class ActivityRepository {
  Future<void> insert(ActivityEventModel event);
  Future<List<ActivityEventModel>> listRecent(
    String workspaceId, {
    int limit = 10,
  });
}
