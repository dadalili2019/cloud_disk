import 'package:fluent_ui/fluent_ui.dart';

import '../application/ai_prompt_builder.dart';
import '../core/ai_context_models.dart';
import '../core/ai_conversation_models.dart';
import '../core/models.dart';
import '../workbench_runtime.dart';
import 'assistant_markdown.dart';

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
  final ScrollController _scrollController = ScrollController();

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
  String? _pendingUserMessage;
  String? _failedMessage;
  Object? _failedError;

  bool _loading = true;
  bool _sending = false;
  bool _previewing = false;
  bool _contextExpanded = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
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

  void _clearFailure() {
    _failedMessage = null;
    _failedError = null;
  }

  Future<void> _setWorkspace(String? value) async {
    setState(() {
      _workspaceId = value;
      _taskId = null;
      _tasks = const [];
      _thread = null;
      _messages = const [];
      _preview = null;
      _contextExpanded = false;
      _clearFailure();
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
      _contextExpanded = false;
      _clearFailure();
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
    setState(() => _manuallyExcluded = [..._manuallyExcluded, ref]);
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
                width: 540,
                height: 430,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextBox(
                            controller: controller,
                            autofocus: true,
                            placeholder: '搜索任务、笔记、问题、资源、决策或知识',
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
                              child: Text('输入关键词搜索需要加入的工作上下文。'),
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

  Future<void> _showHistoryDialog() async {
    if (_threads.isEmpty) return;
    final selected = await showDialog<AIThreadModel>(
      context: context,
      builder: (dialogContext) => ContentDialog(
        title: const Text('历史会话'),
        content: SizedBox(
          width: 500,
          height: 420,
          child: ListView.separated(
            itemCount: _threads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final item = _threads[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: FluentTheme.of(context).inactiveColor.withOpacity(0.14),
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
                            item.title.isEmpty ? '未命名会话' : item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_scopeLabel(item.scope)} · ${_formatDateTime(item.updatedAt)}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Button(
                      onPressed: () => Navigator.pop(dialogContext, item),
                      child: const Text('打开'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('关闭'),
          ),
        ],
      ),
    );

    if (selected != null) await _openThread(selected);
  }

  Future<void> _openThread(AIThreadModel value) async {
    final runtime = _runtime;
    if (runtime == null) return;
    final messages = await runtime.aiConversationService.listMessages(value.id);
    List<TaskModel> tasks = _tasks;
    if (value.workspaceId != null && value.workspaceId != _workspaceId) {
      tasks = await runtime.taskService.listByWorkspace(value.workspaceId!);
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
      _contextExpanded = false;
      _clearFailure();
      _resetContextOverrides();
    });
    _scrollToBottom();
  }

  void _newThread() {
    setState(() {
      _thread = null;
      _messages = const [];
      _preview = null;
      _error = null;
      _pendingUserMessage = null;
      _contextExpanded = false;
      _clearFailure();
      _resetContextOverrides();
    });
  }

  List<AIConversationTurn> _historyForPrompt({String? excludeTrailingUser}) {
    final source = _messages
        .where((item) => item.role == 'user' || item.role == 'assistant')
        .toList(growable: false);
    var end = source.length;
    if (excludeTrailingUser != null &&
        source.isNotEmpty &&
        source.last.role == 'user' &&
        source.last.content.trim() == excludeTrailingUser.trim()) {
      end--;
    }
    return source
        .take(end)
        .map((item) => AIConversationTurn(role: item.role, content: item.content))
        .toList(growable: false);
  }

  Future<void> _send() async {
    final runtime = _runtime;
    final message = _messageController.text.trim();
    if (runtime == null || message.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _pendingUserMessage = message;
      _error = null;
      _clearFailure();
    });
    _scrollToBottom();

    AIThreadModel? thread = _thread;
    var userPersisted = false;
    try {
      final request = _request(query: message);
      final rawContext = await runtime.aiContextBuilder.build(request);
      final context = runtime.aiContextBudget.apply(rawContext);
      final prompt = runtime.aiPromptBuilder.build(
        context: context,
        userMessage: message,
        history: _historyForPrompt(),
      );

      thread ??= await runtime.aiConversationService.createThread(
        scope: _scope,
        workspaceId: request.workspaceId,
        taskId: request.taskId,
        knowledgeId: request.knowledgeId,
      );

      await runtime.aiConversationService.addUserMessage(
        thread: thread,
        content: message,
      );
      userPersisted = true;

      final response = await runtime.aiProvider.complete(prompt);
      await runtime.aiConversationService.addAssistantMessage(
        thread: thread,
        content: response,
        context: context,
      );

      await _refreshConversation(thread.id, request: request);
      if (!mounted) return;
      _messageController.clear();
      setState(() {
        _pendingUserMessage = null;
        _clearFailure();
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      if (thread != null && userPersisted) {
        final messages = await runtime.aiConversationService.listMessages(thread.id);
        final refreshedThread = await runtime.aiConversationService.getThread(thread.id);
        final threads = await runtime.aiConversationService.listThreads();
        if (!mounted) return;
        _messageController.clear();
        setState(() {
          _thread = refreshedThread ?? thread;
          _messages = messages;
          _threads = threads;
          _pendingUserMessage = null;
          _failedMessage = message;
          _failedError = error;
          _error = null;
        });
      } else {
        setState(() {
          _pendingUserMessage = null;
          _error = error;
        });
      }
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _retryFailed() async {
    final runtime = _runtime;
    final thread = _thread;
    final message = _failedMessage;
    if (runtime == null || thread == null || message == null || _sending) return;

    setState(() {
      _sending = true;
      _error = null;
      _failedError = null;
    });
    _scrollToBottom();

    try {
      final request = _request(query: message);
      final rawContext = await runtime.aiContextBuilder.build(request);
      final context = runtime.aiContextBudget.apply(rawContext);
      final prompt = runtime.aiPromptBuilder.build(
        context: context,
        userMessage: message,
        history: _historyForPrompt(excludeTrailingUser: message),
      );

      final response = await runtime.aiProvider.complete(prompt);
      await runtime.aiConversationService.addAssistantMessage(
        thread: thread,
        content: response,
        context: context,
      );

      await _refreshConversation(thread.id, request: request);
      if (!mounted) return;
      setState(_clearFailure);
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() => _failedError = error);
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _refreshConversation(
    String threadId, {
    AIContextRequest? request,
  }) async {
    final runtime = _runtime;
    if (runtime == null) return;
    final refreshedThread = await runtime.aiConversationService.getThread(threadId);
    final messages = await runtime.aiConversationService.listMessages(threadId);
    final threads = await runtime.aiConversationService.listThreads();
    AIContextPreviewModel? preview = _preview;
    if (request != null) {
      preview = await runtime.aiContextPreviewService.preview(request);
    }
    if (!mounted) return;
    setState(() {
      if (refreshedThread != null) _thread = refreshedThread;
      _messages = messages;
      _threads = threads;
      _preview = preview;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth < 980 ? screenWidth * 0.72 : 620.0)
        .clamp(460.0, 680.0)
        .toDouble();

    return Container(
      width: drawerWidth,
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
                _scopeSection(theme),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                    child: InfoBar(
                      title: const Text('AI 操作失败'),
                      content: Text(_readableError(_error!)),
                      severity: InfoBarSeverity.error,
                      isLong: true,
                    ),
                  ),
                const SizedBox(height: 6),
                Expanded(child: _body(theme)),
                _composer(theme),
              ],
            ),
    );
  }

  Widget _header(FluentThemeData theme) {
    final providerName = _runtime?.aiProvider.name ?? 'Loading Provider';
    final isPreview = providerName.toLowerCase().contains('preview');
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 15, 12, 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.inactiveColor.withOpacity(0.12)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.accentColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(FluentIcons.chat_bot, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Workbench AI',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentContextLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.typography.body?.color?.withOpacity(0.58),
                  ),
                ),
              ],
            ),
          ),
          _statusBadge(isPreview ? 'Preview' : _shortProviderName(providerName), theme),
          const SizedBox(width: 6),
          if (_threads.isNotEmpty)
            Tooltip(
              message: '历史会话',
              child: IconButton(
                icon: const Icon(FluentIcons.history, size: 14),
                onPressed: _showHistoryDialog,
              ),
            ),
          Tooltip(
            message: '新建会话',
            child: IconButton(
              icon: const Icon(FluentIcons.add, size: 13),
              onPressed: _newThread,
            ),
          ),
          Tooltip(
            message: '关闭',
            child: IconButton(
              icon: const Icon(FluentIcons.chrome_close, size: 13),
              onPressed: widget.onClose,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scopeSection(FluentThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.inactiveColor.withOpacity(0.10)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _scopeSelector(theme),
          const SizedBox(height: 10),
          _anchorControls(theme),
        ],
      ),
    );
  }

  Widget _scopeSelector(FluentThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.inactiveColor.withOpacity(0.10)),
      ),
      child: Row(
        children: AIContextScope.values.map((scope) {
          final selected = scope == _scope;
          return Expanded(
            child: GestureDetector(
              onTap: () => _setScope(scope),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.accentColor.withOpacity(0.13)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  _scopeShortLabel(scope),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _anchorControls(FluentThemeData theme) {
    final controls = <Widget>[];

    if (_scope == AIContextScope.workspace || _scope == AIContextScope.task) {
      controls.add(
        Expanded(
          child: ComboBox<String>(
            value: _workspaceId,
            isExpanded: true,
            placeholder: const Text('选择 Workspace'),
            items: _workspaces
                .map((item) => ComboBoxItem(value: item.id, child: Text(item.name)))
                .toList(),
            onChanged: _setWorkspace,
          ),
        ),
      );
    }

    if (_scope == AIContextScope.task) {
      if (controls.isNotEmpty) controls.add(const SizedBox(width: 8));
      controls.add(
        Expanded(
          child: ComboBox<String>(
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
              _contextExpanded = false;
              _clearFailure();
              _resetContextOverrides();
            }),
          ),
        ),
      );
    }

    if (_scope == AIContextScope.knowledge) {
      controls.add(
        Expanded(
          child: ComboBox<String>(
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
              _contextExpanded = false;
              _clearFailure();
              _resetContextOverrides();
            }),
          ),
        ),
      );
    }

    if (_scope == AIContextScope.global) {
      controls.add(
        Expanded(
          child: Text(
            '根据当前问题检索少量相关工作上下文。',
            style: TextStyle(
              fontSize: 10,
              color: theme.typography.body?.color?.withOpacity(0.55),
            ),
          ),
        ),
      );
    }

    controls.add(const SizedBox(width: 8));
    controls.add(
      Button(
        onPressed: _previewing ? null : _previewContext,
        child: Text(_previewing ? '整理中…' : '查看上下文'),
      ),
    );

    return Row(children: controls);
  }

  Widget _body(FluentThemeData theme) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      children: [
        if (_preview != null) _contextPreview(theme, _preview!),
        if (_messages.isEmpty && _preview == null && !_sending)
          _emptyState(theme),
        ..._messages.map((message) => _messageBubble(theme, message)),
        if (_pendingUserMessage != null)
          _pendingUserBubble(theme, _pendingUserMessage!),
        if (_sending) _thinkingBubble(theme),
        if (_failedMessage != null && !_sending)
          _failureBubble(theme),
      ],
    );
  }

  Widget _emptyState(FluentThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(
            FluentIcons.chat_bot,
            size: 28,
            color: theme.typography.body?.color?.withOpacity(0.24),
          ),
          const SizedBox(height: 12),
          const Text(
            '选择工作上下文，然后开始提问',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _contextPreview(FluentThemeData theme, AIContextPreviewModel preview) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: theme.inactiveColor.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            child: Row(
              children: [
                const Text(
                  'Context',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Text(
                  '${preview.included.length} 项 · ${_formatCharacters(preview.totalCharacters)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.typography.body?.color?.withOpacity(0.55),
                  ),
                ),
                const Spacer(),
                Button(
                  onPressed: () => setState(() => _contextExpanded = !_contextExpanded),
                  child: Text(_contextExpanded ? '收起' : '管理'),
                ),
              ],
            ),
          ),
          if (!_contextExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 11),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...preview.included.take(6).map(
                        (item) => _contextChip(
                          '${_entityLabel(item.ref.entityType)} · ${item.ref.title}',
                          theme,
                        ),
                      ),
                  if (preview.included.length > 6)
                    _contextChip('+${preview.included.length - 6}', theme),
                  if (preview.excluded.isNotEmpty)
                    _contextChip('已排除 ${preview.excluded.length}', theme),
                ],
              ),
            ),
          if (_contextExpanded) ...[
            Container(height: 1, color: theme.inactiveColor.withOpacity(0.09)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '发送给 AI 的上下文',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Button(
                        onPressed: _showAddContextDialog,
                        child: const Text('添加上下文'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...preview.included.map((item) => _contextRow(theme, item)),
                  if (preview.excluded.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      '已排除',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    ...preview.excluded.map(
                      (ref) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_entityLabel(ref.entityType)} · ${ref.title}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
            ),
          ],
        ],
      ),
    );
  }

  Widget _contextRow(FluentThemeData theme, AIContextPreviewItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withOpacity(0.45),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              'P${item.priority}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${_entityLabel(item.ref.entityType)} · ${item.ref.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10),
            ),
          ),
          IconButton(
            icon: const Icon(FluentIcons.remove, size: 10),
            onPressed: () => _excludeContext(item.ref),
          ),
        ],
      ),
    );
  }

  Widget _contextChip(String text, FluentThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.inactiveColor.withOpacity(0.10)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 9.5),
      ),
    );
  }

  Widget _messageBubble(FluentThemeData theme, AIMessageModel message) {
    final user = message.role == 'user';
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: user ? theme.accentColor.withOpacity(0.12) : theme.cardColor,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: theme.inactiveColor.withOpacity(0.10)),
        ),
        child: user
            ? SelectableText(
                message.content,
                style: const TextStyle(fontSize: 11.5, height: 1.45),
              )
            : AssistantMarkdown(data: message.content),
      ),
    );
  }

  Widget _pendingUserBubble(FluentThemeData theme, String message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.accentColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(message, style: const TextStyle(fontSize: 11.5, height: 1.45)),
      ),
    );
  }

  Widget _thinkingBubble(FluentThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: theme.inactiveColor.withOpacity(0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: ProgressRing(strokeWidth: 1.5),
            ),
            const SizedBox(width: 8),
            Text(
              'Thinking…',
              style: TextStyle(
                fontSize: 10.5,
                color: theme.typography.body?.color?.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _failureBubble(FluentThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFD13438).withOpacity(0.38)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI 回复失败',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              _readableError(_failedError ?? 'Unknown provider error.'),
              style: TextStyle(
                fontSize: 10,
                height: 1.4,
                color: theme.typography.body?.color?.withOpacity(0.66),
              ),
            ),
            const SizedBox(height: 8),
            Button(
              onPressed: _retryFailed,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composer(FluentThemeData theme) {
    final contextCount = _preview?.included.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 9, 18, 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.inactiveColor.withOpacity(0.10)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _currentContextLabel(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: theme.typography.body?.color?.withOpacity(0.55),
                    ),
                  ),
                ),
                if (contextCount != null)
                  Text(
                    '$contextCount contexts',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: theme.typography.body?.color?.withOpacity(0.55),
                    ),
                  ),
              ],
            ),
          ),
          Row(
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
        ],
      ),
    );
  }

  Widget _statusBadge(String text, FluentThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.inactiveColor.withOpacity(0.12)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 9),
      ),
    );
  }

  String _currentContextLabel() {
    return switch (_scope) {
      AIContextScope.task => _taskId == null
          ? 'Current Task · 未选择任务'
          : 'Current Task · ${_taskTitle(_taskId!)}',
      AIContextScope.workspace => _workspaceId == null
          ? 'Workspace · 未选择工作区'
          : 'Workspace · ${_workspaceName(_workspaceId!)}',
      AIContextScope.knowledge => _knowledgeId == null
          ? 'Knowledge · 未选择知识'
          : 'Knowledge · ${_knowledgeTitle(_knowledgeId!)}',
      AIContextScope.global => 'Global · 根据问题检索相关上下文',
    };
  }

  String _workspaceName(String id) {
    for (final item in _workspaces) {
      if (item.id == id) return item.name;
    }
    return id;
  }

  String _taskTitle(String id) {
    for (final item in _tasks) {
      if (item.id == id) return item.title;
    }
    return id;
  }

  String _knowledgeTitle(String id) {
    for (final item in _knowledge) {
      if (item.id == id) return item.title;
    }
    return id;
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

String _scopeShortLabel(AIContextScope scope) {
  return switch (scope) {
    AIContextScope.task => 'Task',
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

String _shortProviderName(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return 'AI';
  if (normalized.length <= 18) return normalized;
  return '${normalized.substring(0, 18)}…';
}

String _formatCharacters(int value) {
  if (value < 1000) return '$value chars';
  return '${(value / 1000).toStringAsFixed(1)}k chars';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month-$day $hour:$minute';
}

String _readableError(Object error) {
  var value = error.toString().trim();
  value = value.replaceFirst(RegExp(r'^(StateError|Exception):\s*'), '');
  if (value.length > 280) value = '${value.substring(0, 280)}…';
  return value;
}
