import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../application/continue_service.dart';
import '../workbench_runtime.dart';
import 'focus_today_card.dart';
import 'quick_capture_card.dart';
import 'workbench_ui.dart';

class WorkbenchHomePage extends StatefulWidget {
  const WorkbenchHomePage({super.key});

  @override
  State<WorkbenchHomePage> createState() => _WorkbenchHomePageState();
}

class _WorkbenchHomePageState extends State<WorkbenchHomePage> {
  late Future<ContinueSnapshot> _snapshot;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _snapshot = WorkbenchRuntime.instance.then(
      (runtime) => runtime.continueService.load(),
    );
  }

  void _reloadAfterCapture() {
    if (!mounted) return;
    setState(_reload);
  }

  void _continueTo(ContinueItem item) {
    context.go('/workspace/${item.workspace.id}/overview');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ContinueSnapshot>(
      future: _snapshot,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const ScaffoldPage(content: Center(child: ProgressRing()));
        }
        if (snapshot.hasError) {
          return ScaffoldPage(
            content: Center(child: Text('加载失败：${snapshot.error}')),
          );
        }

        final data = snapshot.data!;
        final primary = data.primary;

        return WorkbenchPage(
          title: '今天',
          subtitle: primary == null
              ? '先建立当前任务，再从这里继续。'
              : '继续当前工作，记录新想法，保持下一步清晰。',
          actions: [
            Button(
              onPressed: () => context.go('/workspace'),
              child: const Text('工作台'),
            ),
            if (primary != null)
              FilledButton(
                onPressed: () => _continueTo(primary),
                child: const Text('继续工作'),
              ),
          ],
          children: [
            if (primary == null)
              _EmptyContinueCard(
                onOpenWorkspace: () => context.go('/workspace'),
              )
            else
              _PrimaryContinueCard(
                item: primary,
                onContinue: () => _continueTo(primary),
              ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 880;
                if (!twoColumns) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      QuickCaptureCard(
                        defaultWorkspace: primary?.workspace,
                        onCaptured: _reloadAfterCapture,
                      ),
                      const SizedBox(height: 14),
                      FocusTodayCard(primary: primary),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: QuickCaptureCard(
                        defaultWorkspace: primary?.workspace,
                        onCaptured: _reloadAfterCapture,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 7,
                      child: FocusTodayCard(primary: primary),
                    ),
                  ],
                );
              },
            ),
            if (data.others.isNotEmpty) ...[
              const SizedBox(height: 24),
              const WorkbenchSectionHeader(title: '其他进行中的工作'),
              const SizedBox(height: 10),
              ...data.others.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OtherWorkCard(
                    item: item,
                    onTap: () => _continueTo(item),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PrimaryContinueCard extends StatelessWidget {
  const _PrimaryContinueCard({
    required this.item,
    required this.onContinue,
  });

  final ContinueItem item;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final task = item.context.task;
    final blockers = item.context.openIssues;
    final theme = FluentTheme.of(context);

    return WorkbenchCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前任务 · ${item.workspace.name}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: theme.typography.body?.color?.withOpacity(0.48),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 21,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              WorkbenchTag(label: _statusLabel(task.status), selected: true),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final nextStep = task.nextStep.trim().isEmpty
                  ? '暂未设置下一步。'
                  : task.nextStep.trim();
              final blocker = blockers.isEmpty
                  ? '当前没有阻塞。'
                  : blockers.first.title;
              if (constraints.maxWidth < 620) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WorkbenchInfoBlock(
                      label: 'Next Step',
                      value: nextStep,
                      emphasized: true,
                    ),
                    const SizedBox(height: 10),
                    WorkbenchInfoBlock(label: 'Blocker', value: blocker),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: WorkbenchInfoBlock(
                      label: 'Next Step',
                      value: nextStep,
                      emphasized: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: WorkbenchInfoBlock(label: 'Blocker', value: blocker),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _TaskProgress(progress: task.progress),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final tags = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  WorkbenchTag(label: '笔记 ${item.context.notes.length}'),
                  WorkbenchTag(label: '问题 ${item.context.openIssues.length}'),
                  WorkbenchTag(label: '资源 ${item.context.resources.length}'),
                  WorkbenchTag(label: '决策 ${item.context.decisions.length}'),
                ],
              );
              final action = FilledButton(
                onPressed: onContinue,
                child: const Text('打开上下文'),
              );

              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    tags,
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerRight, child: action),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: tags),
                  const SizedBox(width: 14),
                  action,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TaskProgress extends StatelessWidget {
  const _TaskProgress({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final safeProgress = progress.clamp(0, 100);
    final trackColor = theme.typography.body?.color?.withOpacity(0.08) ??
        const Color(0x16000000);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 5,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Positioned.fill(child: Container(color: trackColor)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: constraints.maxWidth * safeProgress / 100,
                          color: theme.accentColor.normal,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$safeProgress%',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: theme.typography.body?.color?.withOpacity(0.56),
          ),
        ),
      ],
    );
  }
}

class _OtherWorkCard extends StatelessWidget {
  const _OtherWorkCard({required this.item, required this.onTap});

  final ContinueItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final task = item.context.task;

    return WorkbenchCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.workspace.name,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: theme.typography.body?.color?.withOpacity(0.46),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (task.nextStep.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    '下一步：${task.nextStep}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: theme.typography.body?.color?.withOpacity(0.58),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          WorkbenchTag(label: '${task.progress}%'),
          const SizedBox(width: 8),
          const Icon(FluentIcons.chevron_right, size: 11),
        ],
      ),
    );
  }
}

class _EmptyContinueCard extends StatelessWidget {
  const _EmptyContinueCard({required this.onOpenWorkspace});

  final VoidCallback onOpenWorkspace;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return WorkbenchCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '暂无当前任务',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '在工作台中选择一个任务作为 Current Task。',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.typography.body?.color?.withOpacity(0.52),
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onOpenWorkspace,
            child: const Text('打开工作台'),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'doing':
      return '进行中';
    case 'done':
      return '已完成';
    case 'archived':
      return '已归档';
    case 'todo':
      return '待处理';
    default:
      return status.isEmpty ? '当前任务' : status;
  }
}
