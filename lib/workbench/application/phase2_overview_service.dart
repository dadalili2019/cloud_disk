import '../core/models.dart';
import '../domain/issue_repository.dart';
import '../domain/repositories.dart';
import 'workbench_services.dart';

class Phase2WorkspaceOverviewService {
  const Phase2WorkspaceOverviewService({
    required this.workspaces,
    required this.tasks,
    required this.notes,
    required this.issues,
    required this.links,
    required this.activities,
  });

  final WorkspaceRepository workspaces;
  final TaskRepository tasks;
  final NoteRepository notes;
  final IssueRepository issues;
  final EntityLinkService links;
  final ActivityRepository activities;

  Future<WorkspaceOverviewModel> loadOverview(String workspaceId) async {
    final workspace = await workspaces.getById(workspaceId);
    if (workspace == null) {
      throw StateError('Workspace not found: $workspaceId');
    }

    final currentTask = await tasks.getCurrent(workspaceId);

    var linkedNotes = <NoteModel>[];
    var currentBlockers = <IssueModel>[];

    if (currentTask != null) {
      linkedNotes = await notes.getByIds(
        await links.linkedNoteIds(currentTask.id),
      );

      final blockerIds = await links.links.listFromIds(
        toType: 'task',
        toId: currentTask.id,
        relationType: 'blocks',
        fromType: 'issue',
      );
      final linkedIssues = await issues.getByIds(blockerIds);
      currentBlockers = linkedIssues.where((issue) => issue.isOpen).toList();
    }

    final recentActivity = await activities.listRecent(workspaceId, limit: 8);

    return WorkspaceOverviewModel(
      workspace: workspace,
      currentTask: currentTask,
      linkedNotes: linkedNotes,
      currentBlockers: currentBlockers,
      recentActivity: recentActivity,
    );
  }
}
