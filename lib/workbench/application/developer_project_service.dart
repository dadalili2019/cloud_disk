import '../core/developer_models.dart';
import '../core/models.dart';
import '../core/workbench_utils.dart';
import '../domain/developer_project_repository.dart';
import '../domain/repositories.dart';

class DeveloperProjectService {
  const DeveloperProjectService({required this.projects, required this.activities});

  final DeveloperProjectRepository projects;
  final ActivityRepository activities;

  Future<List<DeveloperProjectModel>> listByWorkspace(String workspaceId) =>
      projects.listByWorkspace(workspaceId);

  Future<DeveloperProjectModel?> getPrimary(String workspaceId) =>
      projects.getPrimary(workspaceId);

  Future<DeveloperProjectModel> create({
    required String workspaceId,
    required String name,
    String localPath = '',
    String repositoryUrl = '',
    String branch = '',
    String techStack = '',
    String notes = '',
    bool isPrimary = false,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Project name is required.');
    }
    final existing = await projects.listByWorkspace(workspaceId);
    final makePrimary = isPrimary || existing.isEmpty;
    if (makePrimary) {
      await _clearPrimary(workspaceId);
    }
    final now = DateTime.now().toUtc();
    final project = DeveloperProjectModel(
      id: newWorkbenchId(), workspaceId: workspaceId, name: trimmed,
      localPath: localPath.trim(), repositoryUrl: repositoryUrl.trim(),
      branch: branch.trim(), techStack: techStack.trim(), notes: notes.trim(),
      isPrimary: makePrimary, createdAt: now, updatedAt: now,
    );
    await projects.insert(project);
    await _activity(project, 'project_created', project.name, now);
    return project;
  }

  Future<DeveloperProjectModel> update({
    required DeveloperProjectModel project,
    required String name,
    required String localPath,
    required String repositoryUrl,
    required String branch,
    required String techStack,
    required String notes,
    required bool isPrimary,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name', 'Project name is required.');
    if (isPrimary && !project.isPrimary) await _clearPrimary(project.workspaceId);
    final now = DateTime.now().toUtc();
    final updated = DeveloperProjectModel(
      id: project.id, workspaceId: project.workspaceId, name: trimmed,
      localPath: localPath.trim(), repositoryUrl: repositoryUrl.trim(), branch: branch.trim(),
      techStack: techStack.trim(), notes: notes.trim(), isPrimary: isPrimary,
      createdAt: project.createdAt, updatedAt: now, archivedAt: project.archivedAt,
    );
    await projects.update(updated);
    await _activity(updated, 'project_updated', updated.name, now);
    return updated;
  }

  Future<DeveloperProjectModel> setPrimary(DeveloperProjectModel project) async {
    if (project.isPrimary) return project;
    await _clearPrimary(project.workspaceId);
    return update(
      project: project, name: project.name, localPath: project.localPath,
      repositoryUrl: project.repositoryUrl, branch: project.branch,
      techStack: project.techStack, notes: project.notes, isPrimary: true,
    );
  }

  Future<void> _clearPrimary(String workspaceId) async {
    final items = await projects.listByWorkspace(workspaceId);
    for (final item in items.where((item) => item.isPrimary)) {
      await projects.update(DeveloperProjectModel(
        id: item.id, workspaceId: item.workspaceId, name: item.name,
        localPath: item.localPath, repositoryUrl: item.repositoryUrl, branch: item.branch,
        techStack: item.techStack, notes: item.notes, isPrimary: false,
        createdAt: item.createdAt, updatedAt: DateTime.now().toUtc(), archivedAt: item.archivedAt,
      ));
    }
  }

  Future<void> _activity(DeveloperProjectModel project, String type, String summary, DateTime at) =>
      activities.insert(ActivityEventModel(
        id: newWorkbenchId(), workspaceId: project.workspaceId,
        entityType: 'project', entityId: project.id, eventType: type,
        summary: summary, createdAt: at,
      ));
}
