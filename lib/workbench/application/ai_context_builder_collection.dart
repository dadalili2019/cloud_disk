part of 'ai_context_builder.dart';

extension _AIContextCollectionBuilder on AIContextBuilder {
  Future<AIContextModel> _finalize(
    AIContextRequest request, {
    WorkspaceModel? workspace,
    AIContextRef? anchor,
    required List<AIContextItem> items,
  }) async {
    final excluded = {
      for (final ref in request.manuallyExcludedEntities) ref.key,
    };
    final deduped = <String, AIContextItem>{};

    for (final item in items) {
      if (excluded.contains(item.ref.key)) continue;
      deduped.putIfAbsent(item.ref.key, () => item);
    }

    for (final ref in request.manuallyIncludedEntities) {
      if (excluded.contains(ref.key) || deduped.containsKey(ref.key)) continue;
      final item = await this._loadEntityItem(
        ref.entityType,
        ref.entityId,
        reason: 'manual_include',
      );
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
      result.add(
        AIContextItem(
          ref: AIContextRef(
            entityType: 'note',
            entityId: note.id,
            title: note.title,
            workspaceId: note.workspaceId,
          ),
          priority: priority,
          reason: reason,
          content: await markdownStore.read(note.filePath),
        ),
      );
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
      result.add(
        AIContextItem(
          ref: this._knowledgeRef(item),
          priority: priority,
          reason: reason,
          content: this._knowledgeContent(
            item,
            await markdownStore.read(item.filePath),
          ),
        ),
      );
    }
    return result;
  }

  Future<List<AIContextItem>> _developerItemsForWorkspace(
    String workspaceId, {
    required bool workspaceScope,
  }) async {
    final context = await developerContextService.load(workspaceId);
    final result = <AIContextItem>[];

    final primary = context.primaryProject;
    if (primary != null) {
      result.add(
        this._developerProjectItem(
          primary,
          priority: 1,
          reason: 'primary_developer_project',
        ),
      );
    }

    if (workspaceScope) {
      for (final project
          in context.projects.where((item) => item.id != primary?.id).take(2)) {
        result.add(
          this._developerProjectItem(
            project,
            priority: 2,
            reason: 'workspace_developer_project',
          ),
        );
      }
    }

    final pinnedCommands = context.commands.where((item) => item.isPinned).toList();
    final selectedCommands = workspaceScope
        ? context.commands.take(4)
        : (pinnedCommands.isNotEmpty
            ? pinnedCommands.take(3)
            : context.commands.take(2));
    for (final command in selectedCommands) {
      result.add(
        this._developerCommandItem(
          command,
          priority: 2,
          reason: workspaceScope
              ? 'workspace_developer_command'
              : 'task_developer_command',
        ),
      );
    }

    final pinnedSnippets = context.snippets.where((item) => item.isPinned).toList();
    final selectedSnippets = workspaceScope
        ? context.snippets.take(3)
        : (pinnedSnippets.isNotEmpty
            ? pinnedSnippets.take(2)
            : context.snippets.take(1));
    for (final snippet in selectedSnippets) {
      result.add(
        this._developerSnippetItem(
          snippet,
          priority: 3,
          reason: workspaceScope
              ? 'workspace_developer_snippet'
              : 'task_developer_snippet',
        ),
      );
    }

    final resourceLimit = workspaceScope ? 4 : 3;
    for (final resource in context.devResources.take(resourceLimit)) {
      result.add(
        AIContextItem(
          ref: this._resourceRef(resource),
          priority: 2,
          reason: 'developer_resource',
          content: this._resourceContent(resource),
        ),
      );
    }

    return result;
  }

  Future<List<AIContextItem>> _itemsFromSearchHits(
    List<SearchResultModel> hits, {
    required String reason,
  }) async {
    final result = <AIContextItem>[];
    for (final hit in hits) {
      final item = await this._loadEntityItem(
        hit.entityType,
        hit.entityId,
        reason: reason,
      );
      if (item != null) result.add(item);
    }
    return result;
  }

}
