import '../core/models.dart';
import 'workbench_services.dart';
import 'workbench_settings_service.dart';

class QuickCaptureService {
  const QuickCaptureService({
    required this.workspaces,
    required this.tasks,
    required this.notes,
    required this.settings,
  });

  final WorkspaceService workspaces;
  final TaskService tasks;
  final NoteService notes;
  final WorkbenchSettingsService settings;

  Future<List<WorkspaceModel>> listTargetWorkspaces() => workspaces.listActive();

  Future<NoteModel> saveAsNote({
    required String workspaceId,
    required String text,
  }) async {
    final content = text.trim();
    if (content.isEmpty) {
      throw ArgumentError.value(text, 'text', '快速记录内容不能为空。');
    }

    final title = _titleFrom(content);
    return notes.create(
      workspaceId: workspaceId,
      title: title,
      initialContent: '# $title\n\n$content\n',
      linkToCurrentTask: settings.current.general.quickCaptureToCurrentTask,
    );
  }

  Future<TaskModel> saveAsTask({
    required String workspaceId,
    required String text,
  }) async {
    final content = text.trim();
    if (content.isEmpty) {
      throw ArgumentError.value(text, 'text', '快速记录内容不能为空。');
    }

    final task = await tasks.create(
      workspaceId: workspaceId,
      title: _titleFrom(content, maxLength: 80),
      description: content,
    );

    if (await tasks.getCurrent(workspaceId) == null) {
      await tasks.setCurrent(workspaceId, task.id);
    }
    return task;
  }

  String _titleFrom(String text, {int maxLength = 36}) {
    final firstLine = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => text.trim());
    if (firstLine.length <= maxLength) return firstLine;
    return '${firstLine.substring(0, maxLength)}…';
  }
}
