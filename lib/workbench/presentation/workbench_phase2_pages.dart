import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../core/models.dart';
import '../workbench_runtime.dart';

class WorkbenchWorkspaceFrameV2 extends StatelessWidget {
  const WorkbenchWorkspaceFrameV2({super.key, required this.workspaceId, required this.section, required this.child});
  final String workspaceId;
  final String section;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: FluentTheme.of(context).inactiveColor.withOpacity(0.14)))),
        child: Row(children: [
          _Tab(label: '概览', selected: section == 'overview', onTap: () => context.go('/workspace/$workspaceId/overview')),
          _Tab(label: '任务', selected: section == 'tasks', onTap: () => context.go('/workspace/$workspaceId/tasks')),
          _Tab(label: '笔记', selected: section == 'notes', onTap: () => context.go('/workspace/$workspaceId/notes')),
          _Tab(label: '问题', selected: section == 'issues', onTap: () => context.go('/workspace/$workspaceId/issues')),
          _Tab(label: '资源', selected: section == 'resources', onTap: () => context.go('/workspace/$workspaceId/resources')),
          _Tab(label: '决策', selected: section == 'decisions', onTap: () => context.go('/workspace/$workspaceId/decisions')),
        ]),
      ),
      Expanded(child: child),
    ]);
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final accent = theme.accentColor.normal;
    return Padding(
      padding: const EdgeInsets.only(right: 22),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            height: 46,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: selected ? accent : Colors.transparent, width: 2))),
            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? accent : theme.typography.body?.color?.withOpacity(0.72))),
          ),
        ),
      ),
    );
  }
}

class WorkbenchOverviewPageV2 extends StatelessWidget {
  const WorkbenchOverviewPageV2({super.key, required this.workspaceId});
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: FutureBuilder<WorkspaceOverviewModel>(
        future: WorkbenchRuntime.instance.then((runtime) => runtime.overviewService.loadOverview(workspaceId)),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: ProgressRing());
          if (snapshot.hasError) return Center(child: Text('加载失败：${snapshot.error}'));
          final overview = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            children: [
              Row(children: [
                Expanded(child: Text(overview.workspace.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
                Button(onPressed: () => context.go('/workspace'), child: const Text('切换工作区')),
              ]),
              const SizedBox(height: 18),
              _CurrentTaskCard(workspaceId: workspaceId, task: overview.currentTask),
              const SizedBox(height: 14),
              if (overview.currentTask != null) _BlockerPanel(blockers: overview.currentBlockers),
              if (overview.currentTask != null) const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _Panel(
                  title: '关联笔记',
                  emptyText: '暂无关联笔记',
                  children: overview.linkedNotes.map((note) => Text(note.title, style: const TextStyle(fontSize: 12))).toList(),
                )),
                const SizedBox(width: 14),
                Expanded(child: _Panel(
                  title: '相关资源',
                  emptyText: '暂无相关资源',
                  children: overview.linkedResources.map((resource) => Row(children: [
                    const Icon(FluentIcons.link, size: 12),
                    const SizedBox(width: 8),
                    Expanded(child: Text(resource.name, style: const TextStyle(fontSize: 12))),
                  ])).toList(),
                )),
              ]),
              const SizedBox(height: 14),
              _Panel(
                title: '最近决策',
                emptyText: '暂无相关决策',
                children: overview.linkedDecisions.map((decision) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(decision.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    if (decision.decisionText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(decision.decisionText, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: FluentTheme.of(context).typography.body?.color?.withOpacity(0.58))),
                      ),
                  ],
                )).toList(),
              ),
              const SizedBox(height: 14),
              _Panel(
                title: '最近动态',
                emptyText: '暂无动态',
                children: overview.recentActivity.map((activity) => Text(_activityText(activity), style: const TextStyle(fontSize: 12))).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  String _activityText(ActivityEventModel activity) {
    switch (activity.eventType) {
      case 'workspace_created': return '创建工作区 · ${activity.summary.replaceFirst('Created workspace ', '')}';
      case 'task_created': return '新建任务 · ${activity.summary}';
      case 'task_set_current': return '设为当前任务 · ${activity.summary}';
      case 'task_updated': return '更新任务 · ${activity.summary}';
      case 'task_completed': return '完成任务 · ${activity.summary}';
      case 'note_created': return '新建笔记 · ${activity.summary}';
      case 'issue_created': return '新建问题 · ${activity.summary}';
      case 'issue_updated': return '更新问题 · ${activity.summary}';
      case 'issue_resolved': return '解决问题 · ${activity.summary}';
      case 'issue_linked_task': return '关联问题到任务 · ${activity.summary}';
      case 'resource_created': return '新建资源 · ${activity.summary}';
      case 'resource_updated': return '更新资源 · ${activity.summary}';
      case 'resource_linked_task': return '关联资源到任务 · ${activity.summary}';
      case 'decision_created': return '新建决策 · ${activity.summary}';
      case 'decision_updated': return '更新决策 · ${activity.summary}';
      case 'decision_linked_task': return '关联决策到任务 · ${activity.summary}';
      default: return activity.summary;
    }
  }
}

class _CurrentTaskCard extends StatelessWidget {
  const _CurrentTaskCard({required this.workspaceId, required this.task});
  final String workspaceId;
  final TaskModel? task;
  @override
  Widget build(BuildContext context) {
    if (task == null) {
      return _Card(child: Row(children: [
        const Expanded(child: Text('暂无当前任务', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
        FilledButton(onPressed: () => context.go('/workspace/$workspaceId/tasks'), child: const Text('新建任务')),
      ]));
    }
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Text('当前任务', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), const Spacer(), Text('进度 ${task!.progress}%', style: const TextStyle(fontSize: 11))]),
      const SizedBox(height: 8),
      Text(task!.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      if (task!.nextStep.isNotEmpty) ...[const SizedBox(height: 14), Text('下一步：${task!.nextStep}', style: const TextStyle(fontSize: 13))],
    ]));
  }
}

class _BlockerPanel extends StatelessWidget {
  const _BlockerPanel({required this.blockers});
  final List<IssueModel> blockers;
  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: '当前阻塞',
      emptyText: '当前任务暂无阻塞',
      children: blockers.map((issue) => Row(children: [
        const Icon(FluentIcons.warning, size: 13),
        const SizedBox(width: 8),
        Expanded(child: Text(issue.title, style: const TextStyle(fontSize: 12))),
        if (issue.nextInvestigationStep.isNotEmpty) Flexible(child: Text('下一步调查：${issue.nextInvestigationStep}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: FluentTheme.of(context).typography.body?.color?.withOpacity(0.55)))),
      ])).toList(),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.emptyText, required this.children});
  final String title;
  final String emptyText;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      if (children.isEmpty)
        Text(emptyText, style: TextStyle(fontSize: 12, color: FluentTheme.of(context).typography.body?.color?.withOpacity(0.45)))
      else
        ...children.map((child) => Padding(padding: const EdgeInsets.only(bottom: 9), child: child)),
    ]));
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.inactiveColor.withOpacity(0.14))),
      child: child,
    );
  }
}
