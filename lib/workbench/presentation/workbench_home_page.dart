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
              ? '从这里开始今天的工作。'
              : '${primary.workspace.name} · ${primary.context.task.title}',
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
            QuickCaptureCard(
              defaultWorkspace: primary?.workspace,
              onCaptured: _reloadAfterCapture,
            ),
            const SizedBox(height: 14),
            FocusTodayCard(primary: primary),
            if (data.others.isNotEmpty) ...[
              const SizedBox(height: 26),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '继续工作',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onContinue,
                child: const Text('继续'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.workspace.name,
            style: TextStyle(
              fontSize: 11.5,
              color: theme.typography.body?.color?.withOpacity(0.50),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            task.title,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          if (task.nextStep.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 66,
                  child: Text(
                    '下一步',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Text(task.nextStep, style: const TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          ],
          if (blockers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 66,
                  child: Text(
                    '阻塞',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Text(
                    blockers.first.title,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              WorkbenchTag(label: '笔记 ${item.context.notes.length}'),
              WorkbenchTag(label: '问题 ${item.context.openIssues.length}'),
              WorkbenchTag(label: '资源 ${item.context.resources.length}'),
              WorkbenchTag(label: '决策 ${item.context.decisions.length}'),
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

    return WorkbenchCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
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
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
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
    return WorkbenchCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '暂无可继续的当前任务',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
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
