import 'package:fluent_ui/fluent_ui.dart';

import '../core/models.dart';
import '../workbench_runtime.dart';
import 'workbench_ui.dart';

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

  Future<void> _editTask(TaskModel task) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _TaskEditDrawer(
        task: task,
        onSaved: () => Navigator.pop(dialogContext, true),
        onCancel: () => Navigator.pop(dialogContext, false),
      ),
    );

    if (changed == true && mounted) {
      setState(_reload);
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
    return WorkbenchSectionPage(
      title: '任务',
      actions: [
        FilledButton(
          onPressed: _createTask,
          child: const Text('新建任务'),
        ),
      ],
      child: FutureBuilder<List<TaskModel>>(
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
            return WorkbenchEmptyState(
              title: '还没有任务',
              description: '先创建一个任务，明确当前要做什么以及下一步。',
              actionLabel: '新建任务',
              onAction: _createTask,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _TaskTile(
                task: task,
                onTap: () => _editTask(task),
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
    required this.onTap,
    required this.onSetCurrent,
  });

  final TaskModel task;
  final VoidCallback onTap;
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

    return WorkbenchCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: task.isCurrent
                    ? accent
                    : theme.inactiveColor.withValues(alpha: 0.45),
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
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    WorkbenchTag(label: _statusText),
                    const SizedBox(width: 6),
                    WorkbenchTag(label: '${task.progress}%'),
                  ],
                ),
                if (task.nextStep.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    task.nextStep,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.typography.body?.color?.withValues(alpha: 0.62),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          if (task.isCurrent)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: WorkbenchTag(label: '当前任务', selected: true),
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

class _TaskEditDrawer extends StatefulWidget {
  const _TaskEditDrawer({
    required this.task,
    required this.onSaved,
    required this.onCancel,
  });

  final TaskModel task;
  final VoidCallback onSaved;
  final VoidCallback onCancel;

  @override
  State<_TaskEditDrawer> createState() => _TaskEditDrawerState();
}

class _TaskEditDrawerState extends State<_TaskEditDrawer> {
  late final TextEditingController _titleController;
  late final TextEditingController _nextStepController;
  late String _status;
  late double _progress;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _nextStepController = TextEditingController(text: widget.task.nextStep);
    _status = _normalizeStatus(widget.task.status);
    _progress = widget.task.progress.toDouble();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nextStepController.dispose();
    super.dispose();
  }

  String _normalizeStatus(String status) {
    switch (status) {
      case 'doing':
      case 'in_progress':
        return 'doing';
      case 'done':
      case 'completed':
        return 'done';
      default:
        return 'todo';
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final runtime = await WorkbenchRuntime.instance;
      await runtime.taskService.update(
        task: widget.task,
        title: _titleController.text,
        status: _status,
        progress: _progress.round(),
        nextStep: _nextStepController.text,
      );
      if (!mounted) return;
      widget.onSaved();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 430,
        height: double.infinity,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            left: BorderSide(color: theme.inactiveColor.withValues(alpha: 0.16)),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              spreadRadius: 1,
              color: Colors.black.withValues(alpha: 0.10),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 14, 14),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '编辑任务',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(FluentIcons.chrome_close, size: 14),
                      onPressed: widget.onCancel,
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: theme.inactiveColor.withValues(alpha: 0.12),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                  children: [
                    const _FieldLabel('任务名称'),
                    const SizedBox(height: 7),
                    TextBox(
                      controller: _titleController,
                      placeholder: '任务名称',
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel('状态'),
                    const SizedBox(height: 7),
                    ComboBox<String>(
                      value: _status,
                      isExpanded: true,
                      items: const [
                        ComboBoxItem(value: 'todo', child: Text('待办')),
                        ComboBoxItem(value: 'doing', child: Text('进行中')),
                        ComboBoxItem(value: 'done', child: Text('已完成')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _status = value;
                          if (value == 'done') {
                            _progress = 100;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: _FieldLabel('进度')),
                        Text(
                          '${_progress.round()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.typography.body?.color?.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _progress,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      onChanged: _status == 'done'
                          ? null
                          : (value) => setState(() => _progress = value),
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel('下一步'),
                    const SizedBox(height: 7),
                    TextBox(
                      controller: _nextStepController,
                      placeholder: '下一步要做什么',
                      minLines: 4,
                      maxLines: 6,
                    ),
                    if (widget.task.isCurrent) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.accentColor.normal.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              FluentIcons.radio_bullet,
                              size: 13,
                              color: theme.accentColor.normal,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '当前任务',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.accentColor.normal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        '保存失败：$_error',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.inactiveColor.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Button(
                      onPressed: _saving ? null : widget.onCancel,
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? '保存中…' : '保存'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
