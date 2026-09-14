import 'package:fluent_ui/fluent_ui.dart';

import '../application/knowledge_distill_service.dart';
import '../core/models.dart';
import '../workbench_runtime.dart';

Future<bool> showKnowledgeDistillDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _KnowledgeDistillDialog(),
  );
  return result == true;
}

class _KnowledgeDistillDialog extends StatefulWidget {
  const _KnowledgeDistillDialog();

  @override
  State<_KnowledgeDistillDialog> createState() => _KnowledgeDistillDialogState();
}

class _KnowledgeDistillDialogState extends State<_KnowledgeDistillDialog> {
  late Future<List<WorkspaceModel>> _workspaces;
  String? _workspaceId;
  List<KnowledgeDistillCandidate> _candidates = const [];
  KnowledgeDistillCandidate? _selected;
  bool _loadingCandidates = false;
  bool _saving = false;
  String? _error;

  final _title = TextEditingController();
  final _category = TextEditingController();
  final _summary = TextEditingController();
  final _useWhen = TextEditingController();
  final _markdown = TextEditingController();

  @override
  void initState() {
    super.initState();
    _workspaces = WorkbenchRuntime.instance.then(
      (runtime) => runtime.knowledgeDistillService.listWorkspaces(),
    );
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

  Future<void> _loadCandidates(String workspaceId) async {
    setState(() {
      _workspaceId = workspaceId;
      _loadingCandidates = true;
      _selected = null;
      _error = null;
    });
    try {
      final runtime = await WorkbenchRuntime.instance;
      final values = await runtime.knowledgeDistillService.listCandidates(workspaceId);
      if (!mounted) return;
      setState(() {
        _candidates = values;
        _loadingCandidates = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingCandidates = false;
        _error = error.toString();
      });
    }
  }

  void _select(KnowledgeDistillCandidate candidate) {
    setState(() => _selected = candidate);
    _title.text = candidate.title;
    _category.text = candidate.suggestedCategory;
    _summary.text = candidate.suggestedSummary;
    _useWhen.text = '';
    _markdown.text = candidate.suggestedMarkdown;
  }

  Future<void> _save() async {
    final source = _selected;
    if (source == null || _saving) return;
    if (_title.text.trim().isEmpty) {
      setState(() => _error = '知识标题不能为空');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final runtime = await WorkbenchRuntime.instance;
      await runtime.knowledgeDistillService.distill(
        source: source,
        title: _title.text,
        category: _category.text,
        summary: _summary.text,
        useWhen: _useWhen.text,
        markdown: _markdown.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
    return ContentDialog(
      title: const Text('从工作区沉淀'),
      constraints: const BoxConstraints(maxWidth: 980, maxHeight: 760),
      content: SizedBox(
        width: 930,
        height: 610,
        child: Row(
          children: [
            SizedBox(
              width: 330,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('工作区', style: TextStyle(fontSize: 11)),
                  const SizedBox(height: 6),
                  FutureBuilder<List<WorkspaceModel>>(
                    future: _workspaces,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const ProgressRing();
                      }
                      final workspaces = snapshot.data ?? const <WorkspaceModel>[];
                      if (workspaces.isEmpty) {
                        return const Text('暂无工作区');
                      }
                      return ComboBox<String>(
                        value: _workspaceId,
                        isExpanded: true,
                        placeholder: const Text('选择工作区'),
                        items: workspaces
                            .map((workspace) => ComboBoxItem<String>(
                                  value: workspace.id,
                                  child: Text(workspace.name),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) _loadCandidates(value);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('来源', style: TextStyle(fontSize: 11)),
                  const SizedBox(height: 6),
                  Expanded(
                    child: _workspaceId == null
                        ? const Center(child: Text('先选择工作区'))
                        : _loadingCandidates
                            ? const Center(child: ProgressRing())
                            : _candidates.isEmpty
                                ? const Center(child: Text('当前工作区暂无可沉淀内容'))
                                : ListView.separated(
                                    itemCount: _candidates.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final item = _candidates[index];
                                      final selected = _selected?.sourceId == item.sourceId &&
                                          _selected?.sourceType == item.sourceType;
                                      return GestureDetector(
                                        onTap: () => _select(item),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? theme.accentColor.normal.withOpacity(0.08)
                                                : theme.cardColor,
                                            borderRadius: BorderRadius.circular(7),
                                            border: Border.all(
                                              color: selected
                                                  ? theme.accentColor.normal.withOpacity(0.35)
                                                  : theme.inactiveColor.withOpacity(0.14),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  _SourceTypeBadge(item.sourceType),
                                                  const SizedBox(width: 7),
                                                  Expanded(
                                                    child: Text(
                                                      item.title,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (item.preview.isNotEmpty) ...[
                                                const SizedBox(height: 5),
                                                Text(
                                                  item.preview,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: theme.typography.body?.color?.withOpacity(0.56),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Container(width: 1, color: theme.inactiveColor.withOpacity(0.12)),
            const SizedBox(width: 18),
            Expanded(
              child: _selected == null
                  ? const Center(child: Text('选择一条来源后进行整理'))
                  : ListView(
                      children: [
                        Row(
                          children: [
                            const Text('整理为知识', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            _SourceTypeBadge(_selected!.sourceType),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const _Label('标题'),
                        const SizedBox(height: 6),
                        TextBox(controller: _title),
                        const SizedBox(height: 12),
                        const _Label('分类'),
                        const SizedBox(height: 6),
                        TextBox(controller: _category),
                        const SizedBox(height: 12),
                        const _Label('Summary'),
                        const SizedBox(height: 6),
                        TextBox(controller: _summary, minLines: 2, maxLines: 4),
                        const SizedBox(height: 12),
                        const _Label('Use When'),
                        const SizedBox(height: 6),
                        TextBox(
                          controller: _useWhen,
                          minLines: 2,
                          maxLines: 4,
                          placeholder: '什么情况下值得复用？',
                        ),
                        const SizedBox(height: 12),
                        const _Label('Reusable Pattern / Markdown'),
                        const SizedBox(height: 6),
                        TextBox(controller: _markdown, minLines: 8, maxLines: 13),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: Color(0xFFD13438),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _selected == null || _saving ? null : _save,
          child: Text(_saving ? '保存中…' : '沉淀为知识'),
        ),
      ],
    );
  }
}

class _SourceTypeBadge extends StatelessWidget {
  const _SourceTypeBadge(this.type);
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).inactiveColor.withOpacity(0.09),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(_sourceLabel(type), style: const TextStyle(fontSize: 9)),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600));
  }
}

String _sourceLabel(String type) {
  return switch (type) {
    'task' => '任务',
    'note' => '笔记',
    'issue' => '问题',
    'resource' => '资源',
    'decision' => '决策',
    _ => type,
  };
}
