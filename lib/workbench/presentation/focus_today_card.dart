import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';

import '../../theme/theme_controller.dart';
import '../application/continue_service.dart';
import '../application/today_service.dart';
import '../workbench_runtime.dart';
import 'workbench_ui.dart';

class FocusTodayCard extends StatefulWidget {
  const FocusTodayCard({
    super.key,
    required this.primary,
  });

  final ContinueItem? primary;

  @override
  State<FocusTodayCard> createState() => _FocusTodayCardState();
}

class _FocusTodayCardState extends State<FocusTodayCard> {
  late Future<TodaySnapshot> _snapshot;
  Timer? _ticker;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _reload() {
    _snapshot = WorkbenchRuntime.instance.then(
      (runtime) => runtime.todayService.load(),
    );
  }

  Future<void> _start() async {
    final primary = widget.primary;
    if (primary == null || _busy) return;
    setState(() => _busy = true);
    try {
      final runtime = await WorkbenchRuntime.instance;
      await runtime.focusSessionService.start(
        workspaceId: primary.workspace.id,
        taskId: primary.context.task.id,
      );
      if (!mounted) return;
      setState(_reload);
    } catch (error) {
      if (!mounted) return;
      await _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    if (_busy) return;
    final noteController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => ContentDialog(
          title: const Text('结束专注'),
          content: SizedBox(
            width: 420,
            child: TextBox(
              controller: noteController,
              placeholder: '本次专注记录（可选）',
              maxLines: 3,
            ),
          ),
          actions: [
            Button(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('结束'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      setState(() => _busy = true);
      final runtime = await WorkbenchRuntime.instance;
      await runtime.focusSessionService.finish(note: noteController.text);
      if (!mounted) return;
      setState(_reload);
    } catch (error) {
      if (!mounted) return;
      await _showError(error);
    } finally {
      noteController.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showError(Object error) {
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TodaySnapshot>(
      future: _snapshot,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const WorkbenchCard(
            padding: EdgeInsets.all(18),
            child: SizedBox(height: 120, child: Center(child: ProgressRing())),
          );
        }
        if (snapshot.hasError) {
          return WorkbenchCard(
            padding: const EdgeInsets.all(18),
            child: Text('时间记录加载失败：${snapshot.error}'),
          );
        }

        final data = snapshot.data!;
        final focus = data.focus;
        final active = focus.active;
        final elapsed = active == null
            ? Duration.zero
            : DateTime.now().toUtc().difference(active.session.startedAt.toUtc());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WorkbenchCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '专注',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      WorkbenchTag(
                        label:
                            '今日 ${_formatDuration(Duration(seconds: focus.totalSeconds))}',
                        selected: active != null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FocusSurface(
                    child: active != null
                        ? _ActiveFocusBlock(
                            title:
                                '${active.workspace?.name ?? '工作区'} · ${active.task?.title ?? '任务'}',
                            elapsed: _formatClock(elapsed),
                            busy: _busy,
                            onFinish: _finish,
                          )
                        : _IdleFocusBlock(
                            title: widget.primary == null
                                ? '暂无当前任务'
                                : '${widget.primary!.workspace.name} · ${widget.primary!.context.task.title}',
                            enabled: widget.primary != null && !_busy,
                            onStart: _start,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MetricPill(label: '工作区', value: '${data.workspaceCount}'),
                      _MetricPill(
                        label: '已完成',
                        value: '${data.completedSessionCount}',
                      ),
                      _MetricPill(label: '记录', value: '${focus.sessions.length}'),
                    ],
                  ),
                ],
              ),
            ),
            if (focus.sessions.isNotEmpty) ...[
              const SizedBox(height: 18),
              WorkbenchCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WorkbenchSectionHeader(title: '今日时间线'),
                    const SizedBox(height: 16),
                    ...focus.sessions.take(6).map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TimelineRow(
                          time: _timeRange(
                            entry.session.startedAt,
                            entry.session.endedAt,
                          ),
                          title:
                              '${entry.workspace?.name ?? '工作区'} / ${entry.task?.title ?? '任务'}',
                          duration: entry.session.endedAt == null
                              ? '进行中'
                              : _formatDuration(
                                  Duration(
                                    seconds: entry.session.durationSeconds,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FocusSurface extends StatelessWidget {
  const _FocusSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: palette.cardBorder.withValues(alpha: 0.82),
        ),
      ),
      child: child,
    );
  }
}

class _ActiveFocusBlock extends StatelessWidget {
  const _ActiveFocusBlock({
    required this.title,
    required this.elapsed,
    required this.busy,
    required this.onFinish,
  });

  final String title;
  final String elapsed;
  final bool busy;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              elapsed,
              style: const TextStyle(
                fontSize: 24,
                height: 1.1,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.35,
              ),
            ),
          ],
        );
        final button = FilledButton(
          onPressed: busy ? null : onFinish,
          child: const Text('结束专注'),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              content,
              const SizedBox(height: 12),
              button,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: content),
            const SizedBox(width: 14),
            button,
          ],
        );
      },
    );
  }
}

class _IdleFocusBlock extends StatelessWidget {
  const _IdleFocusBlock({
    required this.title,
    required this.enabled,
    required this.onStart,
  });

  final String title;
  final bool enabled;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final text = Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.4,
            color: theme.typography.body?.color?.withValues(alpha: 0.72),
          ),
        );
        final button = FilledButton(
          onPressed: enabled ? onStart : null,
          child: const Text('开始专注'),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              text,
              const SizedBox(height: 12),
              button,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: text),
            const SizedBox(width: 14),
            button,
          ],
        );
      },
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final palette = ThemeScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.cardBackground.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: palette.cardBorder.withValues(alpha: 0.82),
        ),
      ),
      child: Text(
        '$label  $value',
        style: TextStyle(
          fontSize: 10.5,
          color: theme.typography.body?.color?.withValues(alpha: 0.62),
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.time,
    required this.title,
    required this.duration,
  });

  final String time;
  final String title;
  final String duration;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 94,
          child: Text(
            time,
            style: TextStyle(
              fontSize: 10.5,
              color: theme.typography.body?.color?.withValues(alpha: 0.48),
            ),
          ),
        ),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          duration,
          style: TextStyle(
            fontSize: 10.5,
            color: theme.typography.body?.color?.withValues(alpha: 0.54),
          ),
        ),
      ],
    );
  }
}

String _formatClock(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

String _formatDuration(Duration duration) {
  if (duration.inHours > 0) {
    return '${duration.inHours}小时${duration.inMinutes % 60}分钟';
  }
  if (duration.inMinutes > 0) return '${duration.inMinutes}分钟';
  return '${duration.inSeconds}秒';
}

String _timeRange(DateTime startUtc, DateTime? endUtc) {
  final start = startUtc.toLocal();
  final end = endUtc?.toLocal();
  String hhmm(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  return end == null ? '${hhmm(start)} - 现在' : '${hhmm(start)} - ${hhmm(end)}';
}
