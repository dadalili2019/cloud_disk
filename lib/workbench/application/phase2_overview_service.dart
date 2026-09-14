import '../core/models.dart';
import '../domain/decision_repository.dart';
import '../domain/issue_repository.dart';
import '../domain/repositories.dart';
import '../domain/resource_repository.dart';

class Phase2WorkspaceOverviewService {
  const Phase2WorkspaceOverviewService({
    required this.workspaces,
    required this.tasks,
    required this.notes,
    required this.issues,
    required this.resources,
    required this.decisions,
    required this.links,
    required this.activities,
  });

  final WorkspaceRepository workspaces;
  final TaskRepository tasks;
  final NoteRepository notes;
  final IssueRepository issues;
  final ResourceRepository resources;
  final DecisionRepository decisions;
  final EntityLinkRepository links;
  final ActivityRepository activities;

  Future<WorkspaceOverviewModel> loadOverview(String workspaceId) async {
    final workspace = await workspaces.getById(workspaceId);
    if (workspace == null) {
      throw StateError('Workspace not found: $workspaceId');
    }

    final currentTask = await tasks.getCurrent(workspaceId);
    var linkedNotes = <NoteModel>[];
    var currentBlockers = <IssueModel>[];
    var linkedResources = <ResourceModel>[];
    var linkedDecisions = <DecisionModel>[];

    if (currentTask != null) {
      final noteIds = await links.listFromIds(
        toType: 'task',
        toId: currentTask.id,
        relationType: 'linked_to',
        fromType: 'note',
      );
      linkedNotes = await notes.getByIds(noteIds);

      final blockerIds = await links.listFromIds(
        toType: 'task',
        toId: currentTask.id,
        relationType: 'blocks',
        fromType: 'issue',
      );
      final linkedIssues = await issues.getByIds(blockerIds);
      currentBlockers = linkedIssues.where((issue) => issue.isOpen).toList();

      final resourceIds = await links.listFromIds(
        toType: 'task',
        toId: currentTask.id,
        relationType: 'supports',
        fromType: 'resource',
      );
      linkedResources = await resources.getByIds(resourceIds);

      final decisionIds = await links.listFromIds(
        toType: 'task',
        toId: currentTask.id,
        relationType: 'applies_to',
        fromType: 'decision',
      );
      linkedDecisions = await decisions.getByIds(decisionIds);
    }

    final recentActivity = await activities.listRecent(workspaceId, limit: 8);

    return WorkspaceOverviewModel(
      workspace: workspace,
      currentTask: currentTask,
      linkedNotes: linkedNotes,
      currentBlockers: currentBlockers,
      linkedResources: linkedResources,
      linkedDecisions: linkedDecisions,
      recentActivity: recentActivity,
    );
  }
}
