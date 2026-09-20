part of 'workbench_knowledge_page.dart';

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
    const fieldGap = 10.0;

    Widget field({
      required String label,
      required Widget child,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          child,
        ],
      );
    }

    return ContentDialog(
      title: Text(
        widget.existing == null ? '新建知识' : '编辑知识',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      constraints: const BoxConstraints(
        maxWidth: 640,
        maxHeight: 620,
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.sources.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '来源',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: FluentTheme.of(context)
                          .typography
                          .body
                          ?.color
                          ?.withValues(alpha: 0.62),
                    ),
                  ),
                  ...widget.sources.map(
                    (source) => _SourceChip(
                      type: source.entityType,
                      title: source.title,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 520) {
                  return Column(
                    children: [
                      field(
                        label: '标题',
                        child: TextBox(
                          controller: _title,
                          autofocus: true,
                        ),
                      ),
                      const SizedBox(height: fieldGap),
                      field(
                        label: '分类',
                        child: TextBox(
                          controller: _category,
                          placeholder: 'Engineering / AI / Workflow',
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: field(
                        label: '标题',
                        child: TextBox(
                          controller: _title,
                          autofocus: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: field(
                        label: '分类',
                        child: TextBox(
                          controller: _category,
                          placeholder: 'Engineering / AI / Workflow',
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: fieldGap),
            LayoutBuilder(
              builder: (context, constraints) {
                final summary = field(
                  label: '摘要',
                  child: TextBox(
                    controller: _summary,
                    minLines: 2,
                    maxLines: 3,
                    placeholder: '一句话概括',
                  ),
                );
                final useWhen = field(
                  label: '适用场景',
                  child: TextBox(
                    controller: _useWhen,
                    minLines: 2,
                    maxLines: 3,
                    placeholder: '适合在什么情况下复用',
                  ),
                );

                if (constraints.maxWidth < 520) {
                  return Column(
                    children: [
                      summary,
                      const SizedBox(height: fieldGap),
                      useWhen,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: summary),
                    const SizedBox(width: 12),
                    Expanded(child: useWhen),
                  ],
                );
              },
            ),
            const SizedBox(height: fieldGap),
            field(
              label: '内容',
              child: TextBox(
                controller: _markdown,
                minLines: 6,
                maxLines: 9,
                placeholder: 'Markdown',
              ),
            ),
            const SizedBox(height: 10),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 82,
              child: Button(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 82,
              child: FilledButton(
                onPressed: _save,
                child: const Text('保存'),
              ),
            ),
          ],
        ),
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
