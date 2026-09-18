import 'package:fluent_ui/fluent_ui.dart';

import '../core/models.dart';
import '../workbench_runtime.dart';
import 'workbench_ui.dart';

class WorkbenchIssuePage extends StatefulWidget {
  const WorkbenchIssuePage({
    super.key,
    required this.workspaceId,
  });

  final String workspaceId;

  @override
  State<WorkbenchIssuePage> createState() => _WorkbenchIssuePageState();
}

class _WorkbenchIssuePageState extends State<WorkbenchIssuePage> {
  late Future<List<IssueModel>> _issues;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _issues = WorkbenchRuntime.instance.then(
      (runtime) => runtime.issueService.listByWorkspace(widget.workspaceId),
    );
  }

  Future<void> _createIssue() async {
    final title = TextEditingController();
    final impact = TextEditingController();
    final hypothesis = TextEditingController();
    final nextStep = TextEditingController();
    var severity = 'medium';

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => ContentDialog(
            title: const Text('新建问题'),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextBox(
                    controller: title,
                    placeholder: '问题名称',
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  ComboBox<String>(
                    value: severity,
                    isExpanded: true,
                    items: const [
                      ComboBoxItem(value: 'low', child: Text('低')),
                      ComboBoxItem(value: 'medium', child: Text('中')),
                      ComboBoxItem(value: 'high', child: Text('高')),
                      ComboBoxItem(value: 'critical', child: Text('严重')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => severity = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextBox(
                    controller: impact,
                    placeholder: '影响',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextBox(
                    controller: hypothesis,
                    placeholder: '当前假设',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextBox(
                    controller: nextStep,
                    placeholder: '下一步调查',
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
        ),
      );

      if (confirmed != true || !mounted) return;

      final runtime = await WorkbenchRuntime.instance;
      await runtime.issueService.create(
        workspaceId: widget.workspaceId,
        title: title.text,
        severity: severity,
        impact: impact.text,
        hypothesis: hypothesis.text,
        nextInvestigationStep: nextStep.text,
      );

      if (!mounted) return;
      setState(_reload);
    } catch (error) {
      if (!mounted) return;
      await _showError(error);
    } finally {
      title.dispose();
      impact.dispose();
      hypothesis.dispose();
      nextStep.dispose();
    }
  }

  Future<void> _editIssue(IssueModel issue) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _IssueEditDrawer(
        issue: issue,
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

  String _statusText(String status) {
    switch (status) {
      case 'investigating':
        return '调查中';
      case 'resolved':
        return '已解决';
      case 'archived':
        return '已归档';
      default:
        return '待处理';
    }
  }

  String _severityText(String severity) {
    switch (severity) {
      case 'low':
        return '低';
      case 'high':
        return '高';
      case 'critical':
        return '严重';
      default:
        return '中';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return WorkbenchSectionPage(
      title: '问题',
      actions: [
        FilledButton(
          onPressed: _createIssue,
          child: const Text('新建问题'),
        ),
      ],
      child: FutureBuilder<List<IssueModel>>(
        future: _issues,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: ProgressRing());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }

          final issues = snapshot.data ?? const <IssueModel>[];
          if (issues.isEmpty) {
            return WorkbenchEmptyState(
              title: '当前没有问题',
              description: '',
              actionLabel: '新建问题',
              onAction: _createIssue,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: issues.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final issue = issues[index];
              return FutureBuilder<List<TaskModel>>(
                future: WorkbenchRuntime.instance.then(
                  (runtime) => runtime.issueService.linkedTasks(issue),
                ),
                builder: (context, linkSnapshot) {
                  final linkedTasks = linkSnapshot.data ?? const <TaskModel>[];
                  final linkedTaskText = linkedTasks.map((task) => task.title).join('、');

                  return WorkbenchCard(
                    onTap: () => _editIssue(issue),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                issue.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            WorkbenchTag(
                              label: _severityText(issue.severity),
                            ),
                            const SizedBox(width: 6),
                            WorkbenchTag(label: _statusText(issue.status)),
                          ],
                        ),
                        if (linkedTaskText.isNotEmpty) ...[
                          const SizedBox(height: 7),
                          Text(
                            linkedTaskText,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: theme.typography.body?.color?.withValues(alpha: 0.52),
                            ),
                          ),
                        ],
                        if (issue.impact.isNotEmpty) ...[
                          const SizedBox(height: 9),
                          Text('影响 · ${issue.impact}',
                              style: const TextStyle(fontSize: 11.5)),
                        ],
                        if (issue.hypothesis.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text('当前假设 · ${issue.hypothesis}',
                              style: const TextStyle(fontSize: 11.5)),
                        ],
                        if (issue.nextInvestigationStep.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            '下一步调查 · ${issue.nextInvestigationStep}',
                            style: const TextStyle(fontSize: 11.5),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _IssueEditDrawer extends StatefulWidget {
  const _IssueEditDrawer({
    required this.issue,
    required this.onSaved,
    required this.onCancel,
  });

  final IssueModel issue;
  final VoidCallback onSaved;
  final VoidCallback onCancel;

  @override
  State<_IssueEditDrawer> createState() => _IssueEditDrawerState();
}

class _IssueEditDrawerState extends State<_IssueEditDrawer> {
  late final TextEditingController _title;
  late final TextEditingController _impact;
  late final TextEditingController _hypothesis;
  late final TextEditingController _nextStep;
  late final TextEditingController _resolution;
  late String _status;
  late String _severity;
  bool _saving = false;
  bool _linking = false;
  String? _error;
  late Future<List<TaskModel>> _linkedTasks;
  late Future<TaskModel?> _currentTask;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.issue.title);
    _impact = TextEditingController(text: widget.issue.impact);
    _hypothesis = TextEditingController(text: widget.issue.hypothesis);
    _nextStep = TextEditingController(text: widget.issue.nextInvestigationStep);
    _resolution = TextEditingController(text: widget.issue.resolution);
    _status = widget.issue.status;
    _severity = widget.issue.severity;
    _reloadLinks();
  }

  void _reloadLinks() {
    _linkedTasks = WorkbenchRuntime.instance.then(
      (runtime) => runtime.issueService.linkedTasks(widget.issue),
    );
    _currentTask = WorkbenchRuntime.instance.then(
      (runtime) => runtime.issueService.currentTask(widget.issue.workspaceId),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _impact.dispose();
    _hypothesis.dispose();
    _nextStep.dispose();
    _resolution.dispose();
    super.dispose();
  }

  Future<void> _linkCurrentTask() async {
    if (_linking) return;
    setState(() {
      _linking = true;
      _error = null;
    });
    try {
      final runtime = await WorkbenchRuntime.instance;
      await runtime.issueService.linkToCurrentTask(widget.issue);
      if (!mounted) return;
      setState(() {
        _linking = false;
        _reloadLinks();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _linking = false;
        _error = error.toString();
      });
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
      await runtime.issueService.update(
        issue: widget.issue,
        title: _title.text,
        status: _status,
        severity: _severity,
        impact: _impact.text,
        hypothesis: _hypothesis.text,
        nextInvestigationStep: _nextStep.text,
        resolution: _resolution.text,
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
        width: 470,
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
                        '编辑问题',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(FluentIcons.chrome_close, size: 14),
                      onPressed: widget.onCancel,
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: theme.inactiveColor.withValues(alpha: 0.12)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                  children: [
                    const _FieldLabel('问题名称'),
                    const SizedBox(height: 7),
                    TextBox(controller: _title),
                    const SizedBox(height: 18),
                    const _FieldLabel('状态'),
                    const SizedBox(height: 7),
                    ComboBox<String>(
                      value: _status,
                      isExpanded: true,
                      items: const [
                        ComboBoxItem(value: 'open', child: Text('待处理')),
                        ComboBoxItem(value: 'investigating', child: Text('调查中')),
                        ComboBoxItem(value: 'resolved', child: Text('已解决')),
                        ComboBoxItem(value: 'archived', child: Text('已归档')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _status = value);
                      },
                    ),
                    const SizedBox(height: 18),
                    const _FieldLabel('严重程度'),
                    const SizedBox(height: 7),
                    ComboBox<String>(
                      value: _severity,
                      isExpanded: true,
                      items: const [
                        ComboBoxItem(value: 'low', child: Text('低')),
                        ComboBoxItem(value: 'medium', child: Text('中')),
                        ComboBoxItem(value: 'high', child: Text('高')),
                        ComboBoxItem(value: 'critical', child: Text('严重')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _severity = value);
                      },
                    ),
                    const SizedBox(height: 18),
                    const _FieldLabel('影响'),
                    const SizedBox(height: 7),
                    TextBox(controller: _impact, minLines: 2, maxLines: 4),
                    const SizedBox(height: 18),
                    const _FieldLabel('当前假设'),
                    const SizedBox(height: 7),
                    TextBox(controller: _hypothesis, minLines: 3, maxLines: 5),
                    const SizedBox(height: 18),
                    const _FieldLabel('下一步调查'),
                    const SizedBox(height: 7),
                    TextBox(controller: _nextStep, minLines: 3, maxLines: 5),
                    if (_status == 'resolved' || _resolution.text.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const _FieldLabel('解决说明'),
                      const SizedBox(height: 7),
                      TextBox(controller: _resolution, minLines: 3, maxLines: 5),
                    ],
                    const SizedBox(height: 20),
                    const _FieldLabel('关联任务'),
                    const SizedBox(height: 8),
                    FutureBuilder<List<TaskModel>>(
                      future: _linkedTasks,
                      builder: (context, snapshot) {
                        final tasks = snapshot.data ?? const <TaskModel>[];
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const ProgressRing(strokeWidth: 2);
                        }
                        if (tasks.isNotEmpty) {
                          return Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: tasks
                                .map((task) => _IssueBadge(text: task.title))
                                .toList(),
                          );
                        }
                        return Text(
                          '暂未关联任务',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.typography.body?.color?.withValues(alpha: 0.55),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<TaskModel?>(
                      future: _currentTask,
                      builder: (context, snapshot) {
                        final task = snapshot.data;
                        if (task == null) return const SizedBox.shrink();
                        return Button(
                          onPressed: _linking ? null : _linkCurrentTask,
                          child: Text(_linking
                              ? '关联中…'
                              : '关联当前任务：${task.title}'),
                        );
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text('操作失败：$_error', style: const TextStyle(fontSize: 11)),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: theme.inactiveColor.withValues(alpha: 0.12)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Button(onPressed: widget.onCancel, child: const Text('取消')),
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
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    );
  }
}

class _IssueBadge extends StatelessWidget {
  const _IssueBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).inactiveColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10)),
    );
  }
}
