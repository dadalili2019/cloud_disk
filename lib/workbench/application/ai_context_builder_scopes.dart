part of 'ai_context_builder.dart';

extension _AIContextScopeBuilder on AIContextBuilder {
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
      this._taskItem(task),
      ...await this._noteItems(context.notes, priority: 1, reason: 'linked_note'),
      ...context.openIssues.map(this._issueItem),
      ...context.decisions.map(this._decisionItem),
      ...context.resources.map(this._resourceItem),
      ...await this._developerItemsForWorkspace(
        task.workspaceId,
        workspaceScope: false,
      ),
      ...await this._knowledgeItems(
        context.knowledge,
        priority: 3,
        reason: 'task_knowledge',
      ),
      ...context.recentActivity.map(this._activityItem),
    ];
    return this._finalize(
      request,
      workspace: workspace,
      anchor: this._taskRef(task),
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
      items.add(this._taskItem(currentTask));
      items.addAll(
        await this._noteItems(
          context.notes.take(4),
          priority: 1,
          reason: 'current_task_note',
        ),
      );
      items.addAll(context.openIssues.take(4).map(this._issueItem));
      items.addAll(context.decisions.take(4).map(this._decisionItem));
      items.addAll(context.resources.take(4).map(this._resourceItem));
      items.addAll(
        await this._knowledgeItems(
          context.knowledge.take(4),
          priority: 3,
          reason: 'current_task_knowledge',
        ),
      );
    }

    final workspaceTasks = await tasks.listByWorkspace(workspaceId);
    for (final task
        in workspaceTasks.where((task) => task.id != currentTask?.id).take(3)) {
      items.add(
        AIContextItem(
          ref: this._taskRef(task),
          priority: 2,
          reason: 'recent_workspace_task',
          content: this._taskSummary(task),
        ),
      );
    }

    final workspaceNotes = await notes.listByWorkspace(workspaceId);
    items.addAll(
      await this._noteItems(
        workspaceNotes.take(4),
        priority: 2,
        reason: 'recent_workspace_note',
      ),
    );

    final workspaceIssues = await issues.listByWorkspace(workspaceId);
    items.addAll(
      workspaceIssues.where((issue) => issue.isOpen).take(4).map(this._issueItem),
    );

    final workspaceResources = await resources.listByWorkspace(workspaceId);
    items.addAll(workspaceResources.take(4).map(this._resourceItem));

    final workspaceDecisions = await decisions.listByWorkspace(workspaceId);
    items.addAll(workspaceDecisions.take(4).map(this._decisionItem));

    items.addAll(
      await this._developerItemsForWorkspace(
        workspaceId,
        workspaceScope: true,
      ),
    );

    if (request.query.trim().isNotEmpty) {
      final hits = await searchService.searchFresh(
        request.query.trim(),
        workspaceId: workspaceId,
        limit: 8,
      );
      items.addAll(
        await this._itemsFromSearchHits(hits, reason: 'workspace_search'),
      );
    }

    final recentActivity = await activities.listRecent(workspaceId, limit: 6);
    items.addAll(recentActivity.map(this._activityItem));

    return this._finalize(
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
        ref: this._knowledgeRef(item),
        priority: 0,
        reason: 'anchor_knowledge',
        content: this._knowledgeContent(
          item,
          await markdownStore.read(item.filePath),
        ),
      ),
    ];

    WorkspaceModel? workspace;
    for (final source in sourceRefs) {
      final loaded = await this._loadEntityItem(
        source.entityType,
        source.entityId,
        reason: 'knowledge_source',
      );
      if (loaded != null) {
        items.add(loaded);
        workspace ??= await this._workspaceForItem(loaded);
      }
    }

    if (request.query.trim().isNotEmpty) {
      final hits = await searchService.searchFresh(
        request.query.trim(),
        limit: 6,
      );
      items.addAll(
        await this._itemsFromSearchHits(
          hits,
          reason: 'knowledge_related_search',
        ),
      );
    }

    return this._finalize(
      request,
      workspace: workspace,
      anchor: this._knowledgeRef(item),
      items: items,
    );
  }

  Future<AIContextModel> _buildGlobal(AIContextRequest request) async {
    final items = <AIContextItem>[];
    if (request.query.trim().isNotEmpty) {
      final hits = await searchService.searchFresh(
        request.query.trim(),
        limit: 10,
      );
      items.addAll(
        await this._itemsFromSearchHits(hits, reason: 'global_search'),
      );
    }
    return this._finalize(request, items: items);
  }
}
