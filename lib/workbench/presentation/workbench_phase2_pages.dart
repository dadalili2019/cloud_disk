import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme_controller.dart';
import '../core/models.dart';
import '../workbench_runtime.dart';
import 'workbench_ui.dart';
import 'workbench_workspace_admin_dialog.dart';

class WorkbenchWorkspaceFrameV2 extends StatefulWidget {
  const WorkbenchWorkspaceFrameV2({
    super.key,
    required this.workspaceId,
    required this.section,
    required this.child,
  });

  final String workspaceId;
  final String section;
  final Widget child;

  @override
  State<WorkbenchWorkspaceFrameV2> createState() =>
      _WorkbenchWorkspaceFrameV2State();
}

class _WorkbenchWorkspaceFrameV2State
    extends State<WorkbenchWorkspaceFrameV2> {
  late Future<WorkspaceOverviewModel> _overview;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant WorkbenchWorkspaceFrameV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId) _reload();
  }

  void _reload() {
    _overview = WorkbenchRuntime.instance.then(
      (runtime) => runtime.overviewService.loadOverview(widget.workspaceId),
    );
  }

  Future<void> _openSettings(WorkspaceModel workspace) async {
    final result = await showWorkspaceSettingsDialog(context, workspace);
    if (!mounted || result == null) return;
    if (result == 'archived') {
      context.go('/workspace');
      return;
    }
    if (result == 'saved') setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;

    return Container(
      color: palette.appBackground,
      child: Column(
        children: [
          FutureBuilder<WorkspaceOverviewModel>(
            future: _overview,
            builder: (context, snapshot) {
              final overview = snapshot.data;
              return _WorkspaceNavigation(
                workspaceId: widget.workspaceId,
                section: widget.section,
                onSettings: overview == null
                    ? null
                    : () => _openSettings(overview.workspace),
              );
            },
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class _WorkspaceNavigation extends StatelessWidget {
  const _WorkspaceNavigation({
    required this.workspaceId,
    required this.section,
    required this.onSettings,
  });

  final String workspaceId;
  final String section;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: palette.appBackground,
        border: Border(
          bottom: BorderSide(color: palette.cardBorder.withOpacity(0.68)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 1180 ? 34.0 : 28.0;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _WorkspaceTab(
                              label: '概览',
                              selected: section == 'overview',
                              onTap: () => context.go('/workspace/$workspaceId/overview'),
                            ),
                            _WorkspaceTab(
                              label: '任务',
                              selected: section == 'tasks',
                              onTap: () => context.go('/workspace/$workspaceId/tasks'),
                            ),
                            _WorkspaceTab(
                              label: '笔记',
                              selected: section == 'notes',
                              onTap: () => context.go('/workspace/$workspaceId/notes'),
                            ),
                            _WorkspaceTab(
                              label: '问题',
                              selected: section == 'issues',
                              onTap: () => context.go('/workspace/$workspaceId/issues'),
                            ),
                            _WorkspaceTab(
                              label: '资源',
                              selected: section == 'resources',
                              onTap: () => context.go('/workspace/$workspaceId/resources'),
                            ),
                            _WorkspaceTab(
                              label: '决策',
                              selected: section == 'decisions',
                              onTap: () => context.go('/workspace/$workspaceId/decisions'),
                            ),
                            _WorkspaceTab(
                              label: '开发',
                              selected: section == 'developer',
                              onTap: () => context.go('/workspace/$workspaceId/developer'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(FluentIcons.settings, size: 14),
                      onPressed: onSettings,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WorkspaceTab extends StatelessWidget {
  const _WorkspaceTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? palette.navItemSelected : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: selected
                  ? Border.all(color: palette.cardBorder.withOpacity(0.86))
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? theme.accentColor.normal
                    : theme.typography.body?.color?.withOpacity(0.68),
              ),
            ),
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
    final palette = ThemeScope.of(context).palette;
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Container(
        color: palette.appBackground,
        child: FutureBuilder<WorkspaceOverviewModel>(
          future: WorkbenchRuntime.instance.then(
            (runtime) => runtime.overviewService.loadOverview(workspaceId),
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: ProgressRing());
            }
            if (snapshot.hasError) {
              return Center(child: Text('加载失败：${snapshot.error}'));
            }

            final overview = snapshot.data!;
            return LayoutBuilder(
              builder: (context, constraints) {
                final horizontal = constraints.maxWidth >= 1180 ? 34.0 : 28.0;
                return ListView(
                  padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 28),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _CurrentTaskCard(
                              workspaceId: workspaceId,
                              task: overview.currentTask,
                            ),
                            const SizedBox(height: 12),
                            _OverviewGrid(
                              currentTask: overview.currentTask,
                              blockers: overview.currentBlockers,
                              notes: overview.linkedNotes,
                              resources: overview.linkedResources,
                              decisions: overview.linkedDecisions,
                            ),
                            const SizedBox(height: 12),
                            _Panel(
                              title: '最近动态',
                              emptyText: '暂无动态',
                              children: overview.recentActivity
                                  .map(
                                    (activity) => Text(
                                      _activityText(activity),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _activityText(ActivityEventModel activity) {
    switch (activity.eventType) {
      case 'workspace_created':
        return '创建工作区 · ${activity.summary.replaceFirst('Created workspace ', '')}';
      case 'workspace_renamed':
        return '重命名工作区 · ${activity.summary}';
      case 'workspace_archived':
        return '归档工作区 · ${activity.summary}';
      case 'workspace_restored':
        return '恢复工作区 · ${activity.summary}';
      case 'task_created':
        return '新建任务 · ${activity.summary}';
      case 'task_set_current':
        return '设为当前任务 · ${activity.summary}';
      case 'task_updated':
        return '更新任务 · ${activity.summary}';
      case 'task_completed':
        return '完成任务 · ${activity.summary}';
      case 'note_created':
        return '新建笔记 · ${activity.summary}';
      case 'issue_created':
        return '新建问题 · ${activity.summary}';
      case 'issue_updated':
        return '更新问题 · ${activity.summary}';
      case 'issue_resolved':
        return '解决问题 · ${activity.summary}';
      case 'issue_linked_task':
        return '关联问题到任务 · ${activity.summary}';
      case 'resource_created':
        return '新建资源 · ${activity.summary}';
      case 'resource_updated':
        return '更新资源 · ${activity.summary}';
      case 'resource_linked_task':
        return '关联资源到任务 · ${activity.summary}';
      case 'decision_created':
        return '新建决策 · ${activity.summary}';
      case 'decision_updated':
        return '更新决策 · ${activity.summary}';
      case 'decision_linked_task':
        return '关联决策到任务 · ${activity.summary}';
      case 'project_created':
        return '新建开发项目 · ${activity.summary}';
      case 'project_updated':
        return '更新开发项目 · ${activity.summary}';
      case 'project_archived':
        return '归档开发项目 · ${activity.summary}';
      case 'command_created':
        return '新建开发命令 · ${activity.summary}';
      case 'command_updated':
        return '更新开发命令 · ${activity.summary}';
      case 'command_archived':
        return '归档开发命令 · ${activity.summary}';
      case 'snippet_created':
        return '新建代码片段 · ${activity.summary}';
      case 'snippet_updated':
        return '更新代码片段 · ${activity.summary}';
      case 'snippet_archived':
        return '归档代码片段 · ${activity.summary}';
      default:
        return activity.summary;
    }
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({
    required this.currentTask,
    required this.blockers,
    required this.notes,
    required this.resources,
    required this.decisions,
  });

  final TaskModel? currentTask;
  final List<IssueModel> blockers;
  final List<NoteModel> notes;
  final List<ResourceModel> resources;
  final List<DecisionModel> decisions;

  @override
  Widget build(BuildContext context) {
    final panels = <Widget>[
      if (currentTask != null) _BlockerPanel(blockers: blockers),
      _Panel(
        title: '关联笔记',
        emptyText: '暂无关联笔记',
        children: notes
            .map(
              (note) => Text(
                note.title,
                style: const TextStyle(fontSize: 12),
              ),
            )
            .toList(),
      ),
      _Panel(
        title: '相关资源',
        emptyText: '暂无相关资源',
        children: resources
            .map(
              (resource) => Row(
                children: [
                  const Icon(FluentIcons.link, size: 12),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      resource.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
      _Panel(
        title: '最近决策',
        emptyText: '暂无相关决策',
        children: decisions
            .map(
              (decision) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    decision.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (decision.decisionText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        decision.decisionText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: FluentTheme.of(context)
                              .typography
                              .body
                              ?.color
                              ?.withOpacity(0.58),
                        ),
                      ),
                    ),
                ],
              ),
            )
            .toList(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              for (var i = 0; i < panels.length; i++) ...[
                panels[i],
                if (i != panels.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        const gap = 12.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: panels
              .map((panel) => SizedBox(width: width, child: panel))
              .toList(growable: false),
        );
      },
    );
  }
}

class _CurrentTaskCard extends StatelessWidget {
  const _CurrentTaskCard({required this.workspaceId, required this.task});

  final String workspaceId;
  final TaskModel? task;

  @override
  Widget build(BuildContext context) {
    final current = task;
    if (current == null) {
      return WorkbenchCard(
        child: Row(
          children: [
            const Expanded(
              child: Text(
                '暂无当前任务',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton(
              onPressed: () => context.go('/workspace/$workspaceId/tasks'),
              child: const Text('新建任务'),
            ),
          ],
        ),
      );
    }

    return WorkbenchCard(
      onTap: () => context.go('/workspace/$workspaceId/tasks'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '当前任务',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              WorkbenchTag(label: '进度 ${current.progress}%'),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            current.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          if (current.nextStep.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '下一步 · ${current.nextStep}',
              style: const TextStyle(fontSize: 12.5),
            ),
          ],
        ],
      ),
    );
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
      children: blockers
          .map(
            (issue) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(FluentIcons.warning, size: 13),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(issue.title, style: const TextStyle(fontSize: 12)),
                      if (issue.nextInvestigationStep.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          '下一步调查 · ${issue.nextInvestigationStep}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: FluentTheme.of(context)
                                .typography
                                .body
                                ?.color
                                ?.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return WorkbenchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorkbenchSectionHeader(title: title),
          const SizedBox(height: 12),
          if (children.isEmpty)
            Text(
              emptyText,
              style: TextStyle(
                fontSize: 11.5,
                color: FluentTheme.of(context)
                    .typography
                    .body
                    ?.color
                    ?.withOpacity(0.45),
              ),
            )
          else
            ...children.map(
              (child) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: child,
              ),
            ),
        ],
      ),
    );
  }
}
