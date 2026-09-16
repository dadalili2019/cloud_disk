import '../core/models.dart';
import '../data/markdown_store.dart';
import '../domain/decision_repository.dart';
import '../domain/developer_command_repository.dart';
import '../domain/developer_project_repository.dart';
import '../domain/developer_snippet_repository.dart';
import '../domain/issue_repository.dart';
import '../domain/knowledge_repository.dart';
import '../domain/repositories.dart';
import '../domain/resource_repository.dart';
import '../domain/search_repository.dart';

class SearchService {
  SearchService({
    required this.workspaces,
    required this.tasks,
    required this.notes,
    required this.issues,
    required this.resources,
    required this.decisions,
    required this.knowledge,
    required this.developerProjects,
    required this.developerCommands,
    required this.developerSnippets,
    required this.markdownStore,
    required this.index,
    this.freshnessWindow = const Duration(minutes: 2),
  });

  final WorkspaceRepository workspaces;
  final TaskRepository tasks;
  final NoteRepository notes;
  final IssueRepository issues;
  final ResourceRepository resources;
  final DecisionRepository decisions;
  final KnowledgeRepository knowledge;
  final DeveloperProjectRepository developerProjects;
  final DeveloperCommandRepository developerCommands;
  final DeveloperSnippetRepository developerSnippets;
  final MarkdownStore markdownStore;
  final SearchIndexRepository index;
  final Duration freshnessWindow;

  DateTime? _lastRebuildAt;
  Future<void>? _rebuildInFlight;

  Future<void> rebuildIndex() async {
    final existing = _rebuildInFlight;
    if (existing != null) return existing;

    final future = _rebuildIndexInternal();
    _rebuildInFlight = future;
    try {
      await future;
      _lastRebuildAt = DateTime.now().toUtc();
    } finally {
      _rebuildInFlight = null;
    }
  }

  Future<void> ensureFreshIndex() async {
    final last = _lastRebuildAt;
    if (last != null &&
        DateTime.now().toUtc().difference(last) < freshnessWindow) {
      return;
    }
    await rebuildIndex();
  }

  Future<void> _rebuildIndexInternal() async {
    await index.clear();

    final activeWorkspaces = await workspaces.listActive();
    for (final workspace in activeWorkspaces) {
      final workspaceId = workspace.id;
      final workspaceTasks = await tasks.listByWorkspace(workspaceId);
      final workspaceNotes = await notes.listByWorkspace(workspaceId);
      final workspaceIssues = await issues.listByWorkspace(workspaceId);
      final workspaceResources = await resources.listByWorkspace(workspaceId);
      final workspaceDecisions = await decisions.listByWorkspace(workspaceId);
      final workspaceDeveloperProjects =
          await developerProjects.listByWorkspace(workspaceId);
      final workspaceDeveloperCommands =
          await developerCommands.listByWorkspace(workspaceId);
      final workspaceDeveloperSnippets =
          await developerSnippets.listByWorkspace(workspaceId);

      for (final task in workspaceTasks) {
        await index.replace(
          entityType: 'task',
          entityId: task.id,
          workspaceId: workspaceId,
          title: task.title,
          body: [task.description, task.nextStep, task.status]
              .where((value) => value.trim().isNotEmpty)
              .join('\n'),
        );
      }

      for (final note in workspaceNotes) {
        await index.replace(
          entityType: 'note',
          entityId: note.id,
          workspaceId: workspaceId,
          title: note.title,
          body: await markdownStore.read(note.filePath),
        );
      }

      for (final issue in workspaceIssues) {
        await index.replace(
          entityType: 'issue',
          entityId: issue.id,
          workspaceId: workspaceId,
          title: issue.title,
          body: [
            issue.status,
            issue.severity,
            issue.impact,
            issue.hypothesis,
            issue.nextInvestigationStep,
            issue.resolution,
          ].where((value) => value.trim().isNotEmpty).join('\n'),
        );
      }

      for (final resource in workspaceResources) {
        await index.replace(
          entityType: 'resource',
          entityId: resource.id,
          workspaceId: workspaceId,
          title: resource.name,
          body: [resource.resourceType, resource.description, resource.uri]
              .where((value) => value.trim().isNotEmpty)
              .join('\n'),
        );
      }

      for (final decision in workspaceDecisions) {
        await index.replace(
          entityType: 'decision',
          entityId: decision.id,
          workspaceId: workspaceId,
          title: decision.title,
          body: [
            decision.decisionText,
            decision.rationale,
            decision.revisitCondition,
            decision.status,
          ].where((value) => value.trim().isNotEmpty).join('\n'),
        );
      }

      for (final project in workspaceDeveloperProjects) {
        await index.replace(
          entityType: 'developer_project',
          entityId: project.id,
          workspaceId: workspaceId,
          title: project.name,
          body: [
            project.localPath,
            project.repositoryUrl,
            project.branch,
            project.techStack,
            project.notes,
            if (project.isPrimary) 'primary project 主项目',
          ].where((value) => value.trim().isNotEmpty).join('\n'),
        );
      }

      for (final command in workspaceDeveloperCommands) {
        await index.replace(
          entityType: 'developer_command',
          entityId: command.id,
          workspaceId: workspaceId,
          title: command.name,
          body: <String?>[
            command.command,
            command.workingDirectory,
            command.category,
            command.notes,
          ].whereType<String>().where((value) => value.trim().isNotEmpty).join('\n'),
        );
      }

      for (final snippet in workspaceDeveloperSnippets) {
        await index.replace(
          entityType: 'developer_snippet',
          entityId: snippet.id,
          workspaceId: workspaceId,
          title: snippet.title,
          body: [snippet.language, snippet.content, snippet.notes]
              .where((value) => value.trim().isNotEmpty)
              .join('\n'),
        );
      }
    }

    final knowledgeItems = await knowledge.listActive();
    for (final item in knowledgeItems) {
      await index.replace(
        entityType: 'knowledge',
        entityId: item.id,
        title: item.title,
        body: [item.summary, item.useWhen, await markdownStore.read(item.filePath)]
            .where((value) => value.trim().isNotEmpty)
            .join('\n\n'),
      );
    }
  }

  Future<List<SearchResultModel>> search(
    String query, {
    Set<String>? entityTypes,
    String? workspaceId,
    int limit = 50,
  }) {
    return index.search(
      query,
      entityTypes: entityTypes,
      workspaceId: workspaceId,
      limit: limit,
    );
  }

  Future<List<SearchResultModel>> searchFresh(
    String query, {
    Set<String>? entityTypes,
    String? workspaceId,
    int limit = 50,
  }) async {
    await ensureFreshIndex();
    return search(
      query,
      entityTypes: entityTypes,
      workspaceId: workspaceId,
      limit: limit,
    );
  }
}
