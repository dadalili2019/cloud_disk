import '../core/ai_context_models.dart';
import '../core/models.dart';
import '../data/markdown_store.dart';
import '../domain/decision_repository.dart';
import '../domain/issue_repository.dart';
import '../domain/knowledge_repository.dart';
import '../domain/repositories.dart';
import '../domain/resource_repository.dart';
import 'knowledge_service.dart';
import 'search_service.dart';
import 'task_context_service.dart';

class AIContextBuilder {
  const AIContextBuilder({
    required this.workspaces,
    required this.tasks,
    required this.notes,
    required this.issues,
    required this.resources,
    required this.decisions,
    required this.knowledge,
    required this.activities,
    required this.markdownStore,
    required this.taskContextService,
    required this.knowledgeService,
    required this.searchService,
  });

  final WorkspaceRepository workspaces;
  final TaskRepository tasks;
  final NoteRepository notes;
  final IssueRepository issues;
  final ResourceRepository resources;
  final DecisionRepository decisions;
  final KnowledgeRepository knowledge;
  final ActivityRepository activities;
  final MarkdownStore markdownStore;
  final TaskContextService taskContextService;
  final KnowledgeService knowledgeService;
  final SearchService searchService;

  Future<AIContextModel> build(AIContextRequest request) async {
    return switch (request.scope) {
      AIContextScope.task => _buildTask(request),
      AIContextScope.workspace => _buildWorkspace(request),
      AIContextScope.knowledge => _buildKnowledge(request),
      AIContextScope.global => _buildGlobal(request),
    };
  }

  Future<AIContextModel> _buildTask(AIContextRequest request) async {
    final taskId = request.taskId?.trim();
    if (taskId == null || taskId.isEmpty) {
      throw ArgumentError('task scope requires taskId.');
    }
    final task = await tasks.getById(taskId);
    if (task == null) throw StateError('Task not found: $taskId');
    final workspace = await workspaces.getById(task.workspaceId);
    final context = await taskContextService.load(task);
    final items = <AIContextItem>[
      _taskItem(task),
      ...await _noteItems(context.notes, priority: 1, reason: 'linked_note'),
      ...context.openIssues.map(_issueItem),
      ...context.decisions.map(_decisionItem),
      ...context.resources.map(_resourceItem),
      ...await _knowledgeItems(context.knowledge, priority: 3, reason: 'task_knowledge'),
      ...context.recentActivity.map(_activityItem),
    ];
    return _finalize(
      request,
      workspace: workspace,
      anchor: _taskRef(task),
      items: items,
    );
  }

  Future<AIContextModel> _buildWorkspace(AIContextRequest request) async {
    final workspaceId = request.workspaceId?.trim();
    if (workspaceId == null || workspaceId.isEmpty) {
      throw ArgumentError('workspace scope requires workspaceId.');
    }
    final workspace = await workspaces.getById(workspaceId);
    if (workspace == null) throw StateError('Workspace not found: $workspaceId');

    final items = <AIContextItem>[];
    final currentTask = await tasks.getCurrent(workspaceId);
    if (currentTask != null) {
      final context = await taskContextService.load(currentTask);
      items.add(_taskItem(currentTask));
      items.addAll(await _noteItems(context.notes.take(4), priority: 1, reason: 'current_task_note'));
      items.addAll(context.openIssues.take(4).map(_issueItem));
      items.addAll(context.decisions.take(4).map(_decisionItem));
      items.addAll(context.resources.take(4).map(_resourceItem));
      items.addAll(await _knowledgeItems(context.knowledge.take(4), priority: 3, reason: 'current_task_knowledge'));
    }

    final workspaceTasks = await tasks.listByWorkspace(workspaceId);
    for (final task in workspaceTasks.where((task) => task.id != currentTask?.id).take(3)) {
      items.add(AIContextItem(
        ref: _taskRef(task),
        priority: 2,
        reason: 'recent_workspace_task',
        content: _taskSummary(task),
      ));
    }

    final workspaceNotes = await notes.listByWorkspace(workspaceId);
    items.addAll(await _noteItems(workspaceNotes.take(4), priority: 2, reason: 'recent_workspace_note'));

    final workspaceIssues = await issues.listByWorkspace(workspaceId);
    items.addAll(workspaceIssues.where((issue) => issue.isOpen).take(4).map(_issueItem));

    final workspaceResources = await resources.listByWorkspace(workspaceId);
    items.addAll(workspaceResources.take(4).map(_resourceItem));

    final workspaceDecisions = await decisions.listByWorkspace(workspaceId);
    items.addAll(workspaceDecisions.take(4).map(_decisionItem));

    if (request.query.trim().isNotEmpty) {
      final hits = await searchService.search(
        request.query.trim(),
        workspaceId: workspaceId,
        limit: 8,
      );
      items.addAll(await _itemsFromSearchHits(hits, reason: 'workspace_search'));
    }

    final recentActivity = await activities.listRecent(workspaceId, limit: 6);
    items.addAll(recentActivity.map(_activityItem));

    return _finalize(
      request,
      workspace: workspace,
      anchor: AIContextRef(
        entityType: 'workspace',
        entityId: workspace.id,
        title: workspace.name,
        workspaceId: workspace.id,
      ),
      items: items,
    );
  }

  Future<AIContextModel> _buildKnowledge(AIContextRequest request) async {
    final knowledgeId = request.knowledgeId?.trim();
    if (knowledgeId == null || knowledgeId.isEmpty) {
      throw ArgumentError('knowledge scope requires knowledgeId.');
    }
    final item = await knowledge.getById(knowledgeId);
    if (item == null) throw StateError('Knowledge not found: $knowledgeId');

    final sourceRefs = await knowledgeService.sources(item);
    final items = <AIContextItem>[
      AIContextItem(
        ref: _knowledgeRef(item),
        priority: 0,
        reason: 'anchor_knowledge',
        content: _knowledgeContent(item, await markdownStore.read(item.filePath)),
      ),
    ];

    WorkspaceModel? workspace;
    for (final source in sourceRefs) {
      final loaded = await _loadEntityItem(source.entityType, source.entityId, reason: 'knowledge_source');
      if (loaded != null) {
        items.add(loaded);
        workspace ??= await _workspaceForItem(loaded);
      }
    }

    if (request.query.trim().isNotEmpty) {
      final hits = await searchService.search(request.query.trim(), limit: 6);
      items.addAll(await _itemsFromSearchHits(hits, reason: 'knowledge_related_search'));
    }

    return _finalize(
      request,
      workspace: workspace,
      anchor: _knowledgeRef(item),
      items: items,
    );
  }

  Future<AIContextModel> _buildGlobal(AIContextRequest request) async {
    final items = <AIContextItem>[];
    if (request.query.trim().isNotEmpty) {
      final hits = await searchService.search(request.query.trim(), limit: 10);
      items.addAll(await _itemsFromSearchHits(hits, reason: 'global_search'));
    }
    return _finalize(request, items: items);
  }

  Future<AIContextModel> _finalize(
    AIContextRequest request, {
    WorkspaceModel? workspace,
    AIContextRef? anchor,
    required List<AIContextItem> items,
  }) async {
    final excluded = {for (final ref in request.manuallyExcludedEntities) ref.key};
    final deduped = <String, AIContextItem>{};

    for (final item in items) {
      if (excluded.contains(item.ref.key)) continue;
      deduped.putIfAbsent(item.ref.key, () => item);
    }

    for (final ref in request.manuallyIncludedEntities) {
      if (excluded.contains(ref.key) || deduped.containsKey(ref.key)) continue;
      final item = await _loadEntityItem(ref.entityType, ref.entityId, reason: 'manual_include');
      if (item != null) deduped[item.ref.key] = item;
    }

    final ordered = deduped.values.toList()
      ..sort((a, b) {
        final priority = a.priority.compareTo(b.priority);
        if (priority != 0) return priority;
        return a.ref.title.compareTo(b.ref.title);
      });

    return AIContextModel(
      scope: request.scope,
      generatedAt: DateTime.now().toUtc(),
      anchor: anchor,
      workspace: workspace,
      items: ordered,
      excludedRefs: request.manuallyExcludedEntities,
    );
  }

  Future<List<AIContextItem>> _noteItems(
    Iterable<NoteModel> values, {
    required int priority,
    required String reason,
  }) async {
    final result = <AIContextItem>[];
    for (final note in values) {
      result.add(AIContextItem(
        ref: AIContextRef(
          entityType: 'note',
          entityId: note.id,
          title: note.title,
          workspaceId: note.workspaceId,
        ),
        priority: priority,
        reason: reason,
        content: await markdownStore.read(note.filePath),
      ));
    }
    return result;
  }

  Future<List<AIContextItem>> _knowledgeItems(
    Iterable<KnowledgeModel> values, {
    required int priority,
    required String reason,
  }) async {
    final result = <AIContextItem>[];
    for (final item in values) {
      result.add(AIContextItem(
        ref: _knowledgeRef(item),
        priority: priority,
        reason: reason,
        content: _knowledgeContent(item, await markdownStore.read(item.filePath)),
      ));
    }
    return result;
  }

  Future<List<AIContextItem>> _itemsFromSearchHits(
    List<SearchResultModel> hits, {
    required String reason,
  }) async {
    final result = <AIContextItem>[];
    for (final hit in hits) {
      final item = await _loadEntityItem(hit.entityType, hit.entityId, reason: reason);
      if (item != null) result.add(item);
    }
    return result;
  }

  Future<AIContextItem?> _loadEntityItem(
    String entityType,
    String entityId, {
    required String reason,
  }) async {
    switch (entityType) {
      case 'task':
        final task = await tasks.getById(entityId);
        if (task == null) return null;
        return AIContextItem(ref: _taskRef(task), priority: 2, reason: reason, content: _taskSummary(task));
      case 'note':
        final note = await notes.getById(entityId);
        if (note == null) return null;
        return AIContextItem(
          ref: AIContextRef(entityType: 'note', entityId: note.id, title: note.title, workspaceId: note.workspaceId),
          priority: 2,
          reason: reason,
          content: await markdownStore.read(note.filePath),
        );
      case 'issue':
        final issue = await issues.getById(entityId);
        if (issue == null) return null;
        return AIContextItem(ref: _issueRef(issue), priority: 1, reason: reason, content: _issueContent(issue));
      case 'resource':
        final resource = await resources.getById(entityId);
        if (resource == null) return null;
        return AIContextItem(ref: _resourceRef(resource), priority: 2, reason: reason, content: _resourceContent(resource));
      case 'decision':
        final decision = await decisions.getById(entityId);
        if (decision == null) return null;
        return AIContextItem(ref: _decisionRef(decision), priority: 1, reason: reason, content: _decisionContent(decision));
      case 'knowledge':
        final item = await knowledge.getById(entityId);
        if (item == null) return null;
        return AIContextItem(
          ref: _knowledgeRef(item),
          priority: 3,
          reason: reason,
          content: _knowledgeContent(item, await markdownStore.read(item.filePath)),
        );
      default:
        return null;
    }
  }

  Future<WorkspaceModel?> _workspaceForItem(AIContextItem item) async {
    final id = item.ref.workspaceId;
    return id == null ? null : workspaces.getById(id);
  }

  AIContextItem _taskItem(TaskModel task) => AIContextItem(
        ref: _taskRef(task),
        priority: 0,
        reason: 'current_task',
        content: _taskSummary(task),
      );

  AIContextItem _issueItem(IssueModel issue) => AIContextItem(
        ref: _issueRef(issue),
        priority: 0,
        reason: 'active_blocker',
        content: _issueContent(issue),
      );

  AIContextItem _resourceItem(ResourceModel resource) => AIContextItem(
        ref: _resourceRef(resource),
        priority: 2,
        reason: 'resource',
        content: _resourceContent(resource),
      );

  AIContextItem _decisionItem(DecisionModel decision) => AIContextItem(
        ref: _decisionRef(decision),
        priority: 1,
        reason: 'decision',
        content: _decisionContent(decision),
      );

  AIContextItem _activityItem(ActivityEventModel event) => AIContextItem(
        ref: AIContextRef(
          entityType: 'activity',
          entityId: event.id,
          title: event.summary.isEmpty ? event.eventType : event.summary,
          workspaceId: event.workspaceId,
        ),
        priority: 4,
        reason: 'recent_activity',
        content: '${event.eventType}\n${event.summary}\n${event.createdAt.toUtc().toIso8601String()}',
      );

  AIContextRef _taskRef(TaskModel task) => AIContextRef(
        entityType: 'task',
        entityId: task.id,
        title: task.title,
        workspaceId: task.workspaceId,
      );

  AIContextRef _issueRef(IssueModel issue) => AIContextRef(
        entityType: 'issue',
        entityId: issue.id,
        title: issue.title,
        workspaceId: issue.workspaceId,
      );

  AIContextRef _resourceRef(ResourceModel resource) => AIContextRef(
        entityType: 'resource',
        entityId: resource.id,
        title: resource.name,
        workspaceId: resource.workspaceId,
      );

  AIContextRef _decisionRef(DecisionModel decision) => AIContextRef(
        entityType: 'decision',
        entityId: decision.id,
        title: decision.title,
        workspaceId: decision.workspaceId,
      );

  AIContextRef _knowledgeRef(KnowledgeModel item) => AIContextRef(
        entityType: 'knowledge',
        entityId: item.id,
        title: item.title,
      );

  String _taskSummary(TaskModel task) => [
        'Title: ${task.title}',
        if (task.description.trim().isNotEmpty) 'Description: ${task.description}',
        'Status: ${task.status}',
        'Progress: ${task.progress}%',
        if (task.nextStep.trim().isNotEmpty) 'Next Step: ${task.nextStep}',
      ].join('\n');

  String _issueContent(IssueModel issue) => [
        'Status: ${issue.status}',
        'Severity: ${issue.severity}',
        if (issue.impact.trim().isNotEmpty) 'Impact: ${issue.impact}',
        if (issue.hypothesis.trim().isNotEmpty) 'Hypothesis: ${issue.hypothesis}',
        if (issue.nextInvestigationStep.trim().isNotEmpty)
          'Next Investigation Step: ${issue.nextInvestigationStep}',
        if (issue.resolution.trim().isNotEmpty) 'Resolution: ${issue.resolution}',
      ].join('\n');

  String _resourceContent(ResourceModel resource) => [
        'Type: ${resource.resourceType}',
        if (resource.description.trim().isNotEmpty) resource.description,
        if (resource.uri.trim().isNotEmpty) resource.uri,
      ].join('\n');

  String _decisionContent(DecisionModel decision) => [
        if (decision.decisionText.trim().isNotEmpty) 'Decision: ${decision.decisionText}',
        if (decision.rationale.trim().isNotEmpty) 'Why: ${decision.rationale}',
        if (decision.revisitCondition.trim().isNotEmpty)
          'Revisit When: ${decision.revisitCondition}',
        'Status: ${decision.status}',
      ].join('\n');

  String _knowledgeContent(KnowledgeModel item, String markdown) => [
        if (item.category.trim().isNotEmpty) 'Category: ${item.category}',
        if (item.summary.trim().isNotEmpty) 'Summary: ${item.summary}',
        if (item.useWhen.trim().isNotEmpty) 'Use When: ${item.useWhen}',
        if (markdown.trim().isNotEmpty) markdown,
      ].join('\n\n');
}
