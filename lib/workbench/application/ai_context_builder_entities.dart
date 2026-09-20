part of 'ai_context_builder.dart';

extension _AIContextEntityMapper on AIContextBuilder {
  Future<AIContextItem?> _loadEntityItem(
    String entityType,
    String entityId, {
    required String reason,
  }) async {
    switch (entityType) {
      case 'task':
        final task = await tasks.getById(entityId);
        if (task == null) return null;
        return AIContextItem(
          ref: this._taskRef(task),
          priority: 2,
          reason: reason,
          content: this._taskSummary(task),
        );
      case 'note':
        final note = await notes.getById(entityId);
        if (note == null) return null;
        return AIContextItem(
          ref: AIContextRef(
            entityType: 'note',
            entityId: note.id,
            title: note.title,
            workspaceId: note.workspaceId,
          ),
          priority: 2,
          reason: reason,
          content: await markdownStore.read(note.filePath),
        );
      case 'issue':
        final issue = await issues.getById(entityId);
        if (issue == null) return null;
        return AIContextItem(
          ref: this._issueRef(issue),
          priority: 1,
          reason: reason,
          content: this._issueContent(issue),
        );
      case 'resource':
        final resource = await resources.getById(entityId);
        if (resource == null) return null;
        return AIContextItem(
          ref: this._resourceRef(resource),
          priority: 2,
          reason: reason,
          content: this._resourceContent(resource),
        );
      case 'decision':
        final decision = await decisions.getById(entityId);
        if (decision == null) return null;
        return AIContextItem(
          ref: this._decisionRef(decision),
          priority: 1,
          reason: reason,
          content: this._decisionContent(decision),
        );
      case 'knowledge':
        final item = await knowledge.getById(entityId);
        if (item == null) return null;
        return AIContextItem(
          ref: this._knowledgeRef(item),
          priority: 3,
          reason: reason,
          content: this._knowledgeContent(
            item,
            await markdownStore.read(item.filePath),
          ),
        );
      case 'developer_project':
        final project = await developerContextService.getProjectById(entityId);
        if (project == null || project.archivedAt != null) return null;
        return this._developerProjectItem(
          project,
          priority: project.isPrimary ? 1 : 2,
          reason: reason,
        );
      case 'developer_command':
        final command = await developerContextService.getCommandById(entityId);
        if (command == null || command.archivedAt != null) return null;
        return this._developerCommandItem(
          command,
          priority: 2,
          reason: reason,
        );
      case 'developer_snippet':
        final snippet = await developerContextService.getSnippetById(entityId);
        if (snippet == null || snippet.archivedAt != null) return null;
        return this._developerSnippetItem(
          snippet,
          priority: 3,
          reason: reason,
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
        ref: this._taskRef(task),
        priority: 0,
        reason: 'current_task',
        content: this._taskSummary(task),
      );

  AIContextItem _issueItem(IssueModel issue) => AIContextItem(
        ref: this._issueRef(issue),
        priority: 0,
        reason: 'active_blocker',
        content: this._issueContent(issue),
      );

  AIContextItem _resourceItem(ResourceModel resource) => AIContextItem(
        ref: this._resourceRef(resource),
        priority: 2,
        reason: 'resource',
        content: this._resourceContent(resource),
      );

  AIContextItem _decisionItem(DecisionModel decision) => AIContextItem(
        ref: this._decisionRef(decision),
        priority: 1,
        reason: 'decision',
        content: this._decisionContent(decision),
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
        content:
            '${event.eventType}\n${event.summary}\n${event.createdAt.toUtc().toIso8601String()}',
      );

  AIContextItem _developerProjectItem(
    DeveloperProjectModel project, {
    required int priority,
    required String reason,
  }) =>
      AIContextItem(
        ref: AIContextRef(
          entityType: 'developer_project',
          entityId: project.id,
          title: project.name,
          workspaceId: project.workspaceId,
        ),
        priority: priority,
        reason: reason,
        content: this._developerProjectContent(project),
      );

  AIContextItem _developerCommandItem(
    DeveloperCommandModel command, {
    required int priority,
    required String reason,
  }) =>
      AIContextItem(
        ref: AIContextRef(
          entityType: 'developer_command',
          entityId: command.id,
          title: command.name,
          workspaceId: command.workspaceId,
        ),
        priority: priority,
        reason: reason,
        content: this._developerCommandContent(command),
      );

  AIContextItem _developerSnippetItem(
    DeveloperSnippetModel snippet, {
    required int priority,
    required String reason,
  }) =>
      AIContextItem(
        ref: AIContextRef(
          entityType: 'developer_snippet',
          entityId: snippet.id,
          title: snippet.title,
          workspaceId: snippet.workspaceId,
        ),
        priority: priority,
        reason: reason,
        content: this._developerSnippetContent(snippet),
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

}
