import '../core/models.dart';
import '../domain/repositories.dart';
import 'task_context_service.dart';

class WorkspaceOverviewService {
  const WorkspaceOverviewService({
    required this.workspaces,
    required this.tasks,
    required this.taskContextService,
    required this.activities,
  });

  final WorkspaceRepository workspaces;
  final TaskRepository tasks;
  final TaskContextService taskContextService;
  final ActivityRepository activities;

  Future<WorkspaceOverviewModel> loadOverview(String workspaceId) async {
    final workspace = await workspaces.getById(workspaceId);
    if (workspace == null) {
      throw StateError('Workspace not found: $workspaceId');
    }

    final currentTask = await tasks.getCurrent(workspaceId);
    final recentActivity = await activities.listRecent(workspaceId, limit: 8);

    if (currentTask == null) {
      return WorkspaceOverviewModel(
        workspace: workspace,
        currentTask: null,
        linkedNotes: const [],
        currentBlockers: const [],
        linkedResources: const [],
        linkedDecisions: const [],
        recentActivity: recentActivity,
      );
    }

    final context = await taskContextService.load(currentTask);

    return WorkspaceOverviewModel(
      workspace: workspace,
      currentTask: currentTask,
      linkedNotes: context.notes,
      currentBlockers: context.openIssues,
      linkedResources: context.resources,
      linkedDecisions: context.decisions,
      recentActivity: recentActivity,
    );
  }
}
