import 'package:fluent_ui/fluent_ui.dart';

import '../core/models.dart';
import '../workbench_runtime.dart';

class WorkbenchTaskListPage extends StatefulWidget {
  const WorkbenchTaskListPage({
    super.key,
    required this.workspaceId,
  });

  final String workspaceId;

  @override
  State<WorkbenchTaskListPage> createState() => _WorkbenchTaskListPageState();
}

class _WorkbenchTaskListPageState extends State<WorkbenchTaskListPage> {
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
                  placeholder: '下一步（可选）',
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
      await _showError(error);
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
      await _showError(error);
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
            return Center(child: Text('加载失败：${snapshot.error}'));
          }

          final tasks = snapshot.data ?? const <TaskModel>[];
          if (tasks.isEmpty) {
            return Center(
              child: FilledButton(
                onPressed: _createTask,
                child: const Text('新建任务'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _TaskTile(
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

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onSetCurrent,
  });

  final TaskModel task;
  final VoidCallback onSetCurrent;

  String get _statusText {
    switch (task.status) {
      case 'doing':
      case 'in_progress':
        return '进行中';
      case 'done':
      case 'completed':
        return '已完成';
      default:
        return '待办';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final accent = theme.accentColor.normal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: task.isCurrent ? accent.withOpacity(0.045) : theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: task.isCurrent
              ? accent.withOpacity(0.28)
              : theme.inactiveColor.withOpacity(0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: task.isCurrent
                    ? accent
                    : theme.inactiveColor.withOpacity(0.45),
                shape: BoxShape.circle,
              ),
            ),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _Badge(text: _statusText),
                    const SizedBox(width: 6),
                    _Badge(text: '${task.progress}%'),
                  ],
                ),
                if (task.nextStep.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '下一步',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.typography.body?.color?.withOpacity(0.58),
                        ),
                      ),
                      const SizedBox(width: 12),
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
          const SizedBox(width: 14),
          if (task.isCurrent)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                '当前任务',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accent,
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

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: theme.inactiveColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: theme.typography.body?.color?.withOpacity(0.66),
        ),
      ),
    );
  }
}
