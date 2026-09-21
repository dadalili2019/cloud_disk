import 'dart:io';

import 'package:cloud_disk/workbench/application/knowledge_service.dart';
import 'package:cloud_disk/workbench/core/app_paths.dart';
import 'package:cloud_disk/workbench/core/models.dart';
import 'package:cloud_disk/workbench/data/markdown_store.dart';
import 'package:cloud_disk/workbench/domain/knowledge_repository.dart';
import 'package:cloud_disk/workbench/domain/repositories.dart';
import 'package:cloud_disk/workbench/domain/search_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('KnowledgeService', () {
    late Directory tempDirectory;
    late AppPaths paths;
    late MarkdownStore store;
    late _KnowledgeRepository knowledge;
    late _EntityLinkRepository links;
    late _SearchIndexRepository search;
    late KnowledgeService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'personal_workbench_knowledge_service_',
      );
      paths = await AppPaths.createAt(
        Directory(p.join(tempDirectory.path, 'app')),
      );
      store = MarkdownStore(paths);
      knowledge = _KnowledgeRepository();
      links = _EntityLinkRepository();
      search = _SearchIndexRepository();
      service = KnowledgeService(
        paths: paths,
        store: store,
        knowledge: knowledge,
        links: links,
        searchIndex: search,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('create writes markdown, source links and search index', () async {
      final item = await service.create(
        title: '  Search Notes  ',
        category: '  Reference  ',
        summary: '  Search summary  ',
        useWhen: '  When debugging  ',
        markdown: '# Search Notes\n\nDetails',
        isPinned: true,
        sources: const [
          KnowledgeSourceRef(entityType: 'note', entityId: 'note-1'),
          KnowledgeSourceRef(entityType: 'decision', entityId: 'decision-1'),
        ],
      );

      expect(item.title, 'Search Notes');
      expect(item.category, 'Reference');
      expect(item.summary, 'Search summary');
      expect(item.useWhen, 'When debugging');
      expect(item.isPinned, isTrue);
      expect(knowledge.inserted, [item]);
      expect(
        await store.read(item.filePath),
        '# Search Notes\n\nDetails',
      );

      expect(links.linkCalls, hasLength(2));
      expect(links.linkCalls[0].fromType, 'knowledge');
      expect(links.linkCalls[0].fromId, item.id);
      expect(links.linkCalls[0].relationType, 'derived_from');
      expect(links.linkCalls[0].toType, 'note');
      expect(links.linkCalls[0].toId, 'note-1');
      expect(links.linkCalls[1].toType, 'decision');
      expect(links.linkCalls[1].toId, 'decision-1');

      expect(search.replacements, hasLength(1));
      expect(search.replacements.single.entityType, 'knowledge');
      expect(search.replacements.single.entityId, item.id);
      expect(search.replacements.single.title, 'Search Notes');
      expect(
        search.replacements.single.body,
        'Search summary\n\nWhen debugging\n\n# Search Notes\n\nDetails',
      );
    });

    test('create rejects empty title before writing data', () async {
      await expectLater(
        service.create(title: '   ', markdown: '# ignored'),
        throwsArgumentError,
      );

      expect(knowledge.inserted, isEmpty);
      expect(links.linkCalls, isEmpty);
      expect(search.replacements, isEmpty);
      expect(paths.knowledgeDirectory.listSync(), isEmpty);
    });

    test('create uses unique markdown file when title path already exists', () async {
      const originalPath = 'knowledge/repeated-title.md';
      await store.writeAtomic(originalPath, '# Existing');

      final item = await service.create(
        title: 'Repeated Title',
        markdown: '# New',
      );

      expect(item.filePath, isNot(originalPath));
      expect(item.filePath, startsWith('knowledge/repeated-title-'));
      expect(item.filePath, endsWith('.md'));
      expect(await store.read(originalPath), '# Existing');
      expect(await store.read(item.filePath), '# New');
    });

    test('create removes markdown when repository insert fails', () async {
      knowledge.failInsert = true;

      await expectLater(
        service.create(
          title: 'Rollback Me',
          markdown: '# Temporary',
        ),
        throwsA(isA<StateError>()),
      );

      expect(knowledge.insertAttempts, hasLength(1));
      final attempted = knowledge.insertAttempts.single;
      expect(await store.exists(attempted.filePath), isFalse);
      expect(search.replacements, isEmpty);
    });

    test('update preserves identity and file path while reindexing content', () async {
      final now = DateTime.utc(2026, 9, 21, 9);
      const filePath = 'knowledge/existing.md';
      await store.writeAtomic(filePath, '# Old');
      final original = KnowledgeModel(
        id: 'knowledge-1',
        title: 'Old',
        category: 'Old Category',
        summary: 'Old Summary',
        useWhen: 'Old Use',
        filePath: filePath,
        isPinned: false,
        createdAt: now,
        updatedAt: now,
      );

      final updated = await service.update(
        item: original,
        title: '  New Title  ',
        category: '  Decision  ',
        summary: '  New Summary  ',
        useWhen: '  New Use  ',
        markdown: '# New Content',
        isPinned: true,
      );

      expect(updated.id, original.id);
      expect(updated.filePath, original.filePath);
      expect(updated.createdAt, original.createdAt);
      expect(updated.title, 'New Title');
      expect(updated.category, 'Decision');
      expect(updated.summary, 'New Summary');
      expect(updated.useWhen, 'New Use');
      expect(updated.isPinned, isTrue);
      expect(knowledge.updated, [updated]);
      expect(await store.read(filePath), '# New Content');
      expect(search.replacements.single.entityId, original.id);
      expect(
        search.replacements.single.body,
        'New Summary\n\nNew Use\n\n# New Content',
      );
    });

    test('sources resolves derived_from links for supported entity types', () async {
      final item = _knowledge();
      links.toIds['knowledge|knowledge-1|derived_from|note'] = ['note-1'];
      links.toIds['knowledge|knowledge-1|derived_from|decision'] = [
        'decision-1',
      ];
      links.toIds['knowledge|knowledge-1|derived_from|task'] = ['task-1'];

      final result = await service.sources(item);

      expect(
        result.map((ref) => '${ref.entityType}:${ref.entityId}'),
        ['note:note-1', 'decision:decision-1', 'task:task-1'],
      );
      expect(links.listToCalls, hasLength(5));
      expect(
        links.listToCalls.map((call) => call.relationType).toSet(),
        {'derived_from'},
      );
    });

    test('attachToTask creates applies_to relationship', () async {
      await service.attachToTask('knowledge-1', 'task-1');

      expect(links.linkCalls, hasLength(1));
      final call = links.linkCalls.single;
      expect(call.fromType, 'knowledge');
      expect(call.fromId, 'knowledge-1');
      expect(call.relationType, 'applies_to');
      expect(call.toType, 'task');
      expect(call.toId, 'task-1');
    });
  });
}

KnowledgeModel _knowledge() {
  final now = DateTime.utc(2026, 9, 21, 9);
  return KnowledgeModel(
    id: 'knowledge-1',
    title: 'Knowledge',
    category: 'Reference',
    summary: 'Summary',
    useWhen: 'Use',
    filePath: 'knowledge/knowledge.md',
    isPinned: false,
    createdAt: now,
    updatedAt: now,
  );
}

class _KnowledgeRepository implements KnowledgeRepository {
  final List<KnowledgeModel> inserted = [];
  final List<KnowledgeModel> insertAttempts = [];
  final List<KnowledgeModel> updated = [];
  bool failInsert = false;

  @override
  Future<List<KnowledgeModel>> listActive({String? category}) async {
    if (category == null || category.trim().isEmpty) return inserted;
    return inserted.where((item) => item.category == category.trim()).toList();
  }

  @override
  Future<KnowledgeModel?> getById(String id) async {
    for (final item in [...inserted, ...updated.reversed]) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<List<KnowledgeModel>> getByIds(List<String> ids) async {
    return inserted.where((item) => ids.contains(item.id)).toList();
  }

  @override
  Future<void> insert(KnowledgeModel item) async {
    insertAttempts.add(item);
    if (failInsert) {
      throw StateError('insert failed');
    }
    inserted.add(item);
  }

  @override
  Future<void> update(KnowledgeModel item) async {
    updated.add(item);
  }
}

class _LinkCall {
  const _LinkCall({
    required this.fromType,
    required this.fromId,
    required this.relationType,
    required this.toType,
    required this.toId,
  });

  final String fromType;
  final String fromId;
  final String relationType;
  final String toType;
  final String toId;
}

class _ListToCall {
  const _ListToCall({
    required this.fromType,
    required this.fromId,
    required this.relationType,
    required this.toType,
  });

  final String fromType;
  final String fromId;
  final String relationType;
  final String toType;
}

class _EntityLinkRepository implements EntityLinkRepository {
  final List<_LinkCall> linkCalls = [];
  final List<_ListToCall> listToCalls = [];
  final Map<String, List<String>> toIds = {};

  @override
  Future<void> link({
    required String id,
    required String fromType,
    required String fromId,
    required String relationType,
    required String toType,
    required String toId,
    required DateTime createdAt,
  }) async {
    linkCalls.add(
      _LinkCall(
        fromType: fromType,
        fromId: fromId,
        relationType: relationType,
        toType: toType,
        toId: toId,
      ),
    );
  }

  @override
  Future<List<String>> listFromIds({
    required String toType,
    required String toId,
    required String relationType,
    required String fromType,
  }) async => const [];

  @override
  Future<List<String>> listToIds({
    required String fromType,
    required String fromId,
    required String relationType,
    required String toType,
  }) async {
    listToCalls.add(
      _ListToCall(
        fromType: fromType,
        fromId: fromId,
        relationType: relationType,
        toType: toType,
      ),
    );
    return toIds[
            '$fromType|$fromId|$relationType|$toType'] ??
        const [];
  }
}

class _Replacement {
  const _Replacement({
    required this.entityType,
    required this.entityId,
    required this.title,
    required this.body,
  });

  final String entityType;
  final String entityId;
  final String title;
  final String body;
}

class _SearchIndexRepository implements SearchIndexRepository {
  final List<_Replacement> replacements = [];

  @override
  Future<void> clear() async {}

  @override
  Future<void> rebuild(List<SearchIndexEntry> entries) async {}

  @override
  Future<void> replace({
    required String entityType,
    required String entityId,
    String? workspaceId,
    required String title,
    required String body,
  }) async {
    replacements.add(
      _Replacement(
        entityType: entityType,
        entityId: entityId,
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
  }) async => const [];
}
