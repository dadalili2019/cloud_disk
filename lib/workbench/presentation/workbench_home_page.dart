import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../application/continue_service.dart';
import '../workbench_runtime.dart';

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

  void _continueTo(ContinueItem item) {
    context.go('/workspace/${item.workspace.id}/overview');
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: FutureBuilder<ContinueSnapshot>(
        future: _snapshot,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: ProgressRing());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }

          final data = snapshot.data!;
          final primary = data.primary;

          return ListView(
            padding: const EdgeInsets.fromLTRB(34, 30, 34, 36),
            children: [
              const Text(
                '今天',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 22),
              if (primary == null)
                _EmptyContinueCard(
                  onOpenWorkspace: () => context.go('/workspace'),
                )
              else
                _PrimaryContinueCard(
                  item: primary,
                  onContinue: () => _continueTo(primary),
                ),
              if (data.others.isNotEmpty) ...[
                const SizedBox(height: 26),
                const Text(
                  '其他进行中的工作',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
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
      ),
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

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.inactiveColor.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '继续工作',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onContinue,
                child: const Text('继续'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            item.workspace.name,
            style: TextStyle(
              fontSize: 12,
              color: theme.typography.body?.color?.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            task.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          if (task.nextStep.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 62,
                  child: Text(
                    '下一步',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Text(task.nextStep, style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],
          if (blockers.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 62,
                  child: Text(
                    '阻塞',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Text(
                    blockers.first.title,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ContextTag(label: '笔记 ${item.context.notes.length}'),
              _ContextTag(label: '问题 ${item.context.openIssues.length}'),
              _ContextTag(label: '资源 ${item.context.resources.length}'),
              _ContextTag(label: '决策 ${item.context.decisions.length}'),
            ],
          ),
        ],
      ),
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

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.inactiveColor.withOpacity(0.14)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.workspace.name,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.typography.body?.color?.withOpacity(0.50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    if (task.nextStep.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        '下一步：${task.nextStep}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.typography.body?.color?.withOpacity(0.62),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(FluentIcons.chevron_right, size: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextTag extends StatelessWidget {
  const _ContextTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: theme.inactiveColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: theme.typography.body?.color?.withOpacity(0.62),
        ),
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
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.inactiveColor.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '暂无可继续的当前任务',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: onOpenWorkspace,
            child: const Text('打开工作区'),
          ),
        ],
      ),
    );
  }
}
