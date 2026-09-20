import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../application/knowledge_distill_service.dart';
import '../core/models.dart';
import '../workbench_runtime.dart';
import 'workbench_knowledge_distill_dialog.dart';
import 'workbench_ui.dart';


part 'workbench_knowledge_cards.dart';
part 'workbench_knowledge_editor.dart';
part 'workbench_knowledge_support.dart';

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

