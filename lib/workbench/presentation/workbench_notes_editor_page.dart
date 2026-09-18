import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

import '../../theme/theme_controller.dart';
import '../core/models.dart';
import '../core/workbench_settings.dart';
import '../workbench_runtime.dart';
import 'assistant_markdown.dart';
import 'workbench_ui.dart';

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
  List<TaskModel> _linkedTasks = const [];
  NoteModel? _selected;
  NotesSettings _notesSettings = const NotesSettings();
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
    if (_notesSettings.autoSave && _dirty && note != null) {
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
        _notesSettings = runtime.settingsService.current.notes;
        _notes = notes;
        _loading = false;
      });

      if (notes.isEmpty) {
        _selected = null;
        _linkedTasks = const [];
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
    if (_notesSettings.autoSave) {
      await _flushPendingSave();
    }

    final runtime = await WorkbenchRuntime.instance;
    final results = await Future.wait([
      runtime.noteService.readContent(note),
      runtime.noteService.linkedTasks(note),
    ]);
    if (!mounted) return;

    _replaceEditorText(results[0] as String);
    setState(() {
      _selected = note;
      _linkedTasks = results[1] as List<TaskModel>;
      _error = null;
    });
  }

  void _scheduleSave() {
    if (_selected == null) return;
    _dirty = true;
    _saveDebounce?.cancel();

    if (!_notesSettings.autoSave) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = null;
        });
      }
      return;
    }

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
      if (_notesSettings.autoSave) await _flushPendingSave();

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
    final palette = ThemeScope.of(context).palette;
    final textColor = theme.typography.body?.color;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          _flushPendingSave();
        },
      },
      child: Focus(
        autofocus: true,
        child: WorkbenchSectionPage(
          title: '笔记',
          actions: [
            FilledButton(
              onPressed: _createNote,
              child: const Text('新建笔记'),
            ),
          ],
          headerGap: 8,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 250,
                decoration: BoxDecoration(
                  color: palette.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.cardBorder),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '全部笔记',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          WorkbenchTag(label: '${_notes.length}'),
                        ],
                      ),
                    ),
                    Container(
                      height: 1,
                      color: palette.cardBorder.withValues(alpha: 0.9),
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
                              padding: const EdgeInsets.symmetric(vertical: 7),
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
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.inactiveColor.withValues(alpha: 0.14),
                    ),
                  ),
                  child: _selected == null
                      ? Center(
                          child: Button(
                            onPressed: _createNote,
                            child: const Text('新建笔记'),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selected!.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 5,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  FluentIcons.page,
                                                  size: 10,
                                                  color:
                                                      textColor?.withValues(alpha: 0.42),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  _selected!.filePath
                                                      .split('/')
                                                      .last,
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    color: textColor
                                                        ?.withValues(alpha: 0.46),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (_linkedTasks.isNotEmpty)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    FluentIcons.link,
                                                    size: 10,
                                                    color: textColor
                                                        ?.withValues(alpha: 0.42),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    _linkedTasks.map((task) => task.title).join('、'),
                                                    style: TextStyle(
                                                      fontSize: 9.5,
                                                      color: textColor
                                                          ?.withValues(alpha: 0.50),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!_notesSettings.autoSave) ...[
                                    Button(
                                      onPressed: _dirty ? _flushPendingSave : null,
                                      child: const Text('保存'),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  _SaveState(
                                    saving: _saving,
                                    dirty: _dirty,
                                    autoSave: _notesSettings.autoSave,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(child: _noteBody()),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noteBody() {
    return switch (_notesSettings.defaultView) {
      NoteDefaultView.edit => _editorPane(),
      NoteDefaultView.preview => _previewPane(),
      NoteDefaultView.split => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _editorPane()),
            const SizedBox(width: 12),
            Expanded(child: _previewPane()),
          ],
        ),
    };
  }

  Widget _editorPane() {
    return TextBox(
      controller: _editor,
      expands: true,
      minLines: null,
      maxLines: null,
      textAlignVertical: TextAlignVertical.top,
      placeholder: '输入 Markdown 内容',
    );
  }

  Widget _previewPane() {
    final palette = ThemeScope.of(context).palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.cardBorder),
      ),
      child: SingleChildScrollView(
        child: AssistantMarkdown(data: _editor.text),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
            decoration: BoxDecoration(
              color: selected ? accent.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: selected
                    ? accent.withValues(alpha: 0.18)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selected ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        note.filePath.split('/').last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: textColor?.withValues(alpha: 0.44),
                        ),
                      ),
                    ],
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
  const _SaveState({
    required this.saving,
    required this.dirty,
    required this.autoSave,
  });

  final bool saving;
  final bool dirty;
  final bool autoSave;

  @override
  Widget build(BuildContext context) {
    final textColor = FluentTheme.of(context).typography.body?.color;
    final label = saving
        ? '保存中…'
        : dirty
            ? (autoSave ? '等待保存…' : '未保存')
            : '已保存';

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
              dirty ? FluentIcons.edit : FluentIcons.check_mark,
              size: 10,
              color: textColor?.withValues(alpha: 0.46),
            ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: textColor?.withValues(alpha: 0.48),
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
