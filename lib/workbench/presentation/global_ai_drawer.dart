import 'package:fluent_ui/fluent_ui.dart';

import '../application/ai_prompt_builder.dart';
import '../core/ai_context_models.dart';
import '../core/ai_conversation_models.dart';
import '../core/models.dart';
import '../workbench_runtime.dart';

class GlobalAiDrawer extends StatefulWidget {
  const GlobalAiDrawer({
    super.key,
    required this.onClose,
    required this.currentLocation,
  });

  final VoidCallback onClose;
  final String currentLocation;

  @override
  State<GlobalAiDrawer> createState() => _GlobalAiDrawerState();
}

class _GlobalAiDrawerState extends State<GlobalAiDrawer> {
  final TextEditingController _messageController = TextEditingController();
  WorkbenchRuntime? _runtime;
  AIContextScope _scope = AIContextScope.global;
  List<WorkspaceModel> _workspaces = const [];
  List<TaskModel> _tasks = const [];
  List<KnowledgeModel> _knowledge = const [];
  List<AIThreadModel> _threads = const [];
  List<AIMessageModel> _messages = const [];
  List<AIContextRef> _manuallyIncluded = const [];
  List<AIContextRef> _manuallyExcluded = const [];
  AIThreadModel? _thread;
  AIContextPreviewModel? _preview;
  String? _workspaceId;
  String? _taskId;
  String? _knowledgeId;
  bool _loading = true;
  bool _sending = false;
  bool _previewing = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final runtime = await WorkbenchRuntime.instance;
      final workspaces = await runtime.workspaceService.listActive();
      final knowledge = await runtime.knowledgeService.list();
      final threads = await runtime.aiConversationService.listThreads();

      String? routeWorkspaceId;
      final match = RegExp(r'^/workspace/([^/]+)').firstMatch(widget.currentLocation);
      if (match != null) routeWorkspaceId = match.group(1);

      var scope = AIContextScope.global;
      if (routeWorkspaceId != null &&
          workspaces.any((item) => item.id == routeWorkspaceId)) {
        scope = AIContextScope.workspace;
      }

      var tasks = const <TaskModel>[];
      if (routeWorkspaceId != null) {
        tasks = await runtime.taskService.listByWorkspace(routeWorkspaceId);
      }

      if (!mounted) return;
      setState(() {
        _runtime = runtime;
        _workspaces = workspaces;
        _knowledge = knowledge;
        _threads = threads;
        _workspaceId = routeWorkspaceId;
        _tasks = tasks;
        _scope = scope;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  void _resetContextOverrides() {
    _manuallyIncluded = const [];
    _manuallyExcluded = const [];
  }

  Future<void> _setWorkspace(String? value) async {
    setState(() {
      _workspaceId = value;
      _taskId = null;
      _tasks = const [];
      _thread = null;
      _messages = const [];
      _preview = null;
      _resetContextOverrides();
    });
    if (value == null || _runtime == null) return;
    final tasks = await _runtime!.taskService.listByWorkspace(value);
    if (!mounted) return;
    setState(() => _tasks = tasks);
  }

  void _setScope(AIContextScope? scope) {
    if (scope == null || scope == _scope) return;
    setState(() {
      _scope = scope;
      _thread = null;
      _messages = const [];
      _preview = null;
      _resetContextOverrides();
      if (scope == AIContextScope.global) {
        _taskId = null;
        _knowledgeId = null;
      } else if (scope == AIContextScope.knowledge) {
        _taskId = null;
      } else {
        _knowledgeId = null;
      }
    });
  }

  AIContextRequest _request({String query = ''}) {
    return AIContextRequest(
      scope: _scope,
      query: query,
      workspaceId: _scope == AIContextScope.workspace || _scope == AIContextScope.task
          ? _workspaceId
          : null,
      taskId: _scope == AIContextScope.task ? _taskId : null,
      knowledgeId: _scope == AIContextScope.knowledge ? _knowledgeId : null,
      manuallyIncludedEntities: _manuallyIncluded,
      manuallyExcludedEntities: _manuallyExcluded,
    );
  }

  Future<void> _previewContext() async {
    final runtime = _runtime;
    if (runtime == null) return;
    setState(() {
      _previewing = true;
      _error = null;
    });
    try {
      final preview = await runtime.aiContextPreviewService.preview(
        _request(query: _messageController.text),
      );
      if (!mounted) return;
      setState(() => _preview = preview);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  Future<void> _excludeContext(AIContextRef ref) async {
    if (_manuallyExcluded.any((item) => item.key == ref.key)) return;
    setState(() {
      _manuallyExcluded = [..._manuallyExcluded, ref];
    });
    await _previewContext();
  }

  Future<void> _restoreContext(AIContextRef ref) async {
    setState(() {
      _manuallyExcluded = _manuallyExcluded
          .where((item) => item.key != ref.key)
          .toList(growable: false);
    });
    await _previewContext();
  }

  Future<void> _showAddContextDialog() async {
    final runtime = _runtime;
    if (runtime == null) return;

    final controller = TextEditingController();
    var results = const <SearchResultModel>[];
    var searching = false;
    Object? dialogError;

    final selected = await showDialog<AIContextRef>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> runSearch() async {
              final query = controller.text.trim();
              if (query.isEmpty || searching) return;
              setDialogState(() {
                searching = true;
                dialogError = null;
              });
              try {
                final found = await runtime.searchService.search(
                  query,
                  workspaceId: _scope == AIContextScope.workspace ||
                          _scope == AIContextScope.task
                      ? _workspaceId
                      : null,
                  limit: 20,
                );
                setDialogState(() => results = found);
              } catch (error) {
                setDialogState(() => dialogError = error);
              } finally {
                setDialogState(() => searching = false);
              }
            }

            return ContentDialog(
              title: const Text('添加上下文'),
              content: SizedBox(
                width: 520,
                height: 420,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextBox(
                            controller: controller,
                            autofocus: true,
                            placeholder: '搜索 Task / Note / Issue / Resource / Decision / Knowledge',
                            onSubmitted: (_) => runSearch(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Button(
                          onPressed: searching ? null : runSearch,
                          child: Text(searching ? '搜索中…' : '搜索'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (dialogError != null)
                      InfoBar(
                        title: const Text('搜索失败'),
                        content: Text('$dialogError'),
                        severity: InfoBarSeverity.error,
                      ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: results.isEmpty
                          ? const Center(
                              child: Text(
                                '输入关键词搜索需要额外加入的工作上下文。',
                                style: TextStyle(fontSize: 12),
                              ),
                            )
                          : ListView.separated(
                              itemCount: results.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                final item = results[index];
                                final key = '${item.entityType}:${item.entityId}';
                                final alreadyIncluded = _manuallyIncluded
                                    .any((ref) => ref.key == key);
                                return Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: FluentTheme.of(context)
                                          .inactiveColor
                                          .withOpacity(0.14),
                                    ),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${_entityLabel(item.entityType)} · ${item.title}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (item.snippet.trim().isNotEmpty)
                                              Text(
                                                item.snippet,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Button(
                                        onPressed: alreadyIncluded
                                            ? null
                                            : () => Navigator.pop(
                                                  dialogContext,
                                                  AIContextRef(
                                                    entityType: item.entityType,
                                                    entityId: item.entityId,
                                                    title: item.title,
                                                    workspaceId: item.workspaceId,
                                                  ),
                                                ),
                                        child: Text(alreadyIncluded ? '已添加' : '添加'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                Button(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('关闭'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();

    if (selected == null || !mounted) return;
    setState(() {
      if (!_manuallyIncluded.any((item) => item.key == selected.key)) {
        _manuallyIncluded = [..._manuallyIncluded, selected];
      }
      _manuallyExcluded = _manuallyExcluded
          .where((item) => item.key != selected.key)
          .toList(growable: false);
    });
    await _previewContext();
  }

  Future<void> _openThread(AIThreadModel? value) async {
    if (value == null || _runtime == null) return;
    final messages = await _runtime!.aiConversationService.listMessages(value.id);
    List<TaskModel> tasks = _tasks;
    if (value.workspaceId != null && value.workspaceId != _workspaceId) {
      tasks = await _runtime!.taskService.listByWorkspace(value.workspaceId!);
    }
    if (!mounted) return;
    setState(() {
      _thread = value;
      _scope = value.scope;
      _workspaceId = value.workspaceId;
      _taskId = value.taskId;
      _knowledgeId = value.knowledgeId;
      _tasks = tasks;
      _messages = messages;
      _preview = null;
      _resetContextOverrides();
    });
  }

  void _newThread() {
    setState(() {
      _thread = null;
      _messages = const [];
      _preview = null;
      _error = null;
      _resetContextOverrides();
    });
  }

  Future<void> _send() async {
    final runtime = _runtime;
    final message = _messageController.text.trim();
    if (runtime == null || message.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final request = _request(query: message);
      final rawContext = await runtime.aiContextBuilder.build(request);
      final context = runtime.aiContextBudget.apply(rawContext);
      final history = _messages
          .where((item) => item.role == 'user' || item.role == 'assistant')
          .map((item) => AIConversationTurn(role: item.role, content: item.content))
          .toList(growable: false);
      final prompt = runtime.aiPromptBuilder.build(
        context: context,
        userMessage: message,
        history: history,
      );

      var thread = _thread;
      if (thread == null) {
        thread = await runtime.aiConversationService.createThread(
          scope: _scope,
          workspaceId: request.workspaceId,
          taskId: request.taskId,
          knowledgeId: request.knowledgeId,
        );
      }

      await runtime.aiConversationService.addUserMessage(
        thread: thread,
        content: message,
      );
      final response = await runtime.aiProvider.complete(prompt);
      await runtime.aiConversationService.addAssistantMessage(
        thread: thread,
        content: response,
        context: context,
      );

      final refreshedThread = await runtime.aiConversationService.getThread(thread.id);
      final messages = await runtime.aiConversationService.listMessages(thread.id);
      final threads = await runtime.aiConversationService.listThreads();
      final preview = await runtime.aiContextPreviewService.preview(request);

      if (!mounted) return;
      _messageController.clear();
      setState(() {
        _thread = refreshedThread ?? thread;
        _messages = messages;
        _threads = threads;
        _preview = preview;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      width: 430,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(left: BorderSide(color: theme.inactiveColor.withOpacity(0.18))),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(-4, 0),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: _loading
          ? const Center(child: ProgressRing())
          : Column(
              children: [
                _header(theme),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: InfoBar(
                      title: const Text('AI 操作失败'),
                      content: Text('$_error'),
                      severity: InfoBarSeverity.error,
                      isLong: true,
                    ),
                  ),
                _controls(),
                const SizedBox(height: 8),
                Expanded(child: _body(theme)),
                _composer(),
              ],
            ),
    );
  }

  Widget _header(FluentThemeData theme) {
    final providerName = _runtime?.aiProvider.name ?? 'Loading Provider';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
      child: Row(
        children: [
          const Icon(FluentIcons.chat_bot, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Workbench AI',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(providerName, style: const TextStyle(fontSize: 10)),
              ],
            ),
          ),
          IconButton(icon: const Icon(FluentIcons.add, size: 13), onPressed: _newThread),
          IconButton(icon: const Icon(FluentIcons.chrome_close, size: 13), onPressed: widget.onClose),
        ],
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ComboBox<AIContextScope>(
                  value: _scope,
                  isExpanded: true,
                  items: AIContextScope.values
                      .map((scope) => ComboBoxItem(value: scope, child: Text(_scopeLabel(scope))))
                      .toList(),
                  onChanged: _setScope,
                ),
              ),
              const SizedBox(width: 8),
              Button(
                onPressed: _previewing ? null : _previewContext,
                child: Text(_previewing ? '整理中…' : '查看上下文'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_scope == AIContextScope.workspace || _scope == AIContextScope.task)
            ComboBox<String>(
              value: _workspaceId,
              isExpanded: true,
              placeholder: const Text('选择 Workspace'),
              items: _workspaces
                  .map((item) => ComboBoxItem(value: item.id, child: Text(item.name)))
                  .toList(),
              onChanged: _setWorkspace,
            ),
          if (_scope == AIContextScope.task) ...[
            const SizedBox(height: 8),
            ComboBox<String>(
              value: _taskId,
              isExpanded: true,
              placeholder: const Text('选择 Task'),
              items: _tasks
                  .map((item) => ComboBoxItem(value: item.id, child: Text(item.title)))
                  .toList(),
              onChanged: (value) => setState(() {
                _taskId = value;
                _thread = null;
                _messages = const [];
                _preview = null;
                _resetContextOverrides();
              }),
            ),
          ],
          if (_scope == AIContextScope.knowledge)
            ComboBox<String>(
              value: _knowledgeId,
              isExpanded: true,
              placeholder: const Text('选择 Knowledge'),
              items: _knowledge
                  .map((item) => ComboBoxItem(value: item.id, child: Text(item.title)))
                  .toList(),
              onChanged: (value) => setState(() {
                _knowledgeId = value;
                _thread = null;
                _messages = const [];
                _preview = null;
                _resetContextOverrides();
              }),
            ),
          if (_threads.isNotEmpty) ...[
            const SizedBox(height: 8),
            ComboBox<AIThreadModel>(
              value: _thread,
              isExpanded: true,
              placeholder: const Text('历史会话'),
              items: _threads
                  .map((item) => ComboBoxItem(
                        value: item,
                        child: Text(item.title.isEmpty ? '未命名会话' : item.title),
                      ))
                  .toList(),
              onChanged: _openThread,
            ),
          ],
        ],
      ),
    );
  }

  Widget _body(FluentThemeData theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      children: [
        if (_preview != null) _contextPreview(theme, _preview!),
        if (_messages.isEmpty && _preview == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                '先选择 Scope，再查看 AI 将使用的上下文。',
                style: TextStyle(fontSize: 12, color: theme.typography.body?.color?.withOpacity(0.55)),
              ),
            ),
          ),
        ..._messages.map((message) => _messageBubble(theme, message)),
      ],
    );
  }

  Widget _contextPreview(FluentThemeData theme, AIContextPreviewModel preview) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.inactiveColor.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Context Preview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              Button(
                onPressed: _showAddContextDialog,
                child: const Text('添加上下文'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${preview.included.length} 项 · ${preview.totalCharacters} 字符',
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(height: 8),
          ...preview.included.take(12).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('P${item.priority}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_entityLabel(item.ref.entityType)} · ${item.ref.title}', style: const TextStyle(fontSize: 11)),
                            if (item.preview.isNotEmpty)
                              Text(
                                item.preview,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10, color: theme.typography.body?.color?.withOpacity(0.55)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(FluentIcons.remove, size: 11),
                        onPressed: () => _excludeContext(item.ref),
                      ),
                    ],
                  ),
                ),
              ),
          if (preview.excluded.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              '已排除',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ...preview.excluded.map(
              (ref) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_entityLabel(ref.entityType)} · ${ref.title}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    Button(
                      onPressed: () => _restoreContext(ref),
                      child: const Text('恢复'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _messageBubble(FluentThemeData theme, AIMessageModel message) {
    final user = message.role == 'user';
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: user ? theme.accentColor.withOpacity(0.12) : theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.inactiveColor.withOpacity(0.12)),
        ),
        child: Text(message.content, style: const TextStyle(fontSize: 11, height: 1.4)),
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextBox(
              controller: _messageController,
              minLines: 2,
              maxLines: 5,
              placeholder: '问问当前工作上下文…',
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _sending ? null : _send,
            child: Text(_sending ? '处理中…' : '发送'),
          ),
        ],
      ),
    );
  }
}

String _scopeLabel(AIContextScope scope) {
  return switch (scope) {
    AIContextScope.task => 'Current Task',
    AIContextScope.workspace => 'Workspace',
    AIContextScope.knowledge => 'Knowledge',
    AIContextScope.global => 'Global',
  };
}

String _entityLabel(String type) {
  return switch (type) {
    'task' => '任务',
    'note' => '笔记',
    'issue' => '问题',
    'resource' => '资源',
    'decision' => '决策',
    'knowledge' => '知识',
    'workspace' => '工作区',
    'activity' => '活动',
    _ => type,
  };
}
