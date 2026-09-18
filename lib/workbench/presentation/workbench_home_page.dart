import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme_controller.dart';
import '../application/continue_service.dart';
import '../core/models.dart';
import '../workbench_runtime.dart';
import 'quick_capture_drawer.dart';
import 'resume_context_drawer.dart';
import 'workbench_ui.dart';

class WorkbenchHomePage extends StatefulWidget {
  const WorkbenchHomePage({super.key});

  @override
  State<WorkbenchHomePage> createState() => _WorkbenchHomePageState();
}

class _WorkbenchHomePageState extends State<WorkbenchHomePage> {
  late Future<_HomeData> _data;
  bool _quickCaptureOpen = false;
  bool _resumeOpen = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _data = WorkbenchRuntime.instance.then((runtime) async {
      final results = await Future.wait<dynamic>([
        runtime.continueService.load(),
        runtime.workspaceService.listActive(),
      ]);
      return _HomeData(
        snapshot: results[0] as ContinueSnapshot,
        workspaces: results[1] as List<WorkspaceModel>,
      );
    });
  }

  void _reloadFromChild() {
    if (!mounted) return;
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<_HomeData>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _HomeLoading();
            }

            if (snapshot.hasError) {
              return _HomeError(
                onRetry: () => setState(_reload),
              );
            }

            final data = snapshot.data!;
            final primary = data.snapshot.primary;

            return WorkbenchPage(
              title: '首页',
              actions: [
                Button(
                  onPressed: () =>
                      setState(() => _quickCaptureOpen = true),
                  child: const Text('快速记录'),
                ),
                if (primary != null)
                  FilledButton(
                    onPressed: () => setState(() => _resumeOpen = true),
                    child: const Text('继续'),
                  ),
              ],
              children: [
                if (data.workspaces.isEmpty)
                  WorkbenchEmptyState(
                    title: '开始你的第一个工作区',
                    description: '工作区用于保存任务、笔记、问题和工作上下文。',
                    actionLabel: '创建工作区',
                    onAction: () => context.go('/workspace'),
                  )
                else if (primary == null)
                  WorkbenchEmptyState(
                    title: '当前没有正在进行的任务',
                    description: '选择一个任务作为当前工作，之后这里会自动恢复下一步和最近上下文。',
                    actionLabel: '选择任务',
                    onAction: () => context.go('/workspace'),
                  )
                else
                  _CurrentFocusCard(
                    item: primary,
                    onOpenTask: () => context.go(
                      '/workspace/${primary.workspace.id}/tasks',
                    ),
                    onContinue: () => setState(() => _resumeOpen = true),
                  ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 820;
                    final today = _TodayPanel(
                      primary: primary,
                      onOpenTime: () => context.go('/time'),
                    );
                    final activity = _RecentActivityPanel(
                      primary: primary,
                      onOpenWorkspace: primary == null
                          ? () => context.go('/workspace')
                          : () => context.go(
                                '/workspace/${primary.workspace.id}/overview',
                              ),
                    );

                    if (!twoColumns) {
                      return Column(
                        children: [
                          today,
                          const SizedBox(height: 14),
                          activity,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 11, child: today),
                        const SizedBox(width: 14),
                        Expanded(flex: 9, child: activity),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
        if (_quickCaptureOpen)
          Positioned.fill(
            child: _DrawerLayer(
              onDismiss: () => setState(() => _quickCaptureOpen = false),
              child: FutureBuilder<_HomeData>(
                future: _data,
                builder: (context, snapshot) => QuickCaptureDrawer(
                  defaultWorkspace: snapshot.data?.snapshot.primary?.workspace,
                  onClose: () =>
                      setState(() => _quickCaptureOpen = false),
                  onCaptured: _reloadFromChild,
                ),
              ),
            ),
          ),
        if (_resumeOpen)
          Positioned.fill(
            child: FutureBuilder<_HomeData>(
              future: _data,
              builder: (context, snapshot) {
                final primary = snapshot.data?.snapshot.primary;
                if (primary == null) return const SizedBox.shrink();
                return _DrawerLayer(
                  onDismiss: () => setState(() => _resumeOpen = false),
                  child: ResumeContextDrawer(
                    item: primary,
                    onClose: () => setState(() => _resumeOpen = false),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CurrentFocusCard extends StatelessWidget {
  const _CurrentFocusCard({
    required this.item,
    required this.onOpenTask,
    required this.onContinue,
  });

  final ContinueItem item;
  final VoidCallback onOpenTask;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final task = item.context.task;
    final blockers = item.context.openIssues;
    final theme = FluentTheme.of(context);
    final palette = ThemeScope.of(context).palette;
    final secondary = theme.typography.body?.color?.withValues(alpha: 0.52);
    final nextStep =
        task.nextStep.trim().isEmpty ? '暂未设置下一步。' : task.nextStep.trim();
    final lastContext = item.context.recentActivity.isNotEmpty
        ? item.context.recentActivity.first.summary
        : task.description.trim().isNotEmpty
            ? task.description.trim()
            : '暂无最近上下文。';

    return WorkbenchCard(
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              WorkbenchTag(
                label: _statusLabel(task.status),
                selected: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (blockers.isEmpty || constraints.maxWidth < 620) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WorkbenchInfoBlock(
                      label: '下一步',
                      value: nextStep,
                      emphasized: true,
                    ),
                    if (blockers.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      WorkbenchInfoBlock(
                        label: '当前阻塞',
                        value: blockers.first.title,
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            FluentIcons.check_mark,
                            size: 11,
                            color: secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '当前没有阻塞',
                            style: TextStyle(fontSize: 10.5, color: secondary),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: WorkbenchInfoBlock(
                      label: '下一步',
                      value: nextStep,
                      emphasized: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: WorkbenchInfoBlock(
                      label: '当前阻塞',
                      value: blockers.first.title,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _ProgressLine(progress: task.progress),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: palette.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '最近上下文',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: secondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lastContext,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Button(onPressed: onOpenTask, child: const Text('打开任务')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onContinue,
                child: const Text('继续工作'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final palette = ThemeScope.of(context).palette;
    final value = progress.clamp(0, 100);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 4,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Positioned.fill(
                      child: Container(color: palette.cardBorder),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: constraints.maxWidth * value / 100,
                        color: theme.accentColor.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          '$value%',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _TodayPanel extends StatelessWidget {
  const _TodayPanel({
    required this.primary,
    required this.onOpenTime,
  });

  final ContinueItem? primary;
  final VoidCallback onOpenTime;

  @override
  Widget build(BuildContext context) {
    final items = <_TodayItem>[];
    final task = primary?.context.task;
    if (task != null && task.nextStep.trim().isNotEmpty) {
      items.add(
        _TodayItem(
          title: task.nextStep.trim(),
          context: task.title,
          time: '现在',
        ),
      );
    }

    for (final issue in primary?.context.openIssues.take(2) ?? const <IssueModel>[]) {
      final next = issue.nextInvestigationStep.trim();
      if (next.isEmpty) continue;
      items.add(
        _TodayItem(
          title: next,
          context: issue.title,
          time: '今天',
        ),
      );
    }

    return WorkbenchCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _PanelHeader(
            title: '今天',
            actionLabel: '查看时间',
            onAction: onOpenTime,
          ),
          if (items.isEmpty)
            const _PanelEmpty(text: '今天没有额外安排，继续当前任务即可。')
          else
            for (var index = 0; index < items.length; index++)
              _TodayRow(
                index: index + 1,
                item: items[index],
                last: index == items.length - 1,
              ),
        ],
      ),
    );
  }
}

class _RecentActivityPanel extends StatelessWidget {
  const _RecentActivityPanel({
    required this.primary,
    required this.onOpenWorkspace,
  });

  final ContinueItem? primary;
  final VoidCallback onOpenWorkspace;

  @override
  Widget build(BuildContext context) {
    final items = primary?.context.recentActivity.take(5).toList() ??
        const <ActivityEventModel>[];

    return WorkbenchCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _PanelHeader(
            title: '最近动态',
            actionLabel: '查看更多',
            onAction: onOpenWorkspace,
          ),
          if (items.isEmpty)
            const _PanelEmpty(text: '还没有最近动态。')
          else
            for (var index = 0; index < items.length; index++)
              _ActivityRow(
                event: items[index],
                last: index == items.length - 1,
              ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          HyperlinkButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _TodayRow extends StatelessWidget {
  const _TodayRow({
    required this.index,
    required this.item,
    required this.last,
  });

  final int index;
  final _TodayItem item;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final secondary =
        FluentTheme.of(context).typography.body?.color?.withValues(alpha: 0.50);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: palette.cardBorder)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$index',
              style: TextStyle(fontSize: 10.5, color: secondary),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5),
                ),
                const SizedBox(height: 3),
                Text(
                  item.context,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9.5, color: secondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(item.time, style: TextStyle(fontSize: 9.5, color: secondary)),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.event,
    required this.last,
  });

  final ActivityEventModel event;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final theme = FluentTheme.of(context);
    final secondary = theme.typography.body?.color?.withValues(alpha: 0.50);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: palette.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.accentColor.normal.withValues(alpha: 0.70),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              event.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _relativeTime(event.createdAt),
            style: TextStyle(fontSize: 9.5, color: secondary),
          ),
        ],
      ),
    );
  }
}

class _PanelEmpty extends StatelessWidget {
  const _PanelEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final secondary =
        FluentTheme.of(context).typography.body?.color?.withValues(alpha: 0.48);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: TextStyle(fontSize: 10.5, color: secondary)),
      ),
    );
  }
}

class _DrawerLayer extends StatelessWidget {
  const _DrawerLayer({
    required this.onDismiss,
    required this.child,
  });

  final VoidCallback onDismiss;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: Container(color: const Color(0x66000000)),
          ),
        ),
        child,
      ],
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return const WorkbenchPage(
      title: '首页',
      children: [
        WorkbenchCard(
          child: SizedBox(
            height: 240,
            child: Center(child: ProgressRing()),
          ),
        ),
      ],
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return WorkbenchPage(
      title: '首页',
      children: [
        WorkbenchEmptyState(
          title: '无法加载当前工作',
          description: '工作数据暂时无法读取。',
          actionLabel: '重试',
          onAction: onRetry,
        ),
      ],
    );
  }
}

class _HomeData {
  const _HomeData({
    required this.snapshot,
    required this.workspaces,
  });

  final ContinueSnapshot snapshot;
  final List<WorkspaceModel> workspaces;
}

class _TodayItem {
  const _TodayItem({
    required this.title,
    required this.context,
    required this.time,
  });

  final String title;
  final String context;
  final String time;
}

String _statusLabel(String status) {
  return switch (status.toLowerCase()) {
    'doing' => '进行中',
    'done' => '已完成',
    'archived' => '已归档',
    'todo' => '待开始',
    _ => status.isEmpty ? '当前任务' : status,
  };
}

String _relativeTime(DateTime value) {
  final duration = DateTime.now().toUtc().difference(value.toUtc());
  if (duration.inMinutes < 1) return '刚刚';
  if (duration.inHours < 1) return '${duration.inMinutes}m';
  if (duration.inDays < 1) return '${duration.inHours}h';
  if (duration.inDays < 7) return '${duration.inDays}d';
  return '${value.month}/${value.day}';
}
