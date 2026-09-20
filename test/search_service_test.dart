import 'dart:async';

import 'package:cloud_disk/workbench/application/search_service.dart';
import 'package:cloud_disk/workbench/core/app_paths.dart';
import 'package:cloud_disk/workbench/core/developer_models.dart';
import 'package:cloud_disk/workbench/core/models.dart';
import 'package:cloud_disk/workbench/data/markdown_store.dart';
import 'package:cloud_disk/workbench/domain/decision_repository.dart';
import 'package:cloud_disk/workbench/domain/developer_command_repository.dart';
import 'package:cloud_disk/workbench/domain/developer_project_repository.dart';
import 'package:cloud_disk/workbench/domain/developer_snippet_repository.dart';
import 'package:cloud_disk/workbench/domain/issue_repository.dart';
import 'package:cloud_disk/workbench/domain/knowledge_repository.dart';
import 'package:cloud_disk/workbench/domain/repositories.dart';
import 'package:cloud_disk/workbench/domain/resource_repository.dart';
import 'package:cloud_disk/workbench/domain/search_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 9, 20, 9);
  final workspace = WorkspaceModel(
    id: 'workspace-1',
    name: 'Workbench',
    slug: 'workbench',
    status: 'active',
    createdAt: now,
    updatedAt: now,
  );
  final task = TaskModel(
    id: 'task-1',
    workspaceId: workspace.id,
    title: 'Search hardening',
    description: 'Add stable tests',
    status: 'doing',
    progress: 50,
    nextStep: 'Run flutter test',
    priority: 1,
    isCurrent: true,
    createdAt: now,
    updatedAt: now,
  );

  SearchService createService(
    _FakeSearchIndex index, {
    Duration freshnessWindow = const Duration(minutes: 2),
  }) {
    return SearchService(
      workspaces: _WorkspaceRepository([workspace]),
      tasks: _TaskRepository([task]),
      notes: _NoteRepository(),
      issues: _IssueRepository(),
      resources: _ResourceRepository(),
      decisions: _DecisionRepository(),
      knowledge: _KnowledgeRepository(),
      developerProjects: _DeveloperProjectRepository(),
      developerCommands: _DeveloperCommandRepository(),
      developerSnippets: _DeveloperSnippetRepository(),
      markdownStore: _FakeMarkdownStore(),
      index: index,
      freshnessWindow: freshnessWindow,
    );
  }

  group('SearchService', () {
    test('rebuildIndex writes active workspace entities into the index', () async {
      final index = _FakeSearchIndex();
      final service = createService(index);

      await service.rebuildIndex();

      expect(index.clearCalls, 1);
      expect(index.replacements, hasLength(1));
      expect(index.replacements.single.entityType, 'task');
      expect(index.replacements.single.entityId, 'task-1');
      expect(index.replacements.single.workspaceId, 'workspace-1');
      expect(index.replacements.single.title, 'Search hardening');
      expect(
        index.replacements.single.body,
        'Add stable tests\nRun flutter test\ndoing',
      );
    });

    test('ensureFreshIndex does not rebuild again inside freshness window', () async {
      final index = _FakeSearchIndex();
      final service = createService(
        index,
        freshnessWindow: const Duration(hours: 1),
      );

      await service.rebuildIndex();
      await service.ensureFreshIndex();

      expect(index.clearCalls, 1);
      expect(index.replacements, hasLength(1));
    });

    test('concurrent rebuild requests share the same in-flight rebuild', () async {
      final blocker = Completer<void>();
      final index = _FakeSearchIndex(clearBlocker: blocker);
      final service = createService(index);

      final first = service.rebuildIndex();
      await Future<void>.delayed(Duration.zero);
      final second = service.rebuildIndex();

      expect(index.clearCalls, 1);

      blocker.complete();
      await Future.wait([first, second]);

      expect(index.clearCalls, 1);
      expect(index.replacements, hasLength(1));
    });

    test('search forwards filters and limit to index repository', () async {
      final expected = SearchResultModel(
        entityType: 'task',
        entityId: 'task-1',
        title: 'Search hardening',
        snippet: 'stable tests',
        workspaceId: 'workspace-1',
        score: 2,
      );
      final index = _FakeSearchIndex(searchResults: [expected]);
      final service = createService(index);

      final result = await service.search(
        'hardening',
        entityTypes: {'task'},
        workspaceId: 'workspace-1',
        limit: 12,
      );

      expect(result, [expected]);
      expect(index.lastQuery, 'hardening');
      expect(index.lastEntityTypes, {'task'});
      expect(index.lastWorkspaceId, 'workspace-1');
      expect(index.lastLimit, 12);
    });
  });
}

class _WorkspaceRepository implements WorkspaceRepository {
  _WorkspaceRepository(this.active);

  final List<WorkspaceModel> active;

  @override
  Future<List<WorkspaceModel>> listActive() async => active;

  @override
  Future<List<WorkspaceModel>> listArchived() async => const [];

  @override
  Future<WorkspaceModel?> getById(String id) async => null;

  @override
  Future<WorkspaceModel?> getBySlug(String slug) async => null;

  @override
  Future<void> insert(WorkspaceModel workspace) =>
      throw UnimplementedError();

  @override
  Future<void> update(WorkspaceModel workspace) =>
      throw UnimplementedError();
}

class _TaskRepository implements TaskRepository {
  _TaskRepository(this.items);

  final List<TaskModel> items;

  @override
  Future<List<TaskModel>> listByWorkspace(String workspaceId) async =>
      items.where((item) => item.workspaceId == workspaceId).toList();

  @override
  Future<TaskModel?> getById(String id) async => null;

  @override
  Future<TaskModel?> getCurrent(String workspaceId) async => null;

  @override
  Future<void> insert(TaskModel task) => throw UnimplementedError();

  @override
  Future<void> update(TaskModel task) => throw UnimplementedError();

  @override
  Future<void> setCurrent(String workspaceId, String taskId) =>
      throw UnimplementedError();
}

class _NoteRepository implements NoteRepository {
  @override
  Future<List<NoteModel>> listByWorkspace(String workspaceId) async => const [];

  @override
  Future<NoteModel?> getById(String id) async => null;

  @override
  Future<List<NoteModel>> getByIds(List<String> ids) async => const [];

  @override
  Future<void> insert(NoteModel note) => throw UnimplementedError();

  @override
  Future<void> touchUpdatedAt(String noteId, DateTime updatedAt) =>
      throw UnimplementedError();
}

class _IssueRepository implements IssueRepository {
  @override
  Future<List<IssueModel>> listByWorkspace(String workspaceId) async => const [];

  @override
  Future<IssueModel?> getById(String id) async => null;

  @override
  Future<List<IssueModel>> getByIds(List<String> ids) async => const [];

  @override
  Future<void> insert(IssueModel issue) => throw UnimplementedError();

  @override
  Future<void> update(IssueModel issue) => throw UnimplementedError();
}

class _ResourceRepository implements ResourceRepository {
  @override
  Future<List<ResourceModel>> listByWorkspace(String workspaceId) async =>
      const [];

  @override
  Future<ResourceModel?> getById(String id) async => null;

  @override
  Future<List<ResourceModel>> getByIds(List<String> ids) async => const [];

  @override
  Future<void> insert(ResourceModel resource) => throw UnimplementedError();

  @override
  Future<void> update(ResourceModel resource) => throw UnimplementedError();
}

class _DecisionRepository implements DecisionRepository {
  @override
  Future<List<DecisionModel>> listByWorkspace(String workspaceId) async =>
      const [];

  @override
  Future<DecisionModel?> getById(String id) async => null;

  @override
  Future<List<DecisionModel>> getByIds(List<String> ids) async => const [];

  @override
  Future<void> insert(DecisionModel decision) => throw UnimplementedError();

  @override
  Future<void> update(DecisionModel decision) => throw UnimplementedError();
}

class _KnowledgeRepository implements KnowledgeRepository {
  @override
  Future<List<KnowledgeModel>> listActive({String? category}) async => const [];

  @override
  Future<KnowledgeModel?> getById(String id) async => null;

  @override
  Future<List<KnowledgeModel>> getByIds(List<String> ids) async => const [];

  @override
  Future<void> insert(KnowledgeModel knowledge) => throw UnimplementedError();

  @override
  Future<void> update(KnowledgeModel knowledge) => throw UnimplementedError();
}

class _DeveloperProjectRepository implements DeveloperProjectRepository {
  @override
  Future<List<DeveloperProjectModel>> listByWorkspace(String workspaceId) async =>
      const [];

  @override
  Future<DeveloperProjectModel?> getById(String id) async => null;

  @override
  Future<DeveloperProjectModel?> getPrimary(String workspaceId) async => null;

  @override
  Future<List<DeveloperProjectModel>> getByIds(List<String> ids) async =>
      const [];

  @override
  Future<void> insert(DeveloperProjectModel project) =>
      throw UnimplementedError();

  @override
  Future<void> update(DeveloperProjectModel project) =>
      throw UnimplementedError();
}

class _DeveloperCommandRepository implements DeveloperCommandRepository {
  @override
  Future<List<DeveloperCommandModel>> listByWorkspace(String workspaceId) async =>
      const [];

  @override
  Future<List<DeveloperCommandModel>> listByProject(String projectId) async =>
      const [];

  @override
  Future<DeveloperCommandModel?> getById(String id) async => null;

  @override
  Future<List<DeveloperCommandModel>> getByIds(List<String> ids) async =>
      const [];

  @override
  Future<void> insert(DeveloperCommandModel command) =>
      throw UnimplementedError();

  @override
  Future<void> update(DeveloperCommandModel command) =>
      throw UnimplementedError();
}

class _DeveloperSnippetRepository implements DeveloperSnippetRepository {
  @override
  Future<List<DeveloperSnippetModel>> listByWorkspace(String workspaceId) async =>
      const [];

  @override
  Future<List<DeveloperSnippetModel>> listByProject(String projectId) async =>
      const [];

  @override
  Future<DeveloperSnippetModel?> getById(String id) async => null;

  @override
  Future<List<DeveloperSnippetModel>> getByIds(List<String> ids) async =>
      const [];

  @override
  Future<void> insert(DeveloperSnippetModel snippet) =>
      throw UnimplementedError();

  @override
  Future<void> update(DeveloperSnippetModel snippet) =>
      throw UnimplementedError();
}

class _FakeMarkdownStore implements MarkdownStore {
  @override
  AppPaths get paths => throw UnimplementedError();

  @override
  Future<bool> exists(String relativePath) async => false;

  @override
  Future<String> read(String relativePath) async => '';

  @override
  Future<void> writeAtomic(String relativePath, String content) async {}

  @override
  Future<void> deleteIfExists(String relativePath) async {}
}

class _IndexReplacement {
  const _IndexReplacement({
    required this.entityType,
    required this.entityId,
    required this.workspaceId,
    required this.title,
    required this.body,
  });

  final String entityType;
  final String entityId;
  final String? workspaceId;
  final String title;
  final String body;
}

class _FakeSearchIndex implements SearchIndexRepository {
  _FakeSearchIndex({
    this.clearBlocker,
    this.searchResults = const [],
  });

  final Completer<void>? clearBlocker;
  final List<SearchResultModel> searchResults;

  int clearCalls = 0;
  final List<_IndexReplacement> replacements = [];

  String? lastQuery;
  Set<String>? lastEntityTypes;
  String? lastWorkspaceId;
  int? lastLimit;

  @override
  Future<void> clear() async {
    clearCalls += 1;
    if (clearBlocker != null) {
      await clearBlocker!.future;
    }
  }

  @override
  Future<void> replace({
    required String entityType,
    required String entityId,
    String? workspaceId,
    required String title,
    required String body,
  }) async {
    replacements.add(
      _IndexReplacement(
        entityType: entityType,
        entityId: entityId,
        workspaceId: workspaceId,
        title: title,
        body: body,
      ),
    );
  }

  @override
  Future<void> remove({
    required String entityType,
    required String entityId,
  }) async {}

  @override
  Future<List<SearchResultModel>> search(
    String query, {
    Set<String>? entityTypes,
    String? workspaceId,
    int limit = 50,
  }) async {
    lastQuery = query;
    lastEntityTypes = entityTypes;
    lastWorkspaceId = workspaceId;
    lastLimit = limit;
    return searchResults;
  }
}
