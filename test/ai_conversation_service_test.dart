import 'dart:convert';

import 'package:cloud_disk/workbench/application/ai_conversation_service.dart';
import 'package:cloud_disk/workbench/core/ai_context_models.dart';
import 'package:cloud_disk/workbench/core/ai_conversation_models.dart';
import 'package:cloud_disk/workbench/core/models.dart';
import 'package:cloud_disk/workbench/domain/ai_conversation_repository.dart';
import 'package:cloud_disk/workbench/domain/knowledge_repository.dart';
import 'package:cloud_disk/workbench/domain/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AIConversationService', () {
    late _ThreadRepository threads;
    late _MessageRepository messages;
    late _WorkspaceRepository workspaces;
    late _TaskRepository tasks;
    late _KnowledgeRepository knowledge;
    late AIConversationService service;

    setUp(() {
      threads = _ThreadRepository();
      messages = _MessageRepository();
      workspaces = _WorkspaceRepository();
      tasks = _TaskRepository();
      knowledge = _KnowledgeRepository();
      service = AIConversationService(
        threads: threads,
        messages: messages,
        workspaces: workspaces,
        tasks: tasks,
        knowledge: knowledge,
      );
    });

    test('creates global thread without anchor', () async {
      final thread = await service.createThread(
        scope: AIContextScope.global,
        title: '  Global Chat  ',
      );

      expect(thread.scope, AIContextScope.global);
      expect(thread.title, 'Global Chat');
      expect(thread.workspaceId, isNull);
      expect(thread.taskId, isNull);
      expect(thread.knowledgeId, isNull);
      expect(threads.inserted, [thread]);
    });

    test('task thread resolves workspace from task', () async {
      tasks.byId['task-1'] = _task();

      final thread = await service.createThread(
        scope: AIContextScope.task,
        taskId: 'task-1',
      );

      expect(thread.taskId, 'task-1');
      expect(thread.workspaceId, 'workspace-1');
      expect(threads.inserted, [thread]);
    });

    test('rejects task anchor that does not belong to supplied workspace', () async {
      tasks.byId['task-1'] = _task();

      await expectLater(
        service.createThread(
          scope: AIContextScope.task,
          workspaceId: 'workspace-2',
          taskId: 'task-1',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'taskId does not belong to workspaceId.',
          ),
        ),
      );
      expect(threads.inserted, isEmpty);
    });

    test('rejects archived workspace and knowledge anchors', () async {
      workspaces.byId['workspace-1'] = _workspace(
        archivedAt: DateTime.utc(2026, 9, 21),
      );
      knowledge.byId['knowledge-1'] = _knowledge(
        archivedAt: DateTime.utc(2026, 9, 21),
      );

      await expectLater(
        service.createThread(
          scope: AIContextScope.workspace,
          workspaceId: 'workspace-1',
        ),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        service.createThread(
          scope: AIContextScope.knowledge,
          knowledgeId: 'knowledge-1',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('first user message trims content and becomes thread title', () async {
      final thread = _thread(title: '');
      threads.byId[thread.id] = thread;

      final message = await service.addUserMessage(
        thread: thread,
        content: '  This is the first user message  ',
      );

      expect(message.role, 'user');
      expect(message.content, 'This is the first user message');
      expect(messages.inserted, [message]);

      final updated = threads.updated.single;
      expect(updated.id, thread.id);
      expect(updated.title, 'This is the first user message');
      expect(updated.updatedAt.isBefore(message.createdAt), isFalse);
    });

    test('long first user message uses bounded default title', () async {
      final thread = _thread(title: '');
      threads.byId[thread.id] = thread;
      const content = 'abcdefghijklmnopqrstuvwxyz0123456789---tail';

      await service.addUserMessage(
        thread: thread,
        content: content,
      );

      final title = threads.updated.single.title;
      expect(title.endsWith('…'), isTrue);
      expect(title.length, 37);
    });

    test('assistant message stores reference snapshot only', () async {
      final thread = _thread(title: 'Thread');
      threads.byId[thread.id] = thread;

      final context = AIContextModel(
        scope: AIContextScope.task,
        generatedAt: DateTime.utc(2026, 9, 21),
        anchor: const AIContextRef(
          entityType: 'task',
          entityId: 'task-1',
          title: 'Task One',
          workspaceId: 'workspace-1',
        ),
        workspace: _workspace(),
        items: const [
          AIContextItem(
            ref: AIContextRef(
              entityType: 'knowledge',
              entityId: 'knowledge-1',
              title: 'Knowledge One',
            ),
            priority: 1,
            reason: 'related',
            content: 'This full body must not be copied into the snapshot.',
          ),
        ],
        excludedRefs: const [],
      );

      final message = await service.addAssistantMessage(
        thread: thread,
        content: '  Assistant answer  ',
        context: context,
      );

      expect(message.role, 'assistant');
      expect(message.content, 'Assistant answer');

      final snapshot =
          jsonDecode(message.contextSnapshotJson) as Map<String, dynamic>;
      expect(snapshot['scope'], 'task');
      expect(snapshot['workspace_id'], 'workspace-1');
      expect(
        jsonEncode(snapshot),
        isNot(contains('This full body must not be copied')),
      );
      expect(
        (snapshot['entities'] as List).single['id'],
        'knowledge-1',
      );
    });

    test('rejects empty messages before repository write', () async {
      final thread = _thread();
      threads.byId[thread.id] = thread;

      await expectLater(
        service.addUserMessage(thread: thread, content: '   '),
        throwsArgumentError,
      );

      expect(messages.inserted, isEmpty);
      expect(threads.updated, isEmpty);
    });

    test('rejects adding message to archived thread', () async {
      final thread = _thread(
        archivedAt: DateTime.utc(2026, 9, 21),
      );
      threads.byId[thread.id] = thread;

      await expectLater(
        service.addUserMessage(thread: thread, content: 'Hello'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('not found or archived'),
          ),
        ),
      );

      expect(messages.inserted, isEmpty);
    });

    test('archive prevents future messages but keeps existing history', () async {
      final thread = _thread();
      threads.byId[thread.id] = thread;
      final existing = _message('message-1', thread.id, 'user', 'Persisted');
      messages.inserted.add(existing);

      final archived = await service.archiveThread(thread);

      expect(archived.archivedAt, isNotNull);
      expect(threads.updated.last.archivedAt, isNotNull);
      expect(
        (await service.listMessages(thread.id)).single.content,
        'Persisted',
      );

      await expectLater(
        service.addAssistantMessage(
          thread: archived,
          content: 'Should fail',
          context: _emptyContext(),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

AIContextModel _emptyContext() {
  return AIContextModel(
    scope: AIContextScope.global,
    generatedAt: DateTime.utc(2026, 9, 21),
    items: const [],
    excludedRefs: const [],
  );
}

AIThreadModel _thread({
  String title = 'Thread',
  DateTime? archivedAt,
}) {
  final now = DateTime.utc(2026, 9, 21, 9);
  return AIThreadModel(
    id: 'thread-1',
    scope: AIContextScope.global,
    title: title,
    createdAt: now,
    updatedAt: now,
    archivedAt: archivedAt,
  );
}

AIMessageModel _message(
  String id,
  String threadId,
  String role,
  String content,
) {
  return AIMessageModel(
    id: id,
    threadId: threadId,
    role: role,
    content: content,
    contextSnapshotJson: '',
    createdAt: DateTime.utc(2026, 9, 21, 9),
  );
}

WorkspaceModel _workspace({DateTime? archivedAt}) {
  final now = DateTime.utc(2026, 9, 21, 9);
  return WorkspaceModel(
    id: 'workspace-1',
    name: 'Workspace',
    slug: 'workspace',
    status: archivedAt == null ? 'active' : 'archived',
    createdAt: now,
    updatedAt: now,
    archivedAt: archivedAt,
  );
}

TaskModel _task({DateTime? archivedAt}) {
  final now = DateTime.utc(2026, 9, 21, 9);
  return TaskModel(
    id: 'task-1',
    workspaceId: 'workspace-1',
    title: 'Task',
    description: '',
    status: archivedAt == null ? 'doing' : 'archived',
    progress: 20,
    nextStep: '',
    priority: 1,
    isCurrent: false,
    createdAt: now,
    updatedAt: now,
    archivedAt: archivedAt,
  );
}

KnowledgeModel _knowledge({DateTime? archivedAt}) {
  final now = DateTime.utc(2026, 9, 21, 9);
  return KnowledgeModel(
    id: 'knowledge-1',
    title: 'Knowledge',
    category: 'reference',
    summary: '',
    useWhen: '',
    filePath: 'knowledge/knowledge.md',
    isPinned: false,
    createdAt: now,
    updatedAt: now,
    archivedAt: archivedAt,
  );
}

class _ThreadRepository implements AIThreadRepository {
  final Map<String, AIThreadModel> byId = {};
  final List<AIThreadModel> inserted = [];
  final List<AIThreadModel> updated = [];

  @override
  Future<List<AIThreadModel>> listActive({int limit = 50}) async {
    return byId.values
        .where((thread) => thread.archivedAt == null)
        .take(limit)
        .toList();
  }

  @override
  Future<AIThreadModel?> getById(String id) async => byId[id];

  @override
  Future<List<AIThreadModel>> listByAnchor({
    String? workspaceId,
    String? taskId,
    String? knowledgeId,
    int limit = 50,
  }) async {
    return byId.values.where((thread) {
      if (thread.archivedAt != null) return false;
      if (workspaceId != null && thread.workspaceId != workspaceId) return false;
      if (taskId != null && thread.taskId != taskId) return false;
      if (knowledgeId != null && thread.knowledgeId != knowledgeId) return false;
      return true;
    }).take(limit).toList();
  }

  @override
  Future<void> insert(AIThreadModel thread) async {
    inserted.add(thread);
    byId[thread.id] = thread;
  }

  @override
  Future<void> update(AIThreadModel thread) async {
    updated.add(thread);
    byId[thread.id] = thread;
  }
}

class _MessageRepository implements AIMessageRepository {
  final List<AIMessageModel> inserted = [];

  @override
  Future<List<AIMessageModel>> listByThread(String threadId) async {
    return inserted
        .where((message) => message.threadId == threadId)
        .toList();
  }

  @override
  Future<void> insert(AIMessageModel message) async {
    inserted.add(message);
  }
}

class _WorkspaceRepository implements WorkspaceRepository {
  final Map<String, WorkspaceModel> byId = {};

  @override
  Future<List<WorkspaceModel>> listActive() async => byId.values.toList();

  @override
  Future<List<WorkspaceModel>> listArchived() async => const [];

  @override
  Future<WorkspaceModel?> getById(String id) async => byId[id];

  @override
  Future<WorkspaceModel?> getBySlug(String slug) async => null;

  @override
  Future<void> insert(WorkspaceModel workspace) async {
    byId[workspace.id] = workspace;
  }

  @override
  Future<void> update(WorkspaceModel workspace) async {
    byId[workspace.id] = workspace;
  }
}

class _TaskRepository implements TaskRepository {
  final Map<String, TaskModel> byId = {};

  @override
  Future<List<TaskModel>> listByWorkspace(String workspaceId) async {
    return byId.values
        .where((task) => task.workspaceId == workspaceId)
        .toList();
  }

  @override
  Future<TaskModel?> getById(String id) async => byId[id];

  @override
  Future<TaskModel?> getCurrent(String workspaceId) async => null;

  @override
  Future<void> insert(TaskModel task) async {
    byId[task.id] = task;
  }

  @override
  Future<void> update(TaskModel task) async {
    byId[task.id] = task;
  }

  @override
  Future<void> setCurrent(String workspaceId, String taskId) async {}
}

class _KnowledgeRepository implements KnowledgeRepository {
  final Map<String, KnowledgeModel> byId = {};

  @override
  Future<List<KnowledgeModel>> listActive({String? category}) async {
    return byId.values.toList();
  }

  @override
  Future<KnowledgeModel?> getById(String id) async => byId[id];

  @override
  Future<List<KnowledgeModel>> getByIds(List<String> ids) async {
    return ids.map((id) => byId[id]).whereType<KnowledgeModel>().toList();
  }

  @override
  Future<void> insert(KnowledgeModel knowledge) async {
    byId[knowledge.id] = knowledge;
  }

  @override
  Future<void> update(KnowledgeModel knowledge) async {
    byId[knowledge.id] = knowledge;
  }

  @override
  Future<void> delete(String id) async {
    byId.remove(id);
  }
}
