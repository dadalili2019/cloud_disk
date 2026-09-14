import '../core/models.dart';
import '../domain/repositories.dart';
import 'task_context_service.dart';

class ContinueItem {
  const ContinueItem({
    required this.workspace,
    required this.context,
    required this.lastActivityAt,
  });

  final WorkspaceModel workspace;
  final TaskContextModel context;
  final DateTime lastActivityAt;
}

class ContinueSnapshot {
  const ContinueSnapshot({
    required this.primary,
    required this.others,
  });

  final ContinueItem? primary;
  final List<ContinueItem> others;
}

class ContinueService {
  const ContinueService({
    required this.workspaces,
    required this.tasks,
    required this.taskContextService,
  });

  final WorkspaceRepository workspaces;
  final TaskRepository tasks;
  final TaskContextService taskContextService;

  Future<ContinueSnapshot> load() async {
    final activeWorkspaces = await workspaces.listActive();
    final items = <ContinueItem>[];

    for (final workspace in activeWorkspaces) {
      final task = await tasks.getCurrent(workspace.id);
      if (task == null) continue;

      final context = await taskContextService.load(task);
      final activityAt = context.recentActivity.isNotEmpty
          ? context.recentActivity.first.createdAt
          : task.updatedAt;

      items.add(
        ContinueItem(
          workspace: workspace,
          context: context,
          lastActivityAt: activityAt,
        ),
      );
    }

    items.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));

    return ContinueSnapshot(
      primary: items.isEmpty ? null : items.first,
      others: items.length <= 1 ? const [] : items.sublist(1),
    );
  }
}
