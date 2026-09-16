import '../core/developer_models.dart';
import '../core/models.dart';
import '../core/workbench_utils.dart';
import '../domain/developer_command_repository.dart';
import '../domain/developer_project_repository.dart';
import '../domain/repositories.dart';

class DeveloperCommandService {
  const DeveloperCommandService({
    required this.commands,
    required this.projects,
    required this.activities,
  });

  final DeveloperCommandRepository commands;
  final DeveloperProjectRepository projects;
  final ActivityRepository activities;

  static const allowedCategories = {
    'run', 'build', 'test', 'database', 'docker', 'git', 'other',
  };

  Future<List<DeveloperCommandModel>> listByWorkspace(String workspaceId) =>
      commands.listByWorkspace(workspaceId);

  Future<DeveloperCommandModel> create({
    required String workspaceId,
    required String name,
    required String command,
    String? projectId,
    String? workingDirectory,
    String category = 'other',
    String notes = '',
    bool isPinned = false,
  }) async {
    final title = name.trim();
    final value = command.trim();
    if (title.isEmpty) throw ArgumentError.value(name, 'name', 'Command name is required.');
    if (value.isEmpty) throw ArgumentError.value(command, 'command', 'Command is required.');
    if (!allowedCategories.contains(category)) {
      throw ArgumentError.value(category, 'category', 'Unsupported command category.');
    }
    await _validateProject(workspaceId, projectId);
    final now = DateTime.now().toUtc();
    final model = DeveloperCommandModel(
      id: newWorkbenchId(), workspaceId: workspaceId, projectId: projectId,
      name: title, command: value, workingDirectory: _nullable(workingDirectory),
      category: category, notes: notes.trim(), isPinned: isPinned,
      createdAt: now, updatedAt: now,
    );
    await commands.insert(model);
    await _activity(model, 'command_created', model.name, now);
    return model;
  }

  Future<DeveloperCommandModel> update({
    required DeveloperCommandModel commandModel,
    required String name,
    required String command,
    String? projectId,
    String? workingDirectory,
    required String category,
    required String notes,
    required bool isPinned,
  }) async {
    final title = name.trim();
    final value = command.trim();
    if (title.isEmpty) throw ArgumentError.value(name, 'name', 'Command name is required.');
    if (value.isEmpty) throw ArgumentError.value(command, 'command', 'Command is required.');
    if (!allowedCategories.contains(category)) {
      throw ArgumentError.value(category, 'category', 'Unsupported command category.');
    }
    await _validateProject(commandModel.workspaceId, projectId);
    final now = DateTime.now().toUtc();
    final updated = DeveloperCommandModel(
      id: commandModel.id, workspaceId: commandModel.workspaceId, projectId: projectId,
      name: title, command: value, workingDirectory: _nullable(workingDirectory),
      category: category, notes: notes.trim(), isPinned: isPinned,
      createdAt: commandModel.createdAt, updatedAt: now, archivedAt: commandModel.archivedAt,
    );
    await commands.update(updated);
    await _activity(updated, 'command_updated', updated.name, now);
    return updated;
  }

  Future<void> _validateProject(String workspaceId, String? projectId) async {
    if (projectId == null) return;
    final project = await projects.getById(projectId);
    if (project == null || project.archivedAt != null || project.workspaceId != workspaceId) {
      throw StateError('Developer project is not available in this workspace.');
    }
  }

  String? _nullable(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _activity(DeveloperCommandModel command, String type, String summary, DateTime at) =>
      activities.insert(ActivityEventModel(
        id: newWorkbenchId(), workspaceId: command.workspaceId,
        entityType: 'command', entityId: command.id, eventType: type,
        summary: summary, createdAt: at,
      ));
}
