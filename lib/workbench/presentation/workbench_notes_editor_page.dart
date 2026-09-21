import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

import '../../theme/theme_controller.dart';
import '../application/notes_editor_save_coordinator.dart';
import '../core/models.dart';
import '../core/workbench_settings.dart';
import '../workbench_runtime.dart';
import 'assistant_markdown.dart';
import 'workbench_ui.dart';

part 'workbench_notes_editor_widgets.dart';

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
  final NotesEditorSaveCoordinator _saveCoordinator =
      NotesEditorSaveCoordinator();
  Timer? _saveDebounce;
  List<NoteModel> _notes = const [];
  List<TaskModel> _linkedTasks = const [];
  NoteModel? _selected;
  NotesSettings _notesSettings = const NotesSettings();
  bool _loading = true;
  String? _error;

  bool get _dirty => _saveCoordinator.dirty;
  bool get _saving => _saveCoordinator.saving;

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
      unawaited(_persistOnDispose(note, content));
    }
    _editor
      ..removeListener(_scheduleSave)
      ..dispose();
    super.dispose();
  }

  Future<void> _persistOnDispose(NoteModel note, String content) async {
    try {
      await _saveCoordinator.flush(
        persist: (_) async {
          final runtime = await WorkbenchRuntime.instance;
          await runtime.noteService.saveContent(note, content);
        },
        repeatWhileDirty: false,
      );
    } catch (_) {
      // Dispose 阶段已经没有可展示的 UI；正式保存错误仍由编辑态流程展示。
    }
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
    _saveCoordinator.reset();
  }

  Future<void> _selectNote(NoteModel note) async {
    if (_selected?.id == note.id) return;
    if (_saving) {
      await _flushPendingSave();
    }
    if (_dirty) {
      if (_notesSettings.autoSave) {
        await _flushPendingSave();
        if (_dirty) return;
      } else {
        final decision = await _confirmUnsavedChanges();
        if (!mounted || decision == _UnsavedChangesDecision.cancel) return;
        if (decision == _UnsavedChangesDecision.save) {
          await _flushPendingSave();
          if (_dirty) return;
        } else {
          _saveCoordinator.reset();
        }
      }
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
    _saveCoordinator.markEdited();
    _saveDebounce?.cancel();

    if (!_notesSettings.autoSave) {
      if (mounted) {
        setState(() => _error = null);
      }
      return;
    }

    if (mounted) setState(() {});
    _saveDebounce = Timer(
      const Duration(milliseconds: 650),
      _flushPendingSave,
    );
  }

  Future<void> _flushPendingSave() async {
    if (!_dirty || _selected == null) {
      if (mounted) setState(() {});
      return;
    }

    _saveDebounce?.cancel();
    final operation = _saveCoordinator.flush(
      persist: (_) async {
        final note = _selected;
        if (note == null) return;
        final markdown = _editor.text;
        final runtime = await WorkbenchRuntime.instance;
        await runtime.noteService.saveContent(note, markdown);
      },
      repeatWhileDirty: _notesSettings.autoSave,
    );

    if (mounted) setState(() {});

    try {
      await operation;
      if (!mounted) return;
      setState(() => _error = null);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<_UnsavedChangesDecision> _confirmUnsavedChanges() async {
    final result = await showDialog<_UnsavedChangesDecision>(
      context: context,
      builder: (dialogContext) => ContentDialog(
        title: const Text('当前笔记尚未保存'),
        content: const Text('切换笔记前，要保存当前修改吗？'),
        actions: [
          Button(
            onPressed: () => Navigator.pop(
              dialogContext,
              _UnsavedChangesDecision.cancel,
            ),
            child: const Text('取消'),
          ),
          Button(
            onPressed: () => Navigator.pop(
              dialogContext,
              _UnsavedChangesDecision.discard,
            ),
            child: const Text('放弃修改'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              _UnsavedChangesDecision.save,
            ),
            child: const Text('保存并切换'),
          ),
        ],
      ),
    );
    return result ?? _UnsavedChangesDecision.cancel;
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
      if (_saving) {
        await _flushPendingSave();
      }
      var discardCurrentChanges = false;
      if (_dirty) {
        if (_notesSettings.autoSave) {
          await _flushPendingSave();
          if (_dirty) return;
        } else {
          final decision = await _confirmUnsavedChanges();
          if (!mounted || decision == _UnsavedChangesDecision.cancel) return;
          if (decision == _UnsavedChangesDecision.save) {
            await _flushPendingSave();
            if (_dirty) return;
          } else {
            discardCurrentChanges = true;
          }
        }
      }

      final title = titleController.text.trim();
      final runtime = await WorkbenchRuntime.instance;
      final note = await runtime.noteService.create(
        workspaceId: widget.workspaceId,
        title: title,
        fileName: fileNameController.text.trim(),
        initialContent: '# $title\n\n',
      );
      if (!mounted) return;
      if (discardCurrentChanges) {
        _saveCoordinator.reset();
      }
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NotesListPanel(
                notes: _notes,
                selectedId: _selected?.id,
                onCreate: _createNote,
                onSelect: _selectNote,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NotesEditorPanel(
                  selected: _selected,
                  linkedTasks: _linkedTasks,
                  settings: _notesSettings,
                  controller: _editor,
                  saving: _saving,
                  dirty: _dirty,
                  error: _error,
                  onCreate: _createNote,
                  onSave: _flushPendingSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _UnsavedChangesDecision { save, discard, cancel }

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
