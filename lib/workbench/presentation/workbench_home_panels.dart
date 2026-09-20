part of 'workbench_home_page.dart';

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
            const _PanelEmpty(text: '暂无安排')
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
            const _PanelEmpty(text: '暂无动态')
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
