import '../core/models.dart';

class SearchIndexEntry {
  const SearchIndexEntry({
    required this.entityType,
    required this.entityId,
    this.workspaceId,
    required this.title,
    required this.body,
  });

  final String entityType;
  final String entityId;
  final String? workspaceId;
  final String title;
  final String body;
}

abstract interface class SearchIndexRepository {
  Future<void> clear();

  Future<void> rebuild(List<SearchIndexEntry> entries);

  Future<void> replace({
    required String entityType,
    required String entityId,
    String? workspaceId,
    required String title,
    required String body,
  });

  Future<void> remove({
    required String entityType,
    required String entityId,
  });

  Future<List<SearchResultModel>> search(
    String query, {
    Set<String>? entityTypes,
    String? workspaceId,
    int limit = 50,
  });
}
