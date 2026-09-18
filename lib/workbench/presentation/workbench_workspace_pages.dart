import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme_controller.dart';
import '../core/models.dart';
import '../workbench_runtime.dart';
import 'workbench_ui.dart';

class WorkbenchWorkspaceListPage extends StatefulWidget {
  const WorkbenchWorkspaceListPage({super.key});

  @override
  State<WorkbenchWorkspaceListPage> createState() =>
      _WorkbenchWorkspaceListPageState();
}

class _WorkbenchWorkspaceListPageState
    extends State<WorkbenchWorkspaceListPage> {
  late Future<List<WorkspaceModel>> _workspaces;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _workspaces = WorkbenchRuntime.instance.then(
      (runtime) => runtime.workspaceService.listActive(),
    );
  }

  Future<void> _createWorkspace() async {
    final nameController = TextEditingController();
    final slugController = TextEditingController();

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => ContentDialog(
          title: const Text('新建工作区'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextBox(
                  controller: nameController,
                  placeholder: '工作区名称',
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextBox(
                  controller: slugController,
                  placeholder: '目录标识（可选）',
                ),
              ],
            ),
          ),
          actions: [
            Button(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('创建'),
            ),
          ],
        ),
      );

      if (result != true || !mounted) return;
      final runtime = await WorkbenchRuntime.instance;
      final workspace = await runtime.workspaceService.create(
        name: nameController.text,
        slug: slugController.text,
      );
      if (!mounted) return;
      context.go('/workspace/${workspace.id}/overview');
    } catch (error) {
      if (!mounted) return;
      await showWorkbenchError(context, error);
    } finally {
      nameController.dispose();
      slugController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorkbenchPage(
      title: '工作台',
      subtitle: '按工作区组织任务、笔记和上下文。',
      actions: [
        FilledButton(
          onPressed: _createWorkspace,
          child: const Text('新建工作区'),
        ),
      ],
      children: [
        FutureBuilder<List<WorkspaceModel>>(
          future: _workspaces,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 220,
                child: Center(child: ProgressRing()),
              );
            }
            if (snapshot.hasError) {
              return _WorkbenchErrorState(error: snapshot.error!);
            }

            final workspaces = snapshot.data ?? const <WorkspaceModel>[];
            if (workspaces.isEmpty) {
              return WorkbenchCard(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '还没有工作区。',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: _createWorkspace,
                      child: const Text('创建第一个工作区'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                for (final workspace in workspaces)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: WorkbenchCard(
                      onTap: () => context.go(
                        '/workspace/${workspace.id}/overview',
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: ThemeScope.of(context).palette.surfaceMuted,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              FluentIcons.open_folder_horizontal,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  workspace.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (workspace.slug.trim().isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    workspace.slug,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: FluentTheme.of(context)
                                          .typography
                                          .body
                                          ?.color
                                          ?.withValues(alpha: 0.48),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(FluentIcons.chevron_right, size: 11),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class WorkbenchWorkspaceFrame extends StatelessWidget {
  const WorkbenchWorkspaceFrame({
    super.key,
    required this.workspaceId,
    required this.section,
    required this.child,
  });

  final String workspaceId;
  final String section;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return Column(
      children: [
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: palette.cardBackground.withValues(alpha: 0.56),
            border: Border(
              bottom: BorderSide(
                color: palette.navBorder.withValues(alpha: 0.92),
              ),
            ),
          ),
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
            ],
          ),
        ),
        Expanded(child: child),
      ],
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
    final accent = FluentTheme.of(context).accentColor.normal;
    final textColor = FluentTheme.of(context).typography.body?.color;

    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: 42,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? accent : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? accent : textColor?.withValues(alpha: 0.72),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WorkbenchOverviewPage extends StatelessWidget {
  const WorkbenchOverviewPage({
    super.key,
    required this.workspaceId,
  });

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
              return _WorkbenchErrorState(error: snapshot.error!);
            }

            final overview = snapshot.data!;
            final currentTask = overview.currentTask;

            return LayoutBuilder(
              builder: (context, constraints) {
                final horizontal = constraints.maxWidth < 720 ? 16.0 : 28.0;
                final stackPanels = constraints.maxWidth < 820;

                final panels = [
                  _SectionPanel(
                    title: '关联笔记',
                    emptyText: '暂无关联笔记',
                    children: overview.linkedNotes
                        .map(
                          (note) => _CompactRow(
                            icon: FluentIcons.page,
                            text: note.title,
                          ),
                        )
                        .toList(),
                  ),
                  _SectionPanel(
                    title: '最近动态',
                    emptyText: '暂无动态',
                    children: overview.recentActivity
                        .map((activity) => _ActivityRow(activity: activity))
                        .toList(),
                  ),
                ];

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    22,
                    horizontal,
                    32,
                  ),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    overview.workspace.name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      height: 1.15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Button(
                                  onPressed: () => context.go('/workspace'),
                                  child: const Text('切换工作区'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _CurrentTaskCard(
                              workspaceId: workspaceId,
                              task: currentTask,
                            ),
                            const SizedBox(height: 14),
                            if (stackPanels) ...[
                              panels[0],
                              const SizedBox(height: 12),
                              panels[1],
                            ] else
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: panels[0]),
                                  const SizedBox(width: 14),
                                  Expanded(child: panels[1]),
                                ],
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
}

class _CurrentTaskCard extends StatelessWidget {
  const _CurrentTaskCard({
    required this.workspaceId,
    required this.task,
  });

  final String workspaceId;
  final TaskModel? task;

  @override
  Widget build(BuildContext context) {
    final currentTask = task;
    if (currentTask == null) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '当前任务',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: FluentTheme.of(context)
                      .accentColor
                      .normal
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '进度 ${currentTask.progress}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: FluentTheme.of(context).accentColor.normal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currentTask.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (currentTask.nextStep.isNotEmpty) ...[
            const SizedBox(height: 14),
            WorkbenchInfoBlock(
              label: 'Next Step',
              value: currentTask.nextStep,
              emphasized: true,
            ),
          ],
        ],
      ),
    );
  }
}

class WorkbenchTasksPage extends StatefulWidget {
  const WorkbenchTasksPage({
    super.key,
    required this.workspaceId,
  });

  final String workspaceId;

  @override
  State<WorkbenchTasksPage> createState() => _WorkbenchTasksPageState();
}

class _WorkbenchTasksPageState extends State<WorkbenchTasksPage> {
  late Future<List<TaskModel>> _tasks;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _tasks = WorkbenchRuntime.instance.then(
      (runtime) => runtime.taskService.listByWorkspace(widget.workspaceId),
    );
  }

  Future<void> _createTask() async {
    final titleController = TextEditingController();
    final nextStepController = TextEditingController();

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => ContentDialog(
          title: const Text('新建任务'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextBox(
                  controller: titleController,
                  placeholder: '任务名称',
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextBox(
                  controller: nextStepController,
                  placeholder: '下一步',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            Button(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('创建'),
            ),
          ],
        ),
      );

      if (result != true || !mounted) return;
      final runtime = await WorkbenchRuntime.instance;
      final task = await runtime.taskService.create(
        workspaceId: widget.workspaceId,
        title: titleController.text,
        nextStep: nextStepController.text,
      );
      if (await runtime.taskService.getCurrent(widget.workspaceId) == null) {
        await runtime.taskService.setCurrent(widget.workspaceId, task.id);
      }
      if (!mounted) return;
      setState(_reload);
    } catch (error) {
      if (!mounted) return;
      await showWorkbenchError(context, error);
    } finally {
      titleController.dispose();
      nextStepController.dispose();
    }
  }

  Future<void> _setCurrent(TaskModel task) async {
    try {
      final runtime = await WorkbenchRuntime.instance;
      await runtime.taskService.setCurrent(widget.workspaceId, task.id);
      if (!mounted) return;
      setState(_reload);
    } catch (error) {
      if (!mounted) return;
      await showWorkbenchError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('任务'),
        commandBar: FilledButton(
          onPressed: _createTask,
          child: const Text('新建任务'),
        ),
      ),
      content: FutureBuilder<List<TaskModel>>(
        future: _tasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: ProgressRing());
          }
          if (snapshot.hasError) {
            return _WorkbenchErrorState(error: snapshot.error!);
          }

          final tasks = snapshot.data ?? const <TaskModel>[];
          if (tasks.isEmpty) {
            return Center(
              child: FilledButton(
                onPressed: _createTask,
                child: const Text('创建第一个任务'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _TaskCard(
                task: task,
                onSetCurrent: () => _setCurrent(task),
              );
            },
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onSetCurrent,
  });

  final TaskModel task;
  final VoidCallback onSetCurrent;

  @override
  Widget build(BuildContext context) {
    return _WorkbenchCard(
      child: Row(
        children: [
          Icon(
            task.isCurrent ? FluentIcons.radio_bullet : FluentIcons.circle_ring,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              task.isCurrent ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '进度 ${task.progress}%',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                if (task.nextStep.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '下一步  ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          task.nextStep,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (task.isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: FluentTheme.of(context)
                    .accentColor
                    .normal
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '当前任务',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: FluentTheme.of(context).accentColor.normal,
                ),
              ),
            )
          else
            Button(
              onPressed: onSetCurrent,
              child: const Text('设为当前'),
            ),
        ],
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _WorkbenchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (children.isEmpty)
            Text(
              emptyText,
              style: TextStyle(
                fontSize: 12,
                color: FluentTheme.of(context)
                    .typography
                    .body
                    ?.color
                    ?.withValues(alpha: 0.56),
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _CompactRow extends StatelessWidget {
  const _CompactRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final ActivityEventModel activity;

  String _text() {
    switch (activity.eventType) {
      case 'workspace_created':
        final name = activity.summary.replaceFirst('Created workspace ', '');
        return '创建工作区 · $name';
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
      default:
        return activity.summary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        _text(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class _WorkbenchCard extends StatelessWidget {
  const _WorkbenchCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.inactiveColor.withValues(alpha: 0.14),
        ),
      ),
      child: child,
    );
  }
}

class _WorkbenchErrorState extends StatelessWidget {
  const _WorkbenchErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '加载失败：${error.toString()}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

Future<void> showWorkbenchError(BuildContext context, Object error) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => ContentDialog(
      title: const Text('操作失败'),
      content: Text(error.toString()),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('确定'),
        ),
      ],
    ),
  );
}
