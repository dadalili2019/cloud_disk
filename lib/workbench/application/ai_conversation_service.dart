import 'dart:convert';

import '../core/ai_context_models.dart';
import '../core/ai_conversation_models.dart';
import '../core/workbench_utils.dart';
import '../domain/ai_conversation_repository.dart';
import '../domain/knowledge_repository.dart';
import '../domain/repositories.dart';

class AIConversationService {
  const AIConversationService({
    required this.threads,
    required this.messages,
    required this.workspaces,
    required this.tasks,
    required this.knowledge,
  });

  final AIThreadRepository threads;
  final AIMessageRepository messages;
  final WorkspaceRepository workspaces;
  final TaskRepository tasks;
  final KnowledgeRepository knowledge;

  Future<List<AIThreadModel>> listThreads({int limit = 50}) {
    return threads.listActive(limit: limit);
  }

  Future<List<AIThreadModel>> listThreadsForAnchor({
    String? workspaceId,
    String? taskId,
    String? knowledgeId,
    int limit = 50,
  }) {
    return threads.listByAnchor(
      workspaceId: workspaceId,
      taskId: taskId,
      knowledgeId: knowledgeId,
      limit: limit,
    );
  }

  Future<AIThreadModel?> getThread(String threadId) => threads.getById(threadId);

  Future<List<AIMessageModel>> listMessages(String threadId) {
    return messages.listByThread(threadId);
  }

  Future<AIThreadModel> createThread({
    required AIContextScope scope,
    String title = '',
    String? workspaceId,
    String? taskId,
    String? knowledgeId,
  }) async {
    await _validateAnchor(
      scope: scope,
      workspaceId: workspaceId,
      taskId: taskId,
      knowledgeId: knowledgeId,
    );

    String? resolvedWorkspaceId = workspaceId;
    if (scope == AIContextScope.task && taskId != null) {
      final task = await tasks.getById(taskId);
      resolvedWorkspaceId = task?.workspaceId;
    }

    final now = DateTime.now().toUtc();
    final thread = AIThreadModel(
      id: newWorkbenchId(),
      scope: scope,
      title: title.trim(),
      workspaceId: resolvedWorkspaceId,
      taskId: taskId,
      knowledgeId: knowledgeId,
      createdAt: now,
      updatedAt: now,
    );
    await threads.insert(thread);
    return thread;
  }

  Future<AIMessageModel> addUserMessage({
    required AIThreadModel thread,
    required String content,
  }) async {
    return _addMessage(
      thread: thread,
      role: 'user',
      content: content,
      contextSnapshotJson: '',
    );
  }

  Future<AIMessageModel> addAssistantMessage({
    required AIThreadModel thread,
    required String content,
    required AIContextModel context,
  }) async {
    final snapshot = jsonEncode(context.referenceSnapshot());
    return _addMessage(
      thread: thread,
      role: 'assistant',
      content: content,
      contextSnapshotJson: snapshot,
    );
  }

  Future<AIMessageModel> addSystemMessage({
    required AIThreadModel thread,
    required String content,
  }) async {
    return _addMessage(
      thread: thread,
      role: 'system',
      content: content,
      contextSnapshotJson: '',
    );
  }

  Future<AIThreadModel> renameThread(AIThreadModel thread, String title) async {
    final updated = AIThreadModel(
      id: thread.id,
      scope: thread.scope,
      title: title.trim(),
      workspaceId: thread.workspaceId,
      taskId: thread.taskId,
      knowledgeId: thread.knowledgeId,
      createdAt: thread.createdAt,
      updatedAt: DateTime.now().toUtc(),
      archivedAt: thread.archivedAt,
    );
    await threads.update(updated);
    return updated;
  }

  Future<AIThreadModel> archiveThread(AIThreadModel thread) async {
    final now = DateTime.now().toUtc();
    final updated = AIThreadModel(
      id: thread.id,
      scope: thread.scope,
      title: thread.title,
      workspaceId: thread.workspaceId,
      taskId: thread.taskId,
      knowledgeId: thread.knowledgeId,
      createdAt: thread.createdAt,
      updatedAt: now,
      archivedAt: now,
    );
    await threads.update(updated);
    return updated;
  }

  Future<AIMessageModel> _addMessage({
    required AIThreadModel thread,
    required String role,
    required String content,
    required String contextSnapshotJson,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(content, 'content', 'AI message content is required.');
    }
    if (!const {'user', 'assistant', 'system'}.contains(role)) {
      throw ArgumentError.value(role, 'role', 'Unsupported AI message role.');
    }

    final existing = await threads.getById(thread.id);
    if (existing == null || existing.archivedAt != null) {
      throw StateError('AI thread not found or archived: ${thread.id}');
    }

    final now = DateTime.now().toUtc();
    final message = AIMessageModel(
      id: newWorkbenchId(),
      threadId: thread.id,
      role: role,
      content: trimmed,
      contextSnapshotJson: contextSnapshotJson,
      createdAt: now,
    );
    await messages.insert(message);

    final updatedThread = AIThreadModel(
      id: existing.id,
      scope: existing.scope,
      title: existing.title.isEmpty && role == 'user'
          ? _defaultTitle(trimmed)
          : existing.title,
      workspaceId: existing.workspaceId,
      taskId: existing.taskId,
      knowledgeId: existing.knowledgeId,
      createdAt: existing.createdAt,
      updatedAt: now,
      archivedAt: existing.archivedAt,
    );
    await threads.update(updatedThread);
    return message;
  }

  Future<void> _validateAnchor({
    required AIContextScope scope,
    String? workspaceId,
    String? taskId,
    String? knowledgeId,
  }) async {
    switch (scope) {
      case AIContextScope.task:
        if (taskId == null || taskId.trim().isEmpty) {
          throw ArgumentError('task scope requires taskId.');
        }
        final task = await tasks.getById(taskId);
        if (task == null || task.archivedAt != null) {
          throw StateError('Task not found or archived: $taskId');
        }
        if (workspaceId != null && workspaceId != task.workspaceId) {
          throw StateError('taskId does not belong to workspaceId.');
        }
      case AIContextScope.workspace:
        if (workspaceId == null || workspaceId.trim().isEmpty) {
          throw ArgumentError('workspace scope requires workspaceId.');
        }
        final workspace = await workspaces.getById(workspaceId);
        if (workspace == null || workspace.archivedAt != null) {
          throw StateError('Workspace not found or archived: $workspaceId');
        }
      case AIContextScope.knowledge:
        if (knowledgeId == null || knowledgeId.trim().isEmpty) {
          throw ArgumentError('knowledge scope requires knowledgeId.');
        }
        final item = await knowledge.getById(knowledgeId);
        if (item == null || item.archivedAt != null) {
          throw StateError('Knowledge not found or archived: $knowledgeId');
        }
      case AIContextScope.global:
        return;
    }
  }
}

String _defaultTitle(String message) {
  final normalized = message.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= 36) return normalized;
  return '${normalized.substring(0, 36)}…';
}
