import '../core/app_paths.dart';
import '../core/models.dart';
import '../core/workbench_utils.dart';
import '../data/markdown_store.dart';
import '../domain/knowledge_repository.dart';
import '../domain/repositories.dart';
import '../domain/search_repository.dart';

class KnowledgeSourceRef {
  const KnowledgeSourceRef({required this.entityType, required this.entityId});

  final String entityType;
  final String entityId;
}

class KnowledgeService {
  const KnowledgeService({
    required this.paths,
    required this.store,
    required this.knowledge,
    required this.links,
    required this.searchIndex,
  });

  final AppPaths paths;
  final MarkdownStore store;
  final KnowledgeRepository knowledge;
  final EntityLinkRepository links;
  final SearchIndexRepository searchIndex;

  Future<List<KnowledgeModel>> list({String? category}) =>
      knowledge.listActive(category: category);

  Future<KnowledgeModel?> getById(String id) => knowledge.getById(id);

  Future<String> readContent(KnowledgeModel item) => store.read(item.filePath);

  Future<List<KnowledgeSourceRef>> sources(KnowledgeModel item) async {
    const supported = ['note', 'decision', 'issue', 'resource', 'task'];
    final result = <KnowledgeSourceRef>[];
    for (final type in supported) {
      final ids = await links.listToIds(
        fromType: 'knowledge',
        fromId: item.id,
        relationType: 'derived_from',
        toType: type,
      );
      result.addAll(ids.map((id) => KnowledgeSourceRef(entityType: type, entityId: id)));
    }
    return result;
  }

  Future<KnowledgeModel> create({
    required String title,
    String category = '',
    String summary = '',
    String useWhen = '',
    String markdown = '',
    bool isPinned = false,
    List<KnowledgeSourceRef> sources = const [],
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Knowledge title is required.');
    }

    final id = newWorkbenchId();
    final requestedName = normalizeMarkdownFileName('', fallbackTitle: trimmedTitle);
    var fileName = requestedName;
    var relativePath = paths.knowledgeRelativePath(fileName);
    if (await store.exists(relativePath)) {
      final suffix = id.substring(0, 8);
      final stem = requestedName.substring(0, requestedName.length - 3);
      fileName = '$stem-$suffix.md';
      relativePath = paths.knowledgeRelativePath(fileName);
    }

    final now = DateTime.now().toUtc();
    final item = KnowledgeModel(
      id: id,
      title: trimmedTitle,
      category: category.trim(),
      summary: summary.trim(),
      useWhen: useWhen.trim(),
      filePath: relativePath,
      isPinned: isPinned,
      createdAt: now,
      updatedAt: now,
    );

    await store.writeAtomic(relativePath, markdown);
    try {
      await knowledge.insert(item);
      for (final source in sources) {
        await links.link(
          id: newWorkbenchId(),
          fromType: 'knowledge',
          fromId: item.id,
          relationType: 'derived_from',
          toType: source.entityType,
          toId: source.entityId,
          createdAt: now,
        );
      }
      await _index(item, markdown);
    } catch (_) {
      await _rollbackCreate(item, sources);
      rethrow;
    }
    return item;
  }

  Future<KnowledgeModel> update({
    required KnowledgeModel item,
    required String title,
    required String category,
    required String summary,
    required String useWhen,
    required String markdown,
    required bool isPinned,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Knowledge title is required.');
    }

    final updated = KnowledgeModel(
      id: item.id,
      title: trimmedTitle,
      category: category.trim(),
      summary: summary.trim(),
      useWhen: useWhen.trim(),
      filePath: item.filePath,
      isPinned: isPinned,
      createdAt: item.createdAt,
      updatedAt: DateTime.now().toUtc(),
      archivedAt: item.archivedAt,
    );

    final previousMarkdown = await store.read(item.filePath);
    try {
      await store.writeAtomic(updated.filePath, markdown);
      await knowledge.update(updated);
      await _index(updated, markdown);
      return updated;
    } catch (_) {
      await _rollbackUpdate(item, previousMarkdown);
      rethrow;
    }
  }

  Future<void> attachToTask(String knowledgeId, String taskId) {
    return links.link(
      id: newWorkbenchId(),
      fromType: 'knowledge',
      fromId: knowledgeId,
      relationType: 'applies_to',
      toType: 'task',
      toId: taskId,
      createdAt: DateTime.now().toUtc(),
    );
  }

  Future<void> _rollbackCreate(
    KnowledgeModel item,
    List<KnowledgeSourceRef> sources,
  ) async {
    await _bestEffort(
      () => searchIndex.remove(
        entityType: 'knowledge',
        entityId: item.id,
      ),
    );
    for (final source in sources.reversed) {
      await _bestEffort(
        () => links.unlink(
          fromType: 'knowledge',
          fromId: item.id,
          relationType: 'derived_from',
          toType: source.entityType,
          toId: source.entityId,
        ),
      );
    }
    await _bestEffort(() => knowledge.delete(item.id));
    await _bestEffort(() => store.deleteIfExists(item.filePath));
  }

  Future<void> _rollbackUpdate(
    KnowledgeModel original,
    String previousMarkdown,
  ) async {
    await _bestEffort(
      () => store.writeAtomic(original.filePath, previousMarkdown),
    );
    await _bestEffort(() => knowledge.update(original));
    await _bestEffort(() => _index(original, previousMarkdown));
  }

  Future<void> _bestEffort(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Preserve the original mutation failure for the caller.
    }
  }

  Future<void> _index(KnowledgeModel item, String markdown) {
    final body = [item.summary, item.useWhen, markdown]
        .where((value) => value.trim().isNotEmpty)
        .join('\n\n');
    return searchIndex.replace(
      entityType: 'knowledge',
      entityId: item.id,
      title: item.title,
      body: body,
    );
  }
}
