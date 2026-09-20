part of 'workbench_home_page.dart';

class _CurrentFocusCard extends StatelessWidget {
  const _CurrentFocusCard({
    required this.item,
    required this.onOpenTask,
    required this.onQuickCapture,
    required this.onContinue,
  });

  final ContinueItem item;
  final VoidCallback onOpenTask;
  final VoidCallback onQuickCapture;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final task = item.context.task;
    final blockers = item.context.openIssues;
    final theme = FluentTheme.of(context);
    final palette = ThemeScope.of(context).palette;
    final secondary = theme.typography.body?.color?.withValues(alpha: 0.52);
    final nextStep =
        task.nextStep.trim().isEmpty ? '暂无' : task.nextStep.trim();
    final lastContext = item.context.recentActivity.isNotEmpty
        ? item.context.recentActivity.first.summary
        : task.description.trim().isNotEmpty
            ? task.description.trim()
            : '暂无';

    return WorkbenchCard(
      onTap: onOpenTask,
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Button(
                    onPressed: onQuickCapture,
                    child: const Text('快速记录'),
                  ),
                  FilledButton(
                    onPressed: onContinue,
                    child: const Text('继续'),
                  ),
                  WorkbenchTag(
                    label: _statusLabel(task.status),
                    selected: true,
                  ),
                ],
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
          const SizedBox(height: 2),
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
