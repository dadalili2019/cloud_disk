import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';

import '../core/models.dart';
import '../workbench_runtime.dart';

class WorkbenchNotesEditorPage extends StatefulWidget {
  const WorkbenchNotesEditorPage({
    super.key,
    required this.workspaceId,
  });

  final String workspaceId;

  @override
  State<WorkbenchNotesEditorPage> createState() =>
      _WorkbenchNotesEditorPageState();
}

class _WorkbenchNotesEditorPageState extends State<WorkbenchNotesEditorPage> {
  final TextEditingController _editor = TextEditingController();
  Timer? _saveDebounce;
  List<NoteModel> _notes = const [];
  NoteModel? _selected;
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _editor.addListener(_scheduleSave);
    _loadNotes();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    final note = _selected;
    final content = _editor.text;
    if (_dirty && note != null) {
      unawaited(
        WorkbenchRuntime.instance.then(
          (runtime) => runtime.noteService.saveContent(note, content),
        ),
      );
    }
    _editor
      ..removeListener(_scheduleSave)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadNotes({String? selectId}) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final runtime = await WorkbenchRuntime.instance;
      final notes = await runtime.noteService.listByWorkspace(widget.workspaceId);
      if (!mounted) return;

      setState(() {
        _notes = notes;
        _loading = false;
      });

      if (notes.isEmpty) {
        _selected = null;
        _replaceEditorText('');
        return;
      }

      final selected = notes.firstWhere(
        (note) => note.id == selectId,
        orElse: () => notes.first,
      );
      await _selectNote(selected);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _replaceEditorText(String value) {
    _editor.removeListener(_scheduleSave);
    _editor.text = value;
    _editor.selection = TextSelection.collapsed(offset: value.length);
    _editor.addListener(_scheduleSave);
    _dirty = false;
  }

  Future<void> _selectNote(NoteModel note) async {
    if (_selected?.id == note.id) return;
    await _flushPendingSave();

    final runtime = await WorkbenchRuntime.instance;
    final content = await runtime.noteService.readContent(note);
    if (!mounted) return;

    _replaceEditorText(content);
    setState(() {
      _selected = note;
      _error = null;
    });
  }

  void _scheduleSave() {
    if (_selected == null) return;
    _dirty = true;
    _saveDebounce?.cancel();
    if (mounted) setState(() => _saving = true);
    _saveDebounce = Timer(
      const Duration(milliseconds: 650),
      _flushPendingSave,
    );
  }

  Future<void> _flushPendingSave() async {
    final note = _selected;
    if (!_dirty || note == null) {
      if (mounted) setState(() => _saving = false);
      return;
    }

    _saveDebounce?.cancel();
    final markdown = _editor.text;

    try {
      final runtime = await WorkbenchRuntime.instance;
      await runtime.noteService.saveContent(note, markdown);
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _saving = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _createNote() async {
    final titleController = TextEditingController();
    final fileNameController = TextEditingController();

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => ContentDialog(
          title: const Text('新建笔记'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextBox(
                  controller: titleController,
                  placeholder: '笔记标题',
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextBox(
                  controller: fileNameController,
                  placeholder: '文件名（可选，例如 notes.md）',
                ),
              ],
            ),
          ),
          actions: [
            Button(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('创建'),
            ),
          ],
        ),
      );

      if (result != true || !mounted) return;
      await _flushPendingSave();

      final title = titleController.text.trim();
      final runtime = await WorkbenchRuntime.instance;
      final note = await runtime.noteService.create(
        workspaceId: widget.workspaceId,
        title: title,
        fileName: fileNameController.text.trim(),
        initialContent: '# $title\n\n',
      );
      if (!mounted) return;
      await _loadNotes(selectId: note.id);
    } catch (error) {
      if (!mounted) return;
      await _showError(context, error);
    } finally {
      titleController.dispose();
      fileNameController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: ProgressRing());
    }
    if (_error != null && _notes.isEmpty) {
      return Center(child: Text('加载失败：$_error'));
    }

    final theme = FluentTheme.of(context);
    final textColor = theme.typography.body?.color;

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Row(
        children: [
          Container(
            width: 238,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: theme.inactiveColor.withOpacity(0.14),
                ),
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '全部笔记',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${_notes.length}',
                          style: TextStyle(
                            fontSize: 11,
                            color: textColor?.withOpacity(0.48),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Button(
                          onPressed: _createNote,
                          style: ButtonStyle(
                            padding: ButtonState.all(
                              const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(FluentIcons.add, size: 12),
                              SizedBox(width: 5),
                              Text('新建'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 1,
                  color: theme.inactiveColor.withOpacity(0.10),
                ),
                Expanded(
                  child: _notes.isEmpty
                      ? Center(
                          child: Button(
                            onPressed: _createNote,
                            child: const Text('新建第一条笔记'),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: _notes.length,
                          itemBuilder: (context, index) {
                            final note = _notes[index];
                            final selected = note.id == _selected?.id;
                            return _NoteListItem(
                              note: note,
                              selected: selected,
                              onPressed: () => _selectNote(note),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selected == null
                ? Center(
                    child: Button(
                      onPressed: _createNote,
                      child: const Text('新建笔记'),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selected!.title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(
                                        FluentIcons.page,
                                        size: 11,
                                        color: textColor?.withOpacity(0.42),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _selected!.filePath.split('/').last,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: textColor?.withOpacity(0.46),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            _SaveState(saving: _saving),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: TextBox(
                            controller: _editor,
                            expands: true,
                            minLines: null,
                            maxLines: null,
                            textAlignVertical: TextAlignVertical.top,
                            placeholder: '输入 Markdown 内容',
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '保存失败：$_error',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NoteListItem extends StatelessWidget {
  const _NoteListItem({
    required this.note,
    required this.selected,
    required this.onPressed,
  });

  final NoteModel note;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final accent = theme.accentColor.normal;
    final textColor = theme.typography.body?.color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
            decoration: BoxDecoration(
              color: selected ? accent.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border(
                left: BorderSide(
                  color: selected ? accent : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  note.filePath.split('/').last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: textColor?.withOpacity(0.44),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveState extends StatelessWidget {
  const _SaveState({required this.saving});

  final bool saving;

  @override
  Widget build(BuildContext context) {
    final textColor = FluentTheme.of(context).typography.body?.color;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (saving)
            const SizedBox(
              width: 10,
              height: 10,
              child: ProgressRing(strokeWidth: 1.2),
            )
          else
            Icon(
              FluentIcons.check_mark,
              size: 10,
              color: textColor?.withOpacity(0.46),
            ),
          const SizedBox(width: 5),
          Text(
            saving ? '保存中…' : '已保存',
            style: TextStyle(
              fontSize: 10,
              color: textColor?.withOpacity(0.48),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showError(BuildContext context, Object error) {
  return showDialog<void>(
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
}
