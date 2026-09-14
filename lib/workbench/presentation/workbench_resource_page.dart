import 'package:fluent_ui/fluent_ui.dart';

import '../core/models.dart';
import '../workbench_runtime.dart';

class WorkbenchResourcePage extends StatefulWidget {
  const WorkbenchResourcePage({super.key, required this.workspaceId});
  final String workspaceId;

  @override
  State<WorkbenchResourcePage> createState() => _WorkbenchResourcePageState();
}

class _WorkbenchResourcePageState extends State<WorkbenchResourcePage> {
  late Future<List<ResourceModel>> _resources;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _resources = WorkbenchRuntime.instance.then(
      (runtime) => runtime.resourceService.listByWorkspace(widget.workspaceId),
    );
  }

  Future<void> _createResource() async {
    final name = TextEditingController();
    final uri = TextEditingController();
    final description = TextEditingController();
    var type = 'link';
    var pinned = false;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => ContentDialog(
            title: const Text('新建资源'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextBox(controller: name, placeholder: '资源名称', autofocus: true),
                  const SizedBox(height: 12),
                  ComboBox<String>(
                    value: type,
                    isExpanded: true,
                    items: const [
                      ComboBoxItem(value: 'repository', child: Text('代码仓库')),
                      ComboBoxItem(value: 'local_path', child: Text('本地路径')),
                      ComboBoxItem(value: 'document', child: Text('文档')),
                      ComboBoxItem(value: 'service', child: Text('服务地址')),
                      ComboBoxItem(value: 'link', child: Text('链接')),
                      ComboBoxItem(value: 'design', child: Text('设计资料')),
                      ComboBoxItem(value: 'command', child: Text('命令')),
                      ComboBoxItem(value: 'other', child: Text('其他')),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => type = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextBox(controller: uri, placeholder: '地址 / 路径 / 命令'),
                  const SizedBox(height: 12),
                  TextBox(controller: description, placeholder: '说明（可选）', maxLines: 3),
                  const SizedBox(height: 12),
                  Checkbox(
                    checked: pinned,
                    onChanged: (value) => setDialogState(() => pinned = value ?? false),
                    content: const Text('置顶'),
                  ),
                ],
              ),
            ),
            actions: [
              Button(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('取消')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('创建')),
            ],
          ),
        ),
      );

      if (confirmed != true || !mounted) return;
      final runtime = await WorkbenchRuntime.instance;
      await runtime.resourceService.create(
        workspaceId: widget.workspaceId,
        name: name.text,
        resourceType: type,
        uri: uri.text,
        description: description.text,
        isPinned: pinned,
      );
      if (!mounted) return;
      setState(_reload);
    } catch (error) {
      if (!mounted) return;
      await _showError(error);
    } finally {
      name.dispose();
      uri.dispose();
      description.dispose();
    }
  }

  Future<void> _edit(ResourceModel resource) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _ResourceEditDrawer(
        resource: resource,
        onSaved: () => Navigator.pop(dialogContext, true),
        onCancel: () => Navigator.pop(dialogContext, false),
      ),
    );
    if (changed == true && mounted) setState(_reload);
  }

  Future<void> _showError(Object error) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => ContentDialog(
        title: const Text('操作失败'),
        content: Text(error.toString()),
        actions: [FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('确定'))],
      ),
    );
  }

  String _typeText(String type) {
    switch (type) {
      case 'repository': return '代码仓库';
      case 'local_path': return '本地路径';
      case 'document': return '文档';
      case 'service': return '服务地址';
      case 'design': return '设计资料';
      case 'command': return '命令';
      case 'other': return '其他';
      default: return '链接';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('资源'),
        commandBar: FilledButton(onPressed: _createResource, child: const Text('新建资源')),
      ),
      content: FutureBuilder<List<ResourceModel>>(
        future: _resources,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: ProgressRing());
          if (snapshot.hasError) return Center(child: Text('加载失败：${snapshot.error}'));
          final resources = snapshot.data ?? const <ResourceModel>[];
          if (resources.isEmpty) {
            return Center(child: FilledButton(onPressed: _createResource, child: const Text('新建第一个资源')));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
            itemCount: resources.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final resource = resources[index];
              return FutureBuilder<List<TaskModel>>(
                future: WorkbenchRuntime.instance.then((r) => r.resourceService.linkedTasks(resource)),
                builder: (context, taskSnapshot) {
                  final linked = taskSnapshot.data ?? const <TaskModel>[];
                  final taskText = linked.isEmpty ? '未关联任务' : linked.map((e) => e.title).join('、');
                  return GestureDetector(
                    onTap: () => _edit(resource),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: FluentTheme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: FluentTheme.of(context).inactiveColor.withOpacity(0.16)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text(resource.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                              if (resource.isPinned) const Padding(padding: EdgeInsets.only(right: 8), child: Icon(FluentIcons.pinned, size: 12)),
                              _Badge(_typeText(resource.resourceType)),
                            ]),
                            const SizedBox(height: 8),
                            Text('关联任务：$taskText', style: TextStyle(fontSize: 11, color: FluentTheme.of(context).typography.body?.color?.withOpacity(0.55))),
                            if (resource.uri.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(resource.uri, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                            ],
                            if (resource.description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(resource.description, style: const TextStyle(fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
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

class _ResourceEditDrawer extends StatefulWidget {
  const _ResourceEditDrawer({required this.resource, required this.onSaved, required this.onCancel});
  final ResourceModel resource;
  final VoidCallback onSaved;
  final VoidCallback onCancel;

  @override
  State<_ResourceEditDrawer> createState() => _ResourceEditDrawerState();
}

class _ResourceEditDrawerState extends State<_ResourceEditDrawer> {
  late final TextEditingController _name;
  late final TextEditingController _uri;
  late final TextEditingController _description;
  late String _type;
  late bool _pinned;
  late Future<List<TaskModel>> _linkedTasks;
  late Future<TaskModel?> _currentTask;
  bool _saving = false;
  bool _linking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.resource.name);
    _uri = TextEditingController(text: widget.resource.uri);
    _description = TextEditingController(text: widget.resource.description);
    _type = widget.resource.resourceType;
    _pinned = widget.resource.isPinned;
    _reloadLinks();
  }

  void _reloadLinks() {
    _linkedTasks = WorkbenchRuntime.instance.then((r) => r.resourceService.linkedTasks(widget.resource));
    _currentTask = WorkbenchRuntime.instance.then((r) => r.resourceService.currentTask(widget.resource.workspaceId));
  }

  @override
  void dispose() {
    _name.dispose(); _uri.dispose(); _description.dispose(); super.dispose();
  }

  Future<void> _link() async {
    if (_linking) return;
    setState(() { _linking = true; _error = null; });
    try {
      final runtime = await WorkbenchRuntime.instance;
      await runtime.resourceService.linkToCurrentTask(widget.resource);
      if (!mounted) return;
      setState(() { _linking = false; _reloadLinks(); });
    } catch (e) {
      if (!mounted) return;
      setState(() { _linking = false; _error = e.toString(); });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() { _saving = true; _error = null; });
    try {
      final runtime = await WorkbenchRuntime.instance;
      await runtime.resourceService.update(
        resource: widget.resource,
        name: _name.text,
        resourceType: _type,
        uri: _uri.text,
        description: _description.text,
        isPinned: _pinned,
      );
      if (!mounted) return;
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() { _saving = false; _error = e.toString(); });
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
                const Expanded(child: Text('编辑资源', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                IconButton(icon: const Icon(FluentIcons.chrome_close, size: 14), onPressed: widget.onCancel),
              ]),
            ),
            Container(height: 1, color: theme.inactiveColor.withOpacity(0.12)),
            Expanded(child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
              children: [
                const _Label('资源名称'), const SizedBox(height: 7), TextBox(controller: _name),
                const SizedBox(height: 18), const _Label('类型'), const SizedBox(height: 7),
                ComboBox<String>(
                  value: _type, isExpanded: true,
                  items: const [
                    ComboBoxItem(value: 'repository', child: Text('代码仓库')), ComboBoxItem(value: 'local_path', child: Text('本地路径')),
                    ComboBoxItem(value: 'document', child: Text('文档')), ComboBoxItem(value: 'service', child: Text('服务地址')),
                    ComboBoxItem(value: 'link', child: Text('链接')), ComboBoxItem(value: 'design', child: Text('设计资料')),
                    ComboBoxItem(value: 'command', child: Text('命令')), ComboBoxItem(value: 'other', child: Text('其他')),
                  ],
                  onChanged: (v) { if (v != null) setState(() => _type = v); },
                ),
                const SizedBox(height: 18), const _Label('地址 / 路径 / 命令'), const SizedBox(height: 7), TextBox(controller: _uri),
                const SizedBox(height: 18), const _Label('说明'), const SizedBox(height: 7), TextBox(controller: _description, minLines: 3, maxLines: 5),
                const SizedBox(height: 18), Checkbox(checked: _pinned, onChanged: (v) => setState(() => _pinned = v ?? false), content: const Text('置顶')),
                const SizedBox(height: 20), const _Label('关联任务'), const SizedBox(height: 8),
                FutureBuilder<List<TaskModel>>(
                  future: _linkedTasks,
                  builder: (context, snapshot) {
                    final tasks = snapshot.data ?? const <TaskModel>[];
                    if (tasks.isEmpty) return const Text('暂未关联任务', style: TextStyle(fontSize: 12));
                    return Wrap(spacing: 6, children: tasks.map((e) => _Badge(e.title)).toList());
                  },
                ),
                const SizedBox(height: 10),
                FutureBuilder<TaskModel?>(future: _currentTask, builder: (context, snapshot) {
                  final task = snapshot.data;
                  if (task == null) return const SizedBox.shrink();
                  return Button(onPressed: _linking ? null : _link, child: Text(_linking ? '关联中…' : '关联当前任务：${task.title}'));
                }),
                if (_error != null) ...[const SizedBox(height: 14), Text('操作失败：$_error', style: const TextStyle(fontSize: 11))],
              ],
            )),
            Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.inactiveColor.withOpacity(0.12)))),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Button(onPressed: widget.onCancel, child: const Text('取消')), const SizedBox(width: 10),
                FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? '保存中…' : '保存')),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text); final String text;
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: FluentTheme.of(context).inactiveColor.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
    child: Text(text, style: const TextStyle(fontSize: 10)),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text); final String text;
  @override Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600));
}
