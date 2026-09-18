import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../application/knowledge_distill_service.dart';
import '../core/models.dart';
import '../workbench_runtime.dart';
import 'workbench_knowledge_distill_dialog.dart';
import 'workbench_ui.dart';

class WorkbenchKnowledgePage extends StatefulWidget {
  const WorkbenchKnowledgePage({super.key});

  @override
  State<WorkbenchKnowledgePage> createState() => _WorkbenchKnowledgePageState();
}

class _WorkbenchKnowledgePageState extends State<WorkbenchKnowledgePage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _loading = true;
  bool _rebuilding = false;
  Object? _error;
  List<KnowledgeModel> _knowledge = const [];
  List<SearchResultModel> _results = const [];
  String _category = '';

  @override
  void initState() {
    super.initState();
    _load(rebuildIndex: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool rebuildIndex = false}) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        if (rebuildIndex) _rebuilding = true;
      });
    }
    try {
      final runtime = await WorkbenchRuntime.instance;
      if (rebuildIndex) await runtime.searchService.rebuildIndex();
      final items = await runtime.knowledgeService.list(
        category: _category.isEmpty ? null : _category,
      );
      if (!mounted) return;
      setState(() {
        _knowledge = items;
        _loading = false;
        _rebuilding = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _rebuilding = false;
        _error = error;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _search(value));
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    if (query.isEmpty) {
      if (mounted) setState(() => _results = const []);
      return;
    }
    try {
      final runtime = await WorkbenchRuntime.instance;
      final results = await runtime.searchService.search(query, limit: 60);
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() => _results = results);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  Future<void> _distillFromWorkspace() async {
    final changed = await showKnowledgeDistillDialog(context);
    if (!changed || !mounted) return;
    await _load();
    if (_searchController.text.trim().isNotEmpty) {
      await _search(_searchController.text);
    }
  }

  Future<void> _openEditor([KnowledgeModel? existing]) async {
    final runtime = await WorkbenchRuntime.instance;
    final markdown = existing == null
        ? ''
        : await runtime.knowledgeService.readContent(existing);
    final sources = existing == null
        ? const <KnowledgeSourceContext>[]
        : await runtime.knowledgeDistillService.sourceContexts(existing);
    if (!mounted) return;

    final draft = await showDialog<_KnowledgeDraft>(
      context: context,
      builder: (_) => _KnowledgeEditorDialog(
        existing: existing,
        markdown: markdown,
        sources: sources,
      ),
    );
    if (draft == null) return;

    try {
      if (existing == null) {
        await runtime.knowledgeService.create(
          title: draft.title,
          category: draft.category,
          summary: draft.summary,
          useWhen: draft.useWhen,
          markdown: draft.markdown,
          isPinned: draft.isPinned,
        );
      } else {
        await runtime.knowledgeService.update(
          item: existing,
          title: draft.title,
          category: draft.category,
          summary: draft.summary,
          useWhen: draft.useWhen,
          markdown: draft.markdown,
          isPinned: draft.isPinned,
        );
      }
      await _load();
      if (_searchController.text.trim().isNotEmpty) {
        await _search(_searchController.text);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  Future<void> _openKnowledgeResult(String id) async {
    final runtime = await WorkbenchRuntime.instance;
    final item = await runtime.knowledgeService.getById(id);
    if (item != null && mounted) await _openEditor(item);
  }

  void _openSearchResult(SearchResultModel result) {
    if (result.entityType == 'knowledge') {
      _openKnowledgeResult(result.entityId);
      return;
    }
    final workspaceId = result.workspaceId;
    if (workspaceId == null) return;
    final section = switch (result.entityType) {
      'task' => 'tasks',
      'note' => 'notes',
      'issue' => 'issues',
      'resource' => 'resources',
      'decision' => 'decisions',
      'developer_project' || 'developer_command' || 'developer_snippet' =>
        'developer',
      _ => 'overview',
    };
    context.go('/workspace/$workspaceId/$section');
  }

  List<String> get _categories {
    final values = _knowledge
        .map((item) => item.category.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final searching = _searchController.text.trim().isNotEmpty;

    return WorkbenchPage(
      title: '知识',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final searchBox = SizedBox(
              height: 40,
              child: TextBox(
                controller: _searchController,
                placeholder: '搜索知识、任务、笔记、问题、资源…',
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 11),
                  child: Icon(FluentIcons.search, size: 15),
                ),
                suffix: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(FluentIcons.clear, size: 13),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _results = const []);
                        },
                      ),
                onChanged: (value) {
                  setState(() {});
                  _onSearchChanged(value);
                },
              ),
            );

            final actions = Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                Button(
                  onPressed: _distillFromWorkspace,
                  child: const Text('沉淀'),
                ),
                Button(
                  onPressed: _rebuilding ? null : () => _load(rebuildIndex: true),
                  child: Text(_rebuilding ? '重建中…' : '重建索引'),
                ),
                FilledButton(
                  onPressed: () => _openEditor(),
                  child: const Text('新建'),
                ),
              ],
            );

            if (constraints.maxWidth < 760) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  searchBox,
                  const SizedBox(height: 14),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: searchBox),
                const SizedBox(width: 12),
                actions,
              ],
            );
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          InfoBar(
            title: const Text('操作失败'),
            content: Text('$_error'),
            severity: InfoBarSeverity.error,
            isLong: true,
          ),
        ],
        const SizedBox(height: 20),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 70),
            child: Center(child: ProgressRing()),
          )
        else if (searching)
          _SearchResults(
            query: _searchController.text.trim(),
            results: _results,
            onOpen: _openSearchResult,
          )
        else ...[
          if (_categories.isNotEmpty) ...[
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                WorkbenchTag(
                  label: '全部',
                  selected: _category.isEmpty,
                  onTap: () {
                    setState(() => _category = '');
                    _load();
                  },
                ),
                ..._categories.map(
                  (category) => WorkbenchTag(
                    label: category,
                    selected: _category == category,
                    onTap: () {
                      setState(() => _category = category);
                      _load();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          if (_categories.isEmpty) ...[
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_knowledge.length} 条',
                style: TextStyle(
                  fontSize: 10.5,
                  color: theme.typography.body?.color?.withValues(alpha: 0.50),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (_knowledge.isEmpty)
            WorkbenchEmptyState(
              title: '还没有沉淀知识',
              description: '',
              actionLabel: '新建',
              onAction: () => _openEditor(),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 950
                    ? 3
                    : constraints.maxWidth >= 620
                        ? 2
                        : 1;
                const gap = 16.0;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: _knowledge
                      .map(
                        (item) => SizedBox(
                          width: width,
                          child: _KnowledgeCard(
                            item: item,
                            onTap: () => _openEditor(item),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ],
    );
  }
}

class _KnowledgeCard extends StatelessWidget {
  const _KnowledgeCard({required this.item, required this.onTap});

  final KnowledgeModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return WorkbenchCard(
      onTap: onTap,
      minHeight: 156,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (item.category.isNotEmpty) WorkbenchTag(label: item.category),
              const Spacer(),
              if (item.isPinned) const Icon(FluentIcons.pinned, size: 12),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          if (item.summary.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              item.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: theme.typography.body?.color?.withValues(alpha: 0.65),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.results,
    required this.onOpen,
  });

  final String query;
  final List<SearchResultModel> results;
  final ValueChanged<SearchResultModel> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    if (results.isEmpty) {
      return WorkbenchCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Text(
          '没有找到“$query”相关内容',
          style: TextStyle(
            fontSize: 11.5,
            color: theme.typography.body?.color?.withValues(alpha: 0.56),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkbenchSectionHeader(title: '搜索结果  ${results.length}'),
        const SizedBox(height: 10),
        ...results.map(
          (result) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: WorkbenchCard(
              onTap: () => onOpen(result),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WorkbenchTag(label: _entityLabel(result.entityType)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (result.snippet.trim().isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            result.snippet.replaceAll('[', '').replaceAll(']', ''),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.45,
                              color: theme.typography.body?.color?.withValues(alpha: 0.60),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(FluentIcons.chevron_right, size: 11),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KnowledgeDraft {
  const _KnowledgeDraft({
    required this.title,
    required this.category,
    required this.summary,
    required this.useWhen,
    required this.markdown,
    required this.isPinned,
  });

  final String title;
  final String category;
  final String summary;
  final String useWhen;
  final String markdown;
  final bool isPinned;
}

class _KnowledgeEditorDialog extends StatefulWidget {
  const _KnowledgeEditorDialog({
    required this.existing,
    required this.markdown,
    required this.sources,
  });

  final KnowledgeModel? existing;
  final String markdown;
  final List<KnowledgeSourceContext> sources;

  @override
  State<_KnowledgeEditorDialog> createState() => _KnowledgeEditorDialogState();
}

class _KnowledgeEditorDialogState extends State<_KnowledgeEditorDialog> {
  late final TextEditingController _title;
  late final TextEditingController _category;
  late final TextEditingController _summary;
  late final TextEditingController _useWhen;
  late final TextEditingController _markdown;
  late bool _pinned;
  String? _validation;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _title = TextEditingController(text: item?.title ?? '');
    _category = TextEditingController(text: item?.category ?? '');
    _summary = TextEditingController(text: item?.summary ?? '');
    _useWhen = TextEditingController(text: item?.useWhen ?? '');
    _markdown = TextEditingController(text: widget.markdown);
    _pinned = item?.isPinned ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _summary.dispose();
    _useWhen.dispose();
    _markdown.dispose();
    super.dispose();
  }

  void _save() {
    if (_title.text.trim().isEmpty) {
      setState(() => _validation = '标题不能为空');
      return;
    }
    Navigator.of(context).pop(
      _KnowledgeDraft(
        title: _title.text,
        category: _category.text,
        summary: _summary.text,
        useWhen: _useWhen.text,
        markdown: _markdown.text,
        isPinned: _pinned,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(widget.existing == null ? '新建知识' : '编辑知识'),
      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 740),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.sources.isNotEmpty) ...[
              const Text(
                '来源上下文',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.sources
                    .map(
                      (source) => _SourceChip(
                        type: source.entityType,
                        title: source.title,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            const Text('标题', style: TextStyle(fontSize: 11)),
            const SizedBox(height: 5),
            TextBox(controller: _title, autofocus: true),
            const SizedBox(height: 12),
            const Text('分类', style: TextStyle(fontSize: 11)),
            const SizedBox(height: 5),
            TextBox(
              controller: _category,
              placeholder: '例如 Engineering / AI / Workflow',
            ),
            const SizedBox(height: 12),
            const Text('摘要', style: TextStyle(fontSize: 11)),
            const SizedBox(height: 5),
            TextBox(
              controller: _summary,
              minLines: 2,
              maxLines: 4,
              placeholder: '用一句话概括这条知识。',
            ),
            const SizedBox(height: 12),
            const Text('适用场景', style: TextStyle(fontSize: 11)),
            const SizedBox(height: 5),
            TextBox(
              controller: _useWhen,
              minLines: 2,
              maxLines: 4,
              placeholder: '什么情况下适合复用这条知识？',
            ),
            const SizedBox(height: 12),
            const Text(
              '可复用内容 / Markdown',
              style: TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 5),
            TextBox(
              controller: _markdown,
              minLines: 7,
              maxLines: 14,
              placeholder: '写下可复用的原则、步骤、检查清单或示例…',
            ),
            const SizedBox(height: 12),
            ToggleSwitch(
              checked: _pinned,
              onChanged: (value) => setState(() => _pinned = value),
              content: const Text('置顶'),
            ),
            if (_validation != null) ...[
              const SizedBox(height: 8),
              Text(
                _validation!,
                style: const TextStyle(
                  color: Color(0xFFD13438),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.type, required this.title});

  final String type;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: WorkbenchTag(label: '${_entityLabel(type)} · $title'),
    );
  }
}

String _entityLabel(String type) {
  return switch (type) {
    'task' => '任务',
    'note' => '笔记',
    'issue' => '问题',
    'resource' => '资源',
    'decision' => '决策',
    'knowledge' => '知识',
    'developer_project' => '项目',
    'developer_command' => '命令',
    'developer_snippet' => '代码片段',
    _ => type,
  };
}
