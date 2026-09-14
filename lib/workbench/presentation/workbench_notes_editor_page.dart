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
          title: const Text('新建 Markdown 笔记'),
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

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Row(
        children: [
          SizedBox(
            width: 250,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _createNote,
                      child: const Text('新建笔记'),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      final selected = note.id == _selected?.id;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(9, 2, 9, 2),
                        child: Button(
                          onPressed: () => _selectNote(note),
                          style: ButtonStyle(
                            backgroundColor: ButtonState.all(
                              selected
                                  ? FluentTheme.of(context)
                                      .accentColor
                                      .normal
                                      .withOpacity(0.10)
                                  : Colors.transparent,
                            ),
                            padding: ButtonState.all(
                              const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                            ),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  note.filePath.split('/').last,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: FluentTheme.of(context)
                                        .typography
                                        .body
                                        ?.color
                                        ?.withOpacity(0.50),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            color: FluentTheme.of(context).inactiveColor.withOpacity(0.14),
          ),
          Expanded(
            child: _selected == null
                ? const Center(child: Text('新建一条 Markdown 笔记开始记录'))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selected!.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _selected!.filePath,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: FluentTheme.of(context)
                                          .typography
                                          .body
                                          ?.color
                                          ?.withOpacity(0.48),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _saving ? '保存中…' : '已保存',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
