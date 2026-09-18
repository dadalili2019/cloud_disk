import 'package:fluent_ui/fluent_ui.dart';

import '../core/models.dart';
import '../workbench_runtime.dart';
import 'workbench_ui.dart';

class WorkbenchDecisionPage extends StatefulWidget {
  const WorkbenchDecisionPage({super.key, required this.workspaceId});
  final String workspaceId;

  @override
  State<WorkbenchDecisionPage> createState() => _WorkbenchDecisionPageState();
}

class _WorkbenchDecisionPageState extends State<WorkbenchDecisionPage> {
  late Future<List<DecisionModel>> _decisions;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _decisions = WorkbenchRuntime.instance.then(
      (runtime) => runtime.decisionService.listByWorkspace(widget.workspaceId),
    );
  }

  Future<void> _createDecision() async {
    final title = TextEditingController();
    final decisionText = TextEditingController();
    final rationale = TextEditingController();
    final revisit = TextEditingController();

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => ContentDialog(
          title: const Text('新建决策'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextBox(controller: title, placeholder: '决策名称', autofocus: true),
                const SizedBox(height: 12),
                TextBox(controller: decisionText, placeholder: '决定做什么', maxLines: 3),
                const SizedBox(height: 12),
                TextBox(controller: rationale, placeholder: '为什么这样决定', maxLines: 3),
                const SizedBox(height: 12),
                TextBox(controller: revisit, placeholder: '什么情况下需要重新评估', maxLines: 3),
              ],
            ),
          ),
          actions: [
            Button(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('创建')),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final runtime = await WorkbenchRuntime.instance;
      await runtime.decisionService.create(
        workspaceId: widget.workspaceId,
        title: title.text,
        decisionText: decisionText.text,
        rationale: rationale.text,
        revisitCondition: revisit.text,
      );
      if (!mounted) return;
      setState(_reload);
    } catch (e) {
      if (!mounted) return;
      await _showError(e);
    } finally {
      title.dispose();
      decisionText.dispose();
      rationale.dispose();
      revisit.dispose();
    }
  }

  Future<void> _edit(DecisionModel decision) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _DecisionEditDrawer(
        decision: decision,
        onSaved: () => Navigator.pop(dialogContext, true),
        onCancel: () => Navigator.pop(dialogContext, false),
      ),
    );
    if (changed == true && mounted) setState(_reload);
  }

  Future<void> _showError(Object error) => showDialog<void>(
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

  String _statusText(String status) {
    switch (status) {
      case 'superseded':
        return '已替代';
      case 'archived':
        return '已归档';
      default:
        return '生效中';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return WorkbenchSectionPage(
      title: '决策',
      subtitle: '记录已经做出的选择、原因以及需要重新评估的条件。',
      actions: [
        FilledButton(onPressed: _createDecision, child: const Text('新建决策')),
      ],
      child: FutureBuilder<List<DecisionModel>>(
        future: _decisions,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: ProgressRing());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }
          final decisions = snapshot.data ?? const <DecisionModel>[];
          if (decisions.isEmpty) {
            return WorkbenchEmptyState(
              title: '还没有决策记录',
              description: '把已经确定的选择、原因以及重新评估条件沉淀下来。',
              actionLabel: '新建决策',
              onAction: _createDecision,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: decisions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final decision = decisions[index];
              return FutureBuilder<List<TaskModel>>(
                future: WorkbenchRuntime.instance.then(
                  (r) => r.decisionService.linkedTasks(decision),
                ),
                builder: (context, taskSnapshot) {
                  final linked = taskSnapshot.data ?? const <TaskModel>[];
                  final taskText = linked.isEmpty
                      ? '未关联任务'
                      : linked.map((e) => e.title).join('、');
                  return WorkbenchCard(
                    onTap: () => _edit(decision),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                decision.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            WorkbenchTag(label: _statusText(decision.status)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '关联任务 · $taskText',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: theme.typography.body?.color?.withValues(alpha: 0.52),
                          ),
                        ),
                        if (decision.decisionText.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '决定 · ${decision.decisionText}',
                            style: const TextStyle(fontSize: 11.5),
                          ),
                        ],
                        if (decision.rationale.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            '原因 · ${decision.rationale}',
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

class _DecisionEditDrawer extends StatefulWidget {
  const _DecisionEditDrawer({required this.decision, required this.onSaved, required this.onCancel});
  final DecisionModel decision;
  final VoidCallback onSaved;
  final VoidCallback onCancel;

  @override
  State<_DecisionEditDrawer> createState() => _DecisionEditDrawerState();
}

class _DecisionEditDrawerState extends State<_DecisionEditDrawer> {
  late final TextEditingController _title;
  late final TextEditingController _text;
  late final TextEditingController _rationale;
  late final TextEditingController _revisit;
  late String _status;
  late Future<List<TaskModel>> _linkedTasks;
  late Future<TaskModel?> _currentTask;
  bool _saving = false;
  bool _linking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.decision.title);
    _text = TextEditingController(text: widget.decision.decisionText);
    _rationale = TextEditingController(text: widget.decision.rationale);
    _revisit = TextEditingController(text: widget.decision.revisitCondition);
    _status = widget.decision.status;
    _reloadLinks();
  }

  void _reloadLinks() {
    _linkedTasks = WorkbenchRuntime.instance.then((r) => r.decisionService.linkedTasks(widget.decision));
    _currentTask = WorkbenchRuntime.instance.then((r) => r.decisionService.currentTask(widget.decision.workspaceId));
  }

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    _rationale.dispose();
    _revisit.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    if (_linking) return;
    setState(() {
      _linking = true;
      _error = null;
    });
    try {
      final runtime = await WorkbenchRuntime.instance;
      await runtime.decisionService.linkToCurrentTask(widget.decision);
      if (!mounted) return;
      setState(() {
        _linking = false;
        _reloadLinks();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _linking = false;
        _error = e.toString();
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
      await runtime.decisionService.update(
        decision: widget.decision,
        title: _title.text,
        decisionText: _text.text,
        rationale: _rationale.text,
        revisitCondition: _revisit.text,
        status: _status,
      );
      if (!mounted) return;
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
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
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 14, 14),
              child: Row(children: [
                const Expanded(
                  child: Text(
                    '编辑决策',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(FluentIcons.chrome_close, size: 14),
                  onPressed: widget.onCancel,
                ),
              ]),
            ),
            Container(height: 1, color: theme.inactiveColor.withValues(alpha: 0.12)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                children: [
                  const _Label('决策名称'),
                  const SizedBox(height: 7),
                  TextBox(controller: _title),
                  const SizedBox(height: 18),
                  const _Label('状态'),
                  const SizedBox(height: 7),
                  ComboBox<String>(
                    value: _status,
                    isExpanded: true,
                    items: const [
                      ComboBoxItem(value: 'active', child: Text('生效中')),
                      ComboBoxItem(value: 'superseded', child: Text('已替代')),
                      ComboBoxItem(value: 'archived', child: Text('已归档')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),
                  const SizedBox(height: 18),
                  const _Label('决定做什么'),
                  const SizedBox(height: 7),
                  TextBox(controller: _text, minLines: 3, maxLines: 5),
                  const SizedBox(height: 18),
                  const _Label('为什么这样决定'),
                  const SizedBox(height: 7),
                  TextBox(controller: _rationale, minLines: 3, maxLines: 5),
                  const SizedBox(height: 18),
                  const _Label('重新评估条件'),
                  const SizedBox(height: 7),
                  TextBox(controller: _revisit, minLines: 3, maxLines: 5),
                  const SizedBox(height: 20),
                  const _Label('关联任务'),
                  const SizedBox(height: 8),
                  FutureBuilder<List<TaskModel>>(
                    future: _linkedTasks,
                    builder: (context, snapshot) {
                      final tasks = snapshot.data ?? const <TaskModel>[];
                      if (tasks.isEmpty) {
                        return const Text('暂未关联任务', style: TextStyle(fontSize: 12));
                      }
                      return Wrap(
                        spacing: 6,
                        children: tasks.map((e) => _Badge(e.title)).toList(),
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
                        onPressed: _linking ? null : _link,
                        child: Text(
                          _linking ? '关联中…' : '关联当前任务：${task.title}',
                        ),
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
          ]),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: FluentTheme.of(context).inactiveColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text, style: const TextStyle(fontSize: 10)),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      );
}
