import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

import '../../theme/theme_controller.dart';
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

      var scope = AIContextScope.global;
      String? workspaceId;
      String? taskId;
      var tasks = const <TaskModel>[];

      if (widget.currentLocation == '/home') {
        final snapshot = await runtime.continueService.load();
        final primary = snapshot.primary;
        if (primary != null) {
          workspaceId = primary.workspace.id;
          taskId = primary.context.task.id;
          tasks = await runtime.taskService.listByWorkspace(workspaceId);
          scope = AIContextScope.task;
        }
      } else {
        final match = RegExp(r'^/workspace/([^/]+)').firstMatch(widget.currentLocation);
        workspaceId = match?.group(1);
        if (workspaceId != null &&
            workspaces.any((item) => item.id == workspaceId)) {
          tasks = await runtime.taskService.listByWorkspace(workspaceId);
          final currentTask = await runtime.taskService.getCurrent(workspaceId);
          if (currentTask != null) {
            taskId = currentTask.id;
            scope = AIContextScope.task;
          } else {
            scope = AIContextScope.workspace;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _runtime = runtime;
        _workspaces = workspaces;
        _knowledge = knowledge;
        _threads = threads;
        _workspaceId = workspaceId;
        _taskId = taskId;
        _tasks = tasks;
        _scope = scope;
        _loading = false;
      });

      if (_anchorReady()) await _previewContext();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  bool _anchorReady() {
    return switch (_scope) {
      AIContextScope.task => _taskId != null,
      AIContextScope.workspace => _workspaceId != null,
      AIContextScope.knowledge => _knowledgeId != null,
      AIContextScope.global => false,
    };
  }

  void _resetConversation() {
    _thread = null;
    _messages = const [];
    _preview = null;
    _contextExpanded = false;
    _failedMessage = null;
    _failedError = null;
    _manuallyIncluded = const [];
    _manuallyExcluded = const [];
  }

  Future<void> _setWorkspace(String? value) async {
    setState(() {
      _workspaceId = value;
      _taskId = null;
      _tasks = const [];
      _resetConversation();
    });
    if (value == null || _runtime == null) return;

    final tasks = await _runtime!.taskService.listByWorkspace(value);
    final currentTask = _scope == AIContextScope.task
        ? await _runtime!.taskService.getCurrent(value)
        : null;
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _taskId = currentTask?.id;
    });
    if (_anchorReady()) await _previewContext();
  }

  Future<void> _setScope(AIContextScope scope) async {
    if (scope == _scope) return;
    setState(() {
      _scope = scope;
      _resetConversation();
      if (scope == AIContextScope.global) {
        _taskId = null;
        _knowledgeId = null;
      } else if (scope == AIContextScope.knowledge) {
        _taskId = null;
      } else {
        _knowledgeId = null;
      }
    });

    if (scope == AIContextScope.task &&
        _workspaceId != null &&
        _runtime != null) {
      final currentTask = await _runtime!.taskService.getCurrent(_workspaceId!);
      if (!mounted) return;
      setState(() => _taskId = currentTask?.id);
    }

    if (_anchorReady()) await _previewContext();
  }

  Future<void> _setTask(String? value) async {
    setState(() {
      _taskId = value;
      _resetConversation();
    });
    if (value != null) await _previewContext();
  }

  Future<void> _setKnowledge(String? value) async {
    setState(() {
      _knowledgeId = value;
      _resetConversation();
    });
    if (value != null) await _previewContext();
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
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final palette = ThemeScope.of(context).palette;

          Future<void> runSearch() async {
            final query = controller.text.trim();
            if (query.isEmpty || searching) return;
            setDialogState(() {
              searching = true;
              dialogError = null;
            });
            try {
              final found = await runtime.searchService.searchFresh(
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
                          placeholder: '搜索任务、笔记、问题、资源、决策、知识、项目、命令或代码片段',
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
                        ? const Center(child: Text('输入关键词搜索需要加入的工作上下文。'))
                        : ListView.separated(
                            itemCount: results.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 7),
                            itemBuilder: (context, index) {
                              final item = results[index];
                              final key = '${item.entityType}:${item.entityId}';
                              final alreadyIncluded = _manuallyIncluded
                                  .any((ref) => ref.key == key);
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: palette.cardBackground,
                                  border: Border.all(color: palette.cardBorder),
                                  borderRadius: BorderRadius.circular(10),
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
                                          if (item.snippet.trim().isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              item.snippet,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                          ],
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
      ),
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
      builder: (dialogContext) {
        final palette = ThemeScope.of(dialogContext).palette;
        return ContentDialog(
          title: const Text('历史会话'),
          content: SizedBox(
            width: 480,
            height: 400,
            child: ListView.separated(
              itemCount: _threads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 7),
              itemBuilder: (context, index) {
                final item = _threads[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: palette.cardBackground,
                    border: Border.all(color: palette.cardBorder),
                    borderRadius: BorderRadius.circular(10),
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
        );
      },
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
      _failedMessage = null;
      _failedError = null;
      _manuallyIncluded = const [];
      _manuallyExcluded = const [];
    });
    _scrollToBottom();
  }

  void _newThread() {
    setState(() {
      _thread = null;
      _messages = const [];
      _error = null;
      _pendingUserMessage = null;
      _failedMessage = null;
      _failedError = null;
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
      _failedMessage = null;
      _failedError = null;
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
      setState(() => _pendingUserMessage = null);
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
      setState(() {
        _failedMessage = null;
        _failedError = null;
      });
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
    final palette = ThemeScope.of(context).palette;
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth * 0.42).clamp(460.0, 520.0).toDouble();

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _send,
        const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
      },
      child: Container(
        width: drawerWidth,
        height: double.infinity,
        decoration: BoxDecoration(
          color: palette.appBackground,
          border: Border(left: BorderSide(color: palette.cardBorder)),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(-4, 0),
              color: palette.shadow.withOpacity(0.08),
            ),
          ],
        ),
        child: _loading
            ? const Center(child: ProgressRing())
            : Column(
                children: [
                  _header(theme, palette),
                  _scopeSection(theme, palette),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: InfoBar(
                        title: const Text('AI 操作失败'),
                        content: Text(_readableError(_error!)),
                        severity: InfoBarSeverity.error,
                        isLong: true,
                      ),
                    ),
                  Expanded(child: _body(theme, palette)),
                  _composer(theme, palette),
                ],
              ),
      ),
    );
  }

  Widget _header(FluentThemeData theme, ThemePalette palette) {
    final providerName = _runtime?.aiProvider.name ?? 'Loading Provider';
    final isPreview = providerName.toLowerCase().contains('preview');
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 13),
      decoration: BoxDecoration(
        color: palette.appBarBackground,
        border: Border(bottom: BorderSide(color: palette.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: palette.successSoft,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: palette.cardBorder),
            ),
            child: Icon(
              FluentIcons.chat_bot,
              size: 16,
              color: theme.accentColor.normal,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Workbench AI',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  _headerContextLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: theme.typography.body?.color?.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          _statusBadge(isPreview ? 'Preview' : _shortProviderName(providerName), palette),
          const SizedBox(width: 4),
          if (_threads.isNotEmpty)
            Tooltip(
              message: '历史会话',
              child: IconButton(
                icon: const Icon(FluentIcons.history, size: 13),
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

  Widget _scopeSection(FluentThemeData theme, ThemePalette palette) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: palette.appBackground,
        border: Border(bottom: BorderSide(color: palette.cardBorder)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: palette.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.cardBorder),
            ),
            child: Row(
              children: AIContextScope.values.map((scope) {
                final selected = scope == _scope;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _setScope(scope),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? palette.navItemSelected : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _scopeShortLabel(scope),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? theme.accentColor.normal : null,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ),
          const SizedBox(height: 10),
          _anchorControls(),
        ],
      ),
    );
  }

  Widget _anchorControls() {
    final buttonLabel = _previewing
        ? '整理中…'
        : _preview == null
            ? '查看上下文'
            : '刷新';

    if (_scope == AIContextScope.global) {
      return Align(
        alignment: Alignment.centerRight,
        child: Button(
          onPressed: _previewing ? null : _previewContext,
          child: Text(buttonLabel),
        ),
      );
    }

    final controls = <Widget>[];
    if (_scope == AIContextScope.workspace || _scope == AIContextScope.task) {
      controls.add(
        Expanded(
          child: ComboBox<String>(
            value: _workspaceId,
            isExpanded: true,
            placeholder: const Text('选择工作区'),
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
            placeholder: const Text('选择任务'),
            items: _tasks
                .map((item) => ComboBoxItem(value: item.id, child: Text(item.title)))
                .toList(),
            onChanged: _setTask,
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
            placeholder: const Text('选择知识'),
            items: _knowledge
                .map((item) => ComboBoxItem(value: item.id, child: Text(item.title)))
                .toList(),
            onChanged: _setKnowledge,
          ),
        ),
      );
    }

    controls.add(const SizedBox(width: 8));
    controls.add(
      Button(
        onPressed: _previewing ? null : _previewContext,
        child: Text(buttonLabel),
      ),
    );
    return Row(children: controls);
  }

  Widget _body(FluentThemeData theme, ThemePalette palette) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      children: [
        if (_preview != null) _contextPreview(theme, palette, _preview!),
        if (_messages.isEmpty && _preview == null && !_sending)
          _emptyState(theme),
        ..._messages.map((message) => _messageBubble(theme, palette, message)),
        if (_pendingUserMessage != null)
          _pendingUserBubble(palette, _pendingUserMessage!),
        if (_sending) _thinkingBubble(theme, palette),
        if (_failedMessage != null && !_sending)
          _failureBubble(theme, palette),
      ],
    );
  }

  Widget _emptyState(FluentThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 54),
      child: Column(
        children: [
          Icon(
            FluentIcons.chat_bot,
            size: 27,
            color: theme.typography.body?.color?.withOpacity(0.20),
          ),
          const SizedBox(height: 12),
          Text(
            _emptyStateText(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _contextPreview(
    FluentThemeData theme,
    ThemePalette palette,
    AIContextPreviewModel preview,
  ) {
    final nonActivity = preview.included
        .where((item) => item.ref.entityType != 'activity')
        .toList(growable: false);
    final visibleNonActivity = nonActivity.take(5).toList(growable: false);
    final hiddenNonActivity = nonActivity.length - visibleNonActivity.length;
    final activityCount = preview.included
        .where((item) => item.ref.entityType == 'activity')
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 11),
            child: Row(
              children: [
                const Text(
                  '上下文',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Text(
                  '${preview.included.length} 项 · ${_formatCharacters(preview.totalCharacters)}',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: theme.typography.body?.color?.withOpacity(0.50),
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
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 13),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...visibleNonActivity.map(
                    (item) => _contextChip(
                      '${_entityLabel(item.ref.entityType)} · ${item.ref.title}',
                      palette,
                    ),
                  ),
                  if (activityCount > 0)
                    _contextChip('活动 · $activityCount 条', palette),
                  if (hiddenNonActivity > 0)
                    _contextChip('其他 · $hiddenNonActivity 条', palette),
                  if (preview.excluded.isNotEmpty)
                    _contextChip('已排除 ${preview.excluded.length}', palette),
                ],
              ),
            ),
          if (_contextExpanded) ...[
            Container(height: 1, color: palette.cardBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '发送给 AI 的上下文',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Button(
                        onPressed: _showAddContextDialog,
                        child: const Text('添加上下文'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  ...preview.included.map(
                    (item) => _contextRow(palette, item),
                  ),
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

  Widget _contextRow(ThemePalette palette, AIContextPreviewItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              'P${item.priority}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 5),
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

  Widget _contextChip(String text, ThemePalette palette) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 9.5),
      ),
    );
  }

  Widget _messageBubble(
    FluentThemeData theme,
    ThemePalette palette,
    AIMessageModel message,
  ) {
    final user = message.role == 'user';
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: user ? palette.navItemSelected : palette.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.cardBorder),
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

  Widget _pendingUserBubble(ThemePalette palette, String message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: palette.navItemSelected,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.cardBorder),
        ),
        child: Text(message, style: const TextStyle(fontSize: 11.5, height: 1.45)),
      ),
    );
  }

  Widget _thinkingBubble(FluentThemeData theme, ThemePalette palette) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: palette.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.cardBorder),
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
              '正在思考…',
              style: TextStyle(
                fontSize: 10.5,
                color: theme.typography.body?.color?.withOpacity(0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _failureBubble(FluentThemeData theme, ThemePalette palette) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD13438).withOpacity(0.35)),
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
                color: theme.typography.body?.color?.withOpacity(0.62),
              ),
            ),
            const SizedBox(height: 8),
            Button(onPressed: _retryFailed, child: const Text('重试')),
          ],
        ),
      ),
    );
  }

  Widget _composer(FluentThemeData theme, ThemePalette palette) {
    final contextCount = _preview?.included.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: palette.appBarBackground,
        border: Border(top: BorderSide(color: palette.cardBorder)),
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
                    _composerContextLabel(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: theme.typography.body?.color?.withOpacity(0.50),
                    ),
                  ),
                ),
                if (contextCount != null)
                  Text(
                    '$contextCount 条上下文',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: theme.typography.body?.color?.withOpacity(0.50),
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
          const SizedBox(height: 4),
          Text(
            'Ctrl + Enter 发送',
            style: TextStyle(
              fontSize: 8.5,
              color: theme.typography.body?.color?.withOpacity(0.32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, ThemePalette palette) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 8.5),
      ),
    );
  }

  String _headerContextLabel() {
    return switch (_scope) {
      AIContextScope.task => _taskId == null
          ? '当前任务'
          : '当前任务 · ${_taskTitle(_taskId!)}',
      AIContextScope.workspace => _workspaceId == null
          ? '工作区'
          : '工作区 · ${_workspaceName(_workspaceId!)}',
      AIContextScope.knowledge => _knowledgeId == null
          ? '知识'
          : '知识 · ${_knowledgeTitle(_knowledgeId!)}',
      AIContextScope.global => '全局',
    };
  }

  String _composerContextLabel() {
    return switch (_scope) {
      AIContextScope.global => '全局 · 自动检索相关上下文',
      _ => _headerContextLabel(),
    };
  }

  String _emptyStateText() {
    return switch (_scope) {
      AIContextScope.task => _taskId == null
          ? '请选择一个任务'
          : '围绕当前任务提问，我会自动组织相关上下文',
      AIContextScope.workspace => _workspaceId == null
          ? '请选择一个工作区'
          : '围绕当前工作区提问，我会组织相关工作上下文',
      AIContextScope.knowledge => _knowledgeId == null
          ? '请选择一条知识'
          : '围绕当前知识提问，并结合它的来源上下文',
      AIContextScope.global => '输入问题，我会根据当前范围组织相关上下文',
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
    AIContextScope.task => '任务',
    AIContextScope.workspace => '工作区',
    AIContextScope.knowledge => '知识',
    AIContextScope.global => '全局',
  };
}

String _scopeShortLabel(AIContextScope scope) {
  return switch (scope) {
    AIContextScope.task => '任务',
    AIContextScope.workspace => '工作区',
    AIContextScope.knowledge => '知识',
    AIContextScope.global => '全局',
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
    'developer_project' => '项目',
    'developer_command' => '命令',
    'developer_snippet' => '代码片段',
    _ => type,
  };
}

String _shortProviderName(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return 'AI';
  if (normalized.length <= 16) return normalized;
  return '${normalized.substring(0, 16)}…';
}

String _formatCharacters(int value) {
  if (value < 1000) return '$value 字符';
  return '${(value / 1000).toStringAsFixed(1)}k 字符';
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
