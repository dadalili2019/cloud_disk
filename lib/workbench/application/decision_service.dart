import '../core/models.dart';
import '../core/workbench_utils.dart';
import '../domain/decision_repository.dart';
import '../domain/repositories.dart';

class DecisionService {
  const DecisionService({
    required this.decisions,
    required this.tasks,
    required this.links,
    required this.activities,
  });

  final DecisionRepository decisions;
  final TaskRepository tasks;
  final EntityLinkRepository links;
  final ActivityRepository activities;

  Future<List<DecisionModel>> listByWorkspace(String workspaceId) =>
      decisions.listByWorkspace(workspaceId);

  Future<TaskModel?> currentTask(String workspaceId) => tasks.getCurrent(workspaceId);

  Future<List<TaskModel>> linkedTasks(DecisionModel decision) async {
    final ids = await links.listToIds(
      fromType: 'decision',
      fromId: decision.id,
      relationType: 'applies_to',
      toType: 'task',
    );
    final result = <TaskModel>[];
    for (final id in ids) {
      final task = await tasks.getById(id);
      if (task != null) result.add(task);
    }
    return result;
  }

  Future<void> linkToCurrentTask(DecisionModel decision) async {
    final currentTask = await tasks.getCurrent(decision.workspaceId);
    if (currentTask == null) {
      throw StateError('当前工作区暂无当前任务，无法建立关联。');
    }
    final now = DateTime.now().toUtc();
    await links.link(
      id: newWorkbenchId(),
      fromType: 'decision',
      fromId: decision.id,
      relationType: 'applies_to',
      toType: 'task',
      toId: currentTask.id,
      createdAt: now,
    );
    await activities.insert(
      ActivityEventModel(
        id: newWorkbenchId(),
        workspaceId: decision.workspaceId,
        entityType: 'decision',
        entityId: decision.id,
        eventType: 'decision_linked_task',
        summary: '${decision.title} → ${currentTask.title}',
        createdAt: now,
      ),
    );
  }

  Future<DecisionModel> create({
    required String workspaceId,
    required String title,
    required String decisionText,
    String rationale = '',
    String revisitCondition = '',
    bool linkToCurrentTask = true,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Decision title is required.');
    }
    final trimmedDecision = decisionText.trim();
    if (trimmedDecision.isEmpty) {
      throw ArgumentError.value(decisionText, 'decisionText', 'Decision text is required.');
    }

    final now = DateTime.now().toUtc();
    final decision = DecisionModel(
      id: newWorkbenchId(),
      workspaceId: workspaceId,
      title: trimmedTitle,
      decisionText: trimmedDecision,
      rationale: rationale.trim(),
      revisitCondition: revisitCondition.trim(),
      status: 'active',
      createdAt: now,
      updatedAt: now,
    );
    await decisions.insert(decision);

    if (linkToCurrentTask) {
      final current = await tasks.getCurrent(workspaceId);
      if (current != null) {
        await links.link(
          id: newWorkbenchId(),
          fromType: 'decision',
          fromId: decision.id,
          relationType: 'applies_to',
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
        entityType: 'decision',
        entityId: decision.id,
        eventType: 'decision_created',
        summary: decision.title,
        createdAt: now,
      ),
    );
    return decision;
  }

  Future<DecisionModel> update({
    required DecisionModel decision,
    required String title,
    required String decisionText,
    required String rationale,
    required String revisitCondition,
    required String status,
  }) async {
    if (!const {'active', 'superseded', 'archived'}.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Unsupported decision status.');
    }
    final now = DateTime.now().toUtc();
    final updated = DecisionModel(
      id: decision.id,
      workspaceId: decision.workspaceId,
      title: title.trim(),
      decisionText: decisionText.trim(),
      rationale: rationale.trim(),
      revisitCondition: revisitCondition.trim(),
      status: status,
      createdAt: decision.createdAt,
      updatedAt: now,
      archivedAt: status == 'archived' ? now : decision.archivedAt,
    );
    await decisions.update(updated);
    await activities.insert(
      ActivityEventModel(
        id: newWorkbenchId(),
        workspaceId: decision.workspaceId,
        entityType: 'decision',
        entityId: decision.id,
        eventType: 'decision_updated',
        summary: updated.title,
        createdAt: now,
      ),
    );
    return updated;
  }
}
