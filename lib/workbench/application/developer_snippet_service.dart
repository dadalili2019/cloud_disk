import '../core/developer_models.dart';
import '../core/models.dart';
import '../core/workbench_utils.dart';
import '../domain/developer_project_repository.dart';
import '../domain/developer_snippet_repository.dart';
import '../domain/repositories.dart';

class DeveloperSnippetService {
  const DeveloperSnippetService({
    required this.snippets,
    required this.projects,
    required this.activities,
  });

  final DeveloperSnippetRepository snippets;
  final DeveloperProjectRepository projects;
  final ActivityRepository activities;

  Future<List<DeveloperSnippetModel>> listByWorkspace(String workspaceId) =>
      snippets.listByWorkspace(workspaceId);

  Future<DeveloperSnippetModel> create({
    required String workspaceId,
    required String title,
    required String content,
    String? projectId,
    String language = '',
    String notes = '',
    bool isPinned = false,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Snippet title is required.');
    }
    await _validateProject(workspaceId, projectId);
    final now = DateTime.now().toUtc();
    final model = DeveloperSnippetModel(
      id: newWorkbenchId(), workspaceId: workspaceId, projectId: projectId,
      title: trimmedTitle, language: language.trim(), content: content,
      notes: notes.trim(), isPinned: isPinned, createdAt: now, updatedAt: now,
    );
    await snippets.insert(model);
    await _activity(model, 'snippet_created', model.title, now);
    return model;
  }

  Future<DeveloperSnippetModel> update({
    required DeveloperSnippetModel snippet,
    required String title,
    required String content,
    String? projectId,
    required String language,
    required String notes,
    required bool isPinned,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Snippet title is required.');
    }
    await _validateProject(snippet.workspaceId, projectId);
    final now = DateTime.now().toUtc();
    final updated = DeveloperSnippetModel(
      id: snippet.id, workspaceId: snippet.workspaceId, projectId: projectId,
      title: trimmedTitle, language: language.trim(), content: content,
      notes: notes.trim(), isPinned: isPinned, createdAt: snippet.createdAt,
      updatedAt: now, archivedAt: snippet.archivedAt,
    );
    await snippets.update(updated);
    await _activity(updated, 'snippet_updated', updated.title, now);
    return updated;
  }

  Future<void> _validateProject(String workspaceId, String? projectId) async {
    if (projectId == null) return;
    final project = await projects.getById(projectId);
    if (project == null || project.archivedAt != null || project.workspaceId != workspaceId) {
      throw StateError('Developer project is not available in this workspace.');
    }
  }

  Future<void> _activity(DeveloperSnippetModel snippet, String type, String summary, DateTime at) =>
      activities.insert(ActivityEventModel(
        id: newWorkbenchId(), workspaceId: snippet.workspaceId,
        entityType: 'snippet', entityId: snippet.id, eventType: type,
        summary: summary, createdAt: at,
      ));
}
