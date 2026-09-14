import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../core/models.dart';
import '../core/workbench_utils.dart';
import '../workbench_runtime.dart';

class WorkbenchWorkspaceListPage extends StatefulWidget {
  const WorkbenchWorkspaceListPage({super.key});

  @override
  State<WorkbenchWorkspaceListPage> createState() =>
      _WorkbenchWorkspaceListPageState();
}

class _WorkbenchWorkspaceListPageState
    extends State<WorkbenchWorkspaceListPage> {
  late Future<List<WorkspaceModel>> _workspaces;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _workspaces = WorkbenchRuntime.instance.then(
      (runtime) => runtime.workspaceService.listActive(),
    );
  }

  Future<void> _createWorkspace() async {
    final nameController = TextEditingController();
    final slugController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ContentDialog(
        title: const Text('New Workspace'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextBox(
                controller: nameController,
                placeholder: 'Workspace name',
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextBox(
                controller: slugController,
                placeholder: 'Folder slug (optional)',
              ),
            ],
          ),
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != true || !mounted) return;
    try {
      final runtime = await WorkbenchRuntime.instance;
      final workspace = await runtime.workspaceService.create(
        name: nameController.text,
        slug: slugController.text,
      );
      if (!mounted) return;
      context.go('/workspace/${workspace.id}/overview');
    } catch (error) {
      if (!mounted) return;
      await _showError(context, error);
    } finally {
      nameController.dispose();
      slugController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Workspace'),
        commandBar: FilledButton(
          onPressed: _createWorkspace,
          child: const Text('New Workspace'),
        ),
      ),
      content: FutureBuilder<List<WorkspaceModel>>(
        future: _workspaces,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: ProgressRing());
          }
          if (snapshot.hasError) {
            return _ErrorState(error: snapshot.error!);
          }
          final workspaces = snapshot.data ?? const <WorkspaceModel>[];
          if (workspaces.isEmpty) {
            return Center(
              child: FilledButton(
                onPressed: _createWorkspace,
                child: const Text('Create first Workspace'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
            itemCount: workspaces.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final workspace = workspaces[index];
              return _WorkbenchCard(
                onTap: () => context.go(
                  '/workspace/${workspace.id}/overview',
                ),
                child: Row(
                  children: [
                    const Icon(FluentIcons.open_folder_horizontal, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        workspace.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      workspace.slug,
                      style: TextStyle(
                        fontSize: 12,
                        color: FluentTheme.of(context)
                            .typography
                            .body
                            ?.color
                            ?.withOpacity(0.55),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(FluentIcons.chevron_right, size: 12),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class WorkbenchWorkspaceFrame extends StatelessWidget {
  const WorkbenchWorkspaceFrame({
    super.key,
    required this.workspaceId,
    required this.section,
    required this.child,
  });

  final String workspaceId;
  final String section;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: FluentTheme.of(context).inactiveColor.withOpacity(0.18),
              ),
            ),
          ),
          child: Row(
            children: [
              _WorkspaceTab(
                label: 'Overview',
                selected: section == 'overview',
                onTap: () =>
                    context.go('/workspace/$workspaceId/overview'),
              ),
              _WorkspaceTab(
                label: 'Tasks',
                selected: section == 'tasks',
                onTap: () => context.go('/workspace/$workspaceId/tasks'),
              ),
              _WorkspaceTab(
                label: 'Notes',
                selected: section == 'notes',
                onTap: () => context.go('/workspace/$workspaceId/notes'),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _WorkspaceTab extends StatelessWidget {
  const _WorkspaceTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = FluentTheme.of(context).accentColor.normal;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Button(
        onPressed: onTap,
        style: ButtonStyle(
          padding: ButtonState.all(
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          backgroundColor: ButtonState.all(
            selected ? accent.withOpacity(0.12) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? accent : null,
          ),
        ),
      ),
    );
  }
}

class WorkbenchOverviewPage extends StatelessWidget {
  const WorkbenchOverviewPage({
    super.key,
    required this.workspaceId,
  });

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: FutureBuilder<WorkspaceOverviewModel>(
        future: WorkbenchRuntime.instance.then(
          (runtime) => runtime.overviewService.loadOverview(workspaceId),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: ProgressRing());
          }
          if (snapshot.hasError) {
            return _ErrorState(error: snapshot.error!);
          }
          final overview = snapshot.data!;
          final currentTask = overview.currentTask;

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      overview.workspace.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Button(
                    onPressed: () => context.go('/workspace'),
                    child: const Text('Switch Workspace'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _WorkbenchCard(
                child: currentTask == null
                    ? Row(
                        children: [
                          const Expanded(child: Text('No current task')),
                          FilledButton(
                            onPressed: () =>
                                context.go('/workspace/$workspaceId/tasks'),
                            child: const Text('Create Task'),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Current Task',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${currentTask.progress}%',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentTask.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (currentTask.nextStep.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            const Text(
                              'Next Step',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              currentTask.nextStep,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _SectionCard(
                      title: 'Linked Notes',
                      emptyText: 'No linked notes',
                      children: overview.linkedNotes
                          .map(
                            (note) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(FluentIcons.page, size: 14),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(note.title)),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _SectionCard(
                      title: 'Recent Activity',
                      emptyText: 'No activity yet',
                      children: overview.recentActivity
                          .map(
                            (activity) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                activity.summary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class WorkbenchTasksPage extends StatefulWidget {
  const WorkbenchTasksPage({
    super.key,
    required this.workspaceId,
  });

  final String workspaceId;

  @override
  State<WorkbenchTasksPage> createState() => _WorkbenchTasksPageState();
}

class _WorkbenchTasksPageState extends State<WorkbenchTasksPage> {
  late Future<List<TaskModel>> _tasks;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _tasks = WorkbenchRuntime.instance.then(
      (runtime) => runtime.taskService.listByWorkspace(widget.workspaceId),
    );
  }

  Future<void> _createTask() async {
    final titleController = TextEditingController();
    final nextStepController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ContentDialog(
        title: const Text('New Task'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextBox(
                controller: titleController,
                placeholder: 'Task title',
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextBox(
                controller: nextStepController,
                placeholder: 'Next step',
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (result != true || !mounted) return;

    try {
      final runtime = await WorkbenchRuntime.instance;
      final task = await runtime.taskService.create(
        workspaceId: widget.workspaceId,
        title: titleController.text,
        nextStep: nextStepController.text,
      );
      if (await runtime.taskService.getCurrent(widget.workspaceId) == null) {
        await runtime.taskService.setCurrent(widget.workspaceId, task.id);
      }
      if (!mounted) return;
      setState(_reload);
    } catch (error) {
      if (!mounted) return;
      await _showError(context, error);
    } finally {
      titleController.dispose();
      nextStepController.dispose();
    }
  }

  Future<void> _setCurrent(TaskModel task) async {
    try {
      final runtime = await WorkbenchRuntime.instance;
      await runtime.taskService.setCurrent(widget.workspaceId, task.id);
      if (!mounted) return;
      setState(_reload);
    } catch (error) {
      if (!mounted) return;
      await _showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Tasks'),
        commandBar: FilledButton(
          onPressed: _createTask,
          child: const Text('New Task'),
        ),
      ),
      content: FutureBuilder<List<TaskModel>>(
        future: _tasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: ProgressRing());
          }
          if (snapshot.hasError) {
            return _ErrorState(error: snapshot.error!);
          }
          final tasks = snapshot.data ?? const <TaskModel>[];
          if (tasks.isEmpty) {
            return Center(
              child: FilledButton(
                onPressed: _createTask,
                child: const Text('Create first Task'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _WorkbenchCard(
                child: Row(
                  children: [
                    Icon(
                      task.isCurrent
                          ? FluentIcons.radio_bullet
                          : FluentIcons.circle_ring,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: task.isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          if (task.nextStep.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              task.nextStep,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!task.isCurrent)
                      Button(
                        onPressed: () => _setCurrent(task),
                        child: const Text('Set Current'),
                      )
                    else
                      const Text(
                        'Current',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class WorkbenchNotesPage extends StatefulWidget {
  const WorkbenchNotesPage({
    super.key,
    required this.workspaceId,
  });

  final String workspaceId;

  @override
  State<WorkbenchNotesPage> createState() => _WorkbenchNotesPageState();
}

class _WorkbenchNotesPageState extends State<WorkbenchNotesPage> {
  final TextEditingController _editor = TextEditingController();
  Timer? _saveDebounce;
  List<NoteModel> _notes = const [];
  NoteModel? _selected;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _editor.addListener(_scheduleSave);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _editor
      ..removeListener(_scheduleSave)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadNotes({String? selectId}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final runtime = await WorkbenchRuntime.instance;
      final notes = await runtime.noteService.listByWorkspace(widget.workspaceId);
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _loading = false;
      });
      if (notes.isNotEmpty) {
        final selected = notes.firstWhere(
          (note) => note.id == selectId,
          orElse: () => notes.first,
        );
        await _selectNote(selected);
      } else {
        _selected = null;
        _editor.text = '';
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _selectNote(NoteModel note) async {
    _saveDebounce?.cancel();
    final runtime = await WorkbenchRuntime.instance;
    final content = await runtime.noteService.readContent(note);
    if (!mounted) return;
    _editor.removeListener(_scheduleSave);
    _editor.text = content;
    _editor.addListener(_scheduleSave);
    setState(() => _selected = note);
  }

  void _scheduleSave() {
    final note = _selected;
    if (note == null) return;
    _saveDebounce?.cancel();
    setState(() => _saving = true);
    _saveDebounce = Timer(const Duration(milliseconds: 650), () async {
      try {
        final runtime = await WorkbenchRuntime.instance;
        await runtime.noteService.saveContent(note, _editor.text);
        if (!mounted) return;
        setState(() => _saving = false);
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    });
  }

  Future<void> _createNote() async {
    final titleController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ContentDialog(
        title: const Text('New Markdown Note'),
        content: SizedBox(
          width: 420,
          child: TextBox(
            controller: titleController,
            placeholder: 'Note title',
            autofocus: true,
          ),
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (result != true || !mounted) return;

    try {
      final runtime = await WorkbenchRuntime.instance;
      final title = titleController.text.trim();
      final note = await runtime.noteService.create(
        workspaceId: widget.workspaceId,
        title: title,
        initialContent: '# $title\n\n',
      );
      if (!mounted) return;
      await _loadNotes(selectId: note.id);
    } catch (error) {
      if (!mounted) return;
      await _showError(context, error);
    } finally {
      titleController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: ProgressRing());
    if (_error != null && _notes.isEmpty) {
      return _ErrorState(error: _error!);
    }

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Row(
        children: [
          SizedBox(
            width: 260,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _createNote,
                      child: const Text('New Note'),
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
                        padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
                        child: Button(
                          onPressed: () => _selectNote(note),
                          style: ButtonStyle(
                            backgroundColor: ButtonState.all(
                              selected
                                  ? FluentTheme.of(context)
                                      .accentColor
                                      .normal
                                      .withOpacity(0.12)
                                  : Colors.transparent,
                            ),
                            padding: ButtonState.all(
                              const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              note.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
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
            color: FluentTheme.of(context).inactiveColor.withOpacity(0.16),
          ),
          Expanded(
            child: _selected == null
                ? const Center(child: Text('Create a Markdown note'))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selected!.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              _saving ? 'Saving...' : 'Saved',
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
                            placeholder: 'Markdown',
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _error!,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _WorkbenchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (children.isEmpty)
            Text(emptyText, style: const TextStyle(fontSize: 12))
          else
            ...children,
        ],
      ),
    );
  }
}

class _WorkbenchCard extends StatelessWidget {
  const _WorkbenchCard({
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final container = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.inactiveColor.withOpacity(0.16)),
      ),
      child: child,
    );

    if (onTap == null) return container;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: MouseRegion(cursor: SystemMouseCursors.click, child: container),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          error.toString(),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

Future<void> _showError(BuildContext context, Object error) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => ContentDialog(
      title: const Text('Unable to complete action'),
      content: Text(error.toString()),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
