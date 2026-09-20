part of 'workbench_home_page.dart';

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
          description: '',
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
