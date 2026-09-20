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
    final activeWorkspacesFuture = workspaces.listActive();
    final knowledgeItemsFuture = knowledge.listActive();

    final activeWorkspaces = await activeWorkspacesFuture;
    final workspaceEntryGroups = await Future.wait(
      activeWorkspaces.map(_workspaceEntries),
    );

    final entries = <SearchIndexEntry>[
      for (final group in workspaceEntryGroups) ...group,
    ];

    final knowledgeItems = await knowledgeItemsFuture;
    final knowledgeEntries = await Future.wait(
      knowledgeItems.map((item) async {
        return SearchIndexEntry(
          entityType: 'knowledge',
          entityId: item.id,
          title: item.title,
          body: [
            item.summary,
            item.useWhen,
            await markdownStore.read(item.filePath),
          ].where((value) => value.trim().isNotEmpty).join('\n\n'),
        );
      }),
    );
    entries.addAll(knowledgeEntries);

    await index.rebuild(entries);
  }

  Future<List<SearchIndexEntry>> _workspaceEntries(
    WorkspaceModel workspace,
  ) async {
    final workspaceId = workspace.id;

    final tasksFuture = tasks.listByWorkspace(workspaceId);
    final notesFuture = notes.listByWorkspace(workspaceId);
    final issuesFuture = issues.listByWorkspace(workspaceId);
    final resourcesFuture = resources.listByWorkspace(workspaceId);
    final decisionsFuture = decisions.listByWorkspace(workspaceId);
    final projectsFuture = developerProjects.listByWorkspace(workspaceId);
    final commandsFuture = developerCommands.listByWorkspace(workspaceId);
    final snippetsFuture = developerSnippets.listByWorkspace(workspaceId);

    final workspaceTasks = await tasksFuture;
    final workspaceNotes = await notesFuture;
    final workspaceIssues = await issuesFuture;
    final workspaceResources = await resourcesFuture;
    final workspaceDecisions = await decisionsFuture;
    final workspaceDeveloperProjects = await projectsFuture;
    final workspaceDeveloperCommands = await commandsFuture;
    final workspaceDeveloperSnippets = await snippetsFuture;

    final entries = <SearchIndexEntry>[
      for (final task in workspaceTasks)
        SearchIndexEntry(
          entityType: 'task',
          entityId: task.id,
          workspaceId: workspaceId,
          title: task.title,
          body: [task.description, task.nextStep, task.status]
              .where((value) => value.trim().isNotEmpty)
              .join('\n'),
        ),
      for (final issue in workspaceIssues)
        SearchIndexEntry(
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
        ),
      for (final resource in workspaceResources)
        SearchIndexEntry(
          entityType: 'resource',
          entityId: resource.id,
          workspaceId: workspaceId,
          title: resource.name,
          body: [resource.resourceType, resource.description, resource.uri]
              .where((value) => value.trim().isNotEmpty)
              .join('\n'),
        ),
      for (final decision in workspaceDecisions)
        SearchIndexEntry(
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
        ),
      for (final project in workspaceDeveloperProjects)
        SearchIndexEntry(
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
        ),
      for (final command in workspaceDeveloperCommands)
        SearchIndexEntry(
          entityType: 'developer_command',
          entityId: command.id,
          workspaceId: workspaceId,
          title: command.name,
          body: <String?>[
            command.command,
            command.workingDirectory,
            command.category,
            command.notes,
          ]
              .whereType<String>()
              .where((value) => value.trim().isNotEmpty)
              .join('\n'),
        ),
      for (final snippet in workspaceDeveloperSnippets)
        SearchIndexEntry(
          entityType: 'developer_snippet',
          entityId: snippet.id,
          workspaceId: workspaceId,
          title: snippet.title,
          body: [snippet.language, snippet.content, snippet.notes]
              .where((value) => value.trim().isNotEmpty)
              .join('\n'),
        ),
    ];

    final noteEntries = await Future.wait(
      workspaceNotes.map((note) async {
        return SearchIndexEntry(
          entityType: 'note',
          entityId: note.id,
          workspaceId: workspaceId,
          title: note.title,
          body: await markdownStore.read(note.filePath),
        );
      }),
    );
    entries.addAll(noteEntries);

    return entries;
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
