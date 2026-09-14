import '../core/models.dart';

abstract interface class SearchIndexRepository {
  Future<void> clear();

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
