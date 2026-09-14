import '../core/models.dart';
import '../core/workbench_utils.dart';
import '../domain/issue_repository.dart';
import '../domain/repositories.dart';

class IssueService {
  const IssueService({
    required this.issues,
    required this.tasks,
    required this.links,
    required this.activities,
  });

  final IssueRepository issues;
  final TaskRepository tasks;
  final EntityLinkRepository links;
  final ActivityRepository activities;

  Future<List<IssueModel>> listByWorkspace(String workspaceId) =>
      issues.listByWorkspace(workspaceId);

  Future<TaskModel?> currentTask(String workspaceId) =>
      tasks.getCurrent(workspaceId);

  Future<List<IssueModel>> linkedToTask(String taskId) async {
    final ids = await links.listFromIds(
      toType: 'task',
      toId: taskId,
      relationType: 'blocks',
      fromType: 'issue',
    );
    return issues.getByIds(ids);
  }

  Future<List<TaskModel>> linkedTasks(IssueModel issue) async {
    final ids = await links.listToIds(
      fromType: 'issue',
      fromId: issue.id,
      relationType: 'blocks',
      toType: 'task',
    );
    if (ids.isEmpty) return const [];

    final result = <TaskModel>[];
    for (final id in ids) {
      final task = await tasks.getById(id);
      if (task != null) result.add(task);
    }
    return result;
  }

  Future<void> linkToCurrentTask(IssueModel issue) async {
    final currentTask = await tasks.getCurrent(issue.workspaceId);
    if (currentTask == null) {
      throw StateError('当前工作区暂无当前任务，无法建立关联。');
    }

    final now = DateTime.now().toUtc();
    await links.link(
      id: newWorkbenchId(),
      fromType: 'issue',
      fromId: issue.id,
      relationType: 'blocks',
      toType: 'task',
      toId: currentTask.id,
      createdAt: now,
    );

    await activities.insert(
      ActivityEventModel(
        id: newWorkbenchId(),
        workspaceId: issue.workspaceId,
        entityType: 'issue',
        entityId: issue.id,
        eventType: 'issue_linked_task',
        summary: '${issue.title} → ${currentTask.title}',
        createdAt: now,
      ),
    );
  }

  Future<IssueModel> create({
    required String workspaceId,
    required String title,
    String severity = 'medium',
    String impact = '',
    String hypothesis = '',
    String nextInvestigationStep = '',
    bool linkToCurrentTask = true,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Issue title is required.');
    }
    if (!const {'low', 'medium', 'high', 'critical'}.contains(severity)) {
      throw ArgumentError.value(severity, 'severity', 'Unsupported severity.');
    }

    final now = DateTime.now().toUtc();
    final issue = IssueModel(
      id: newWorkbenchId(),
      workspaceId: workspaceId,
      title: trimmedTitle,
      status: 'open',
      severity: severity,
      impact: impact.trim(),
      hypothesis: hypothesis.trim(),
      nextInvestigationStep: nextInvestigationStep.trim(),
      resolution: '',
      createdAt: now,
      updatedAt: now,
    );

    await issues.insert(issue);

    if (linkToCurrentTask) {
      final currentTask = await tasks.getCurrent(workspaceId);
      if (currentTask != null) {
        await links.link(
          id: newWorkbenchId(),
          fromType: 'issue',
          fromId: issue.id,
          relationType: 'blocks',
          toType: 'task',
          toId: currentTask.id,
          createdAt: now,
        );
      }
    }

    await activities.insert(
      ActivityEventModel(
        id: newWorkbenchId(),
        workspaceId: workspaceId,
        entityType: 'issue',
        entityId: issue.id,
        eventType: 'issue_created',
        summary: issue.title,
        createdAt: now,
      ),
    );

    return issue;
  }

  Future<IssueModel> update({
    required IssueModel issue,
    required String title,
    required String status,
    required String severity,
    required String impact,
    required String hypothesis,
    required String nextInvestigationStep,
    required String resolution,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Issue title is required.');
    }
    if (!const {'open', 'investigating', 'resolved', 'archived'}
        .contains(status)) {
      throw ArgumentError.value(status, 'status', 'Unsupported issue status.');
    }
    if (!const {'low', 'medium', 'high', 'critical'}.contains(severity)) {
      throw ArgumentError.value(severity, 'severity', 'Unsupported severity.');
    }

    final now = DateTime.now().toUtc();
    final updated = IssueModel(
      id: issue.id,
      workspaceId: issue.workspaceId,
      title: trimmedTitle,
      status: status,
      severity: severity,
      impact: impact.trim(),
      hypothesis: hypothesis.trim(),
      nextInvestigationStep: nextInvestigationStep.trim(),
      resolution: resolution.trim(),
      createdAt: issue.createdAt,
      updatedAt: now,
      archivedAt: status == 'archived' ? now : issue.archivedAt,
    );

    await issues.update(updated);
    await activities.insert(
      ActivityEventModel(
        id: newWorkbenchId(),
        workspaceId: issue.workspaceId,
        entityType: 'issue',
        entityId: issue.id,
        eventType: status == 'resolved' ? 'issue_resolved' : 'issue_updated',
        summary: updated.title,
        createdAt: now,
      ),
    );

    return updated;
  }
}
