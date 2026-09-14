import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';

import '../application/continue_service.dart';
import '../application/today_service.dart';
import '../workbench_runtime.dart';

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
    final theme = FluentTheme.of(context);
    return FutureBuilder<TodaySnapshot>(
      future: _snapshot,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _shell(
            theme,
            const SizedBox(height: 90, child: Center(child: ProgressRing())),
          );
        }
        if (snapshot.hasError) {
          return _shell(
            theme,
            Text('时间记录加载失败：${snapshot.error}'),
          );
        }

        final data = snapshot.data!;
        final focus = data.focus;
        final active = focus.active;
        final elapsed = active == null
            ? Duration.zero
            : DateTime.now().toUtc().difference(active.session.startedAt.toUtc());

        return _shell(
          theme,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '专注',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  _SummaryValue(
                    label: '今日专注',
                    value: _formatDuration(
                      Duration(seconds: focus.totalSeconds),
                    ),
                  ),
                  const SizedBox(width: 18),
                  _SummaryValue(
                    label: '工作区',
                    value: '${data.workspaceCount}',
                  ),
                  const SizedBox(width: 18),
                  _SummaryValue(
                    label: '完成专注',
                    value: '${data.completedSessionCount}',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (active != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${active.workspace?.name ?? '工作区'} · ${active.task?.title ?? '任务'}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatClock(elapsed),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: _busy ? null : _finish,
                      child: const Text('结束专注'),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.primary == null
                            ? '暂无可开始专注的当前任务'
                            : '${widget.primary!.workspace.name} · ${widget.primary!.context.task.title}',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.typography.body?.color?.withOpacity(0.72),
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: widget.primary == null || _busy ? null : _start,
                      child: const Text('开始专注'),
                    ),
                  ],
                ),
              ],
              if (focus.sessions.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  '今日时间线',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...focus.sessions.take(6).map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 104,
                          child: Text(
                            _timeRange(entry.session.startedAt, entry.session.endedAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.typography.body?.color?.withOpacity(0.52),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${entry.workspace?.name ?? '工作区'} / ${entry.task?.title ?? '任务'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          entry.session.endedAt == null
                              ? '进行中'
                              : _formatDuration(
                                  Duration(seconds: entry.session.durationSeconds),
                                ),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.typography.body?.color?.withOpacity(0.58),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _shell(FluentThemeData theme, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.inactiveColor.withOpacity(0.14)),
      ),
      child: child,
    );
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
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.typography.body?.color?.withOpacity(0.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
