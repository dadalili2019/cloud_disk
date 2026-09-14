import '../core/models.dart';
import '../domain/decision_repository.dart';
import '../domain/issue_repository.dart';
import '../domain/repositories.dart';
import '../domain/resource_repository.dart';

/// 统一聚合一个 Task 的工作上下文。
///
/// 页面、Home、Continue 和后续 AI 能力都应优先通过这个服务获取
/// Note / Issue / Resource / Decision，而不是各自重复查询 entity_links。
class TaskContextService {
  const TaskContextService({
    required this.notes,
    required this.issues,
    required this.resources,
    required this.decisions,
    required this.links,
    required this.activities,
  });

  final NoteRepository notes;
  final IssueRepository issues;
  final ResourceRepository resources;
  final DecisionRepository decisions;
  final EntityLinkRepository links;
  final ActivityRepository activities;

  Future<TaskContextModel> load(TaskModel task) async {
    final noteIds = await links.listFromIds(
      toType: 'task',
      toId: task.id,
      relationType: 'linked_to',
      fromType: 'note',
    );

    final issueIds = await links.listFromIds(
      toType: 'task',
      toId: task.id,
      relationType: 'blocks',
      fromType: 'issue',
    );

    final resourceIds = await links.listFromIds(
      toType: 'task',
      toId: task.id,
      relationType: 'supports',
      fromType: 'resource',
    );

    final decisionIds = await links.listFromIds(
      toType: 'task',
      toId: task.id,
      relationType: 'applies_to',
      fromType: 'decision',
    );

    final linkedNotes = await notes.getByIds(noteIds);
    final linkedIssues = await issues.getByIds(issueIds);
    final linkedResources = await resources.getByIds(resourceIds);
    final linkedDecisions = await decisions.getByIds(decisionIds);
    final recentActivity = await activities.listRecent(task.workspaceId, limit: 8);

    return TaskContextModel(
      task: task,
      notes: linkedNotes,
      issues: linkedIssues,
      resources: linkedResources,
      decisions: linkedDecisions,
      recentActivity: recentActivity,
    );
  }
}
