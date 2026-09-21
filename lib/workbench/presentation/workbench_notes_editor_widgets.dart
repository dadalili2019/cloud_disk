part of 'workbench_notes_editor_page.dart';

class _NotesListPanel extends StatelessWidget {
  const _NotesListPanel({
    required this.notes,
    required this.selectedId,
    required this.onCreate,
    required this.onSelect,
  });

  final List<NoteModel> notes;
  final String? selectedId;
  final VoidCallback onCreate;
  final ValueChanged<NoteModel> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
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
                WorkbenchTag(label: '${notes.length}'),
              ],
            ),
          ),
          Container(
            height: 1,
            color: palette.cardBorder.withValues(alpha: 0.9),
          ),
          Expanded(
            child: notes.isEmpty
                ? Center(
                    child: Button(
                      onPressed: onCreate,
                      child: const Text('新建第一条笔记'),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return _NoteListItem(
                        note: note,
                        selected: note.id == selectedId,
                        onPressed: () => onSelect(note),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotesEditorPanel extends StatelessWidget {
  const _NotesEditorPanel({
    required this.selected,
    required this.linkedTasks,
    required this.settings,
    required this.controller,
    required this.saving,
    required this.dirty,
    required this.error,
    required this.onCreate,
    required this.onSave,
  });

  final NoteModel? selected;
  final List<TaskModel> linkedTasks;
  final NotesSettings settings;
  final TextEditingController controller;
  final bool saving;
  final bool dirty;
  final String? error;
  final VoidCallback onCreate;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final note = selected;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.inactiveColor.withValues(alpha: 0.14),
        ),
      ),
      child: note == null
          ? Center(
              child: Button(
                onPressed: onCreate,
                child: const Text('新建笔记'),
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NotesEditorHeader(
                    note: note,
                    linkedTasks: linkedTasks,
                    settings: settings,
                    saving: saving,
                    dirty: dirty,
                    onSave: onSave,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _NotesBody(
                      defaultView: settings.defaultView,
                      controller: controller,
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '保存失败：$error',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _NotesEditorHeader extends StatelessWidget {
  const _NotesEditorHeader({
    required this.note,
    required this.linkedTasks,
    required this.settings,
    required this.saving,
    required this.dirty,
    required this.onSave,
  });

  final NoteModel note;
  final List<TaskModel> linkedTasks;
  final NotesSettings settings;
  final bool saving;
  final bool dirty;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final textColor = FluentTheme.of(context).typography.body?.color;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
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
                        color: textColor?.withValues(alpha: 0.42),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        note.filePath.split('/').last,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: textColor?.withValues(alpha: 0.46),
                        ),
                      ),
                    ],
                  ),
                  if (linkedTasks.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          FluentIcons.link,
                          size: 10,
                          color: textColor?.withValues(alpha: 0.42),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          linkedTasks.map((task) => task.title).join('、'),
                          style: TextStyle(
                            fontSize: 9.5,
                            color: textColor?.withValues(alpha: 0.50),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        if (!settings.autoSave) ...[
          Button(
            onPressed: dirty ? onSave : null,
            child: const Text('保存'),
          ),
          const SizedBox(width: 8),
        ],
        _SaveState(
          saving: saving,
          dirty: dirty,
          autoSave: settings.autoSave,
        ),
      ],
    );
  }
}

class _NotesBody extends StatelessWidget {
  const _NotesBody({
    required this.defaultView,
    required this.controller,
  });

  final NoteDefaultView defaultView;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return switch (defaultView) {
      NoteDefaultView.edit => _EditorPane(controller: controller),
      NoteDefaultView.preview => _PreviewPane(controller: controller),
      NoteDefaultView.split => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _EditorPane(controller: controller)),
            const SizedBox(width: 12),
            Expanded(child: _PreviewPane(controller: controller)),
          ],
        ),
    };
  }
}

class _EditorPane extends StatelessWidget {
  const _EditorPane({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextBox(
      controller: controller,
      expands: true,
      minLines: null,
      maxLines: null,
      textAlignVertical: TextAlignVertical.top,
      placeholder: '输入 Markdown 内容',
    );
  }
}

class _PreviewPane extends StatelessWidget {
  const _PreviewPane({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
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
        child: AssistantMarkdown(data: controller.text),
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
              color: selected
                  ? accent.withValues(alpha: 0.08)
                  : Colors.transparent,
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
