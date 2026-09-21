import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

import '../../theme/theme_controller.dart';
import '../application/ai_conversation_history.dart';
import '../application/ai_prompt_builder.dart';
import '../core/ai_context_models.dart';
import '../core/ai_conversation_models.dart';
import '../core/models.dart';
import '../workbench_runtime.dart';
import 'assistant_markdown.dart';


part 'global_ai_drawer_widgets.dart';
part 'global_ai_drawer_formatters.dart';

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
              width: 500,
              height: 400,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: TextBox(
                            controller: controller,
                            autofocus: true,
                            placeholder: '搜索任务、笔记、问题、资源、决策、知识、项目、命令或代码片段',
                            onSubmitted: (_) => runSearch(),
                          ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.cardBackground,
                                  border: Border.all(color: palette.cardBorder),
                                  borderRadius: BorderRadius.circular(12),
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
                                              style: TextStyle(
                                                fontSize: 10,
                                                height: 1.35,
                                                color: FluentTheme.of(context)
                                                    .typography
                                                    .body
                                                    ?.color
                                                    ?.withValues(alpha: 0.58),
                                              ),
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
            width: 460,
            height: 380,
            child: ListView.separated(
              itemCount: _threads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 7),
              itemBuilder: (context, index) {
                final item = _threads[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: palette.cardBackground,
                    border: Border.all(color: palette.cardBorder),
                    borderRadius: BorderRadius.circular(12),
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
                              style: TextStyle(
                                fontSize: 9.5,
                                color: FluentTheme.of(context)
                                    .typography
                                    .body
                                    ?.color
                                    ?.withValues(alpha: 0.52),
                              ),
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
        history: buildAIConversationHistory(_messages),
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
        history: buildAIConversationHistory(
          _messages,
          excludeTrailingUser: message,
        ),
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
    final drawerWidth = (screenWidth * 0.40).clamp(450.0, 510.0).toDouble();

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
              color: palette.shadow.withValues(alpha: 0.08),
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
        borderRadius: BorderRadius.circular(12),
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
                    color: theme.typography.body?.color?.withValues(alpha: 0.50),
                  ),
                ),
                const Spacer(),
                HyperlinkButton(
                  onPressed: () => setState(
                    () => _contextExpanded = !_contextExpanded,
                  ),
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
}
