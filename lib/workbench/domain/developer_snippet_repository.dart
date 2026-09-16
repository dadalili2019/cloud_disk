import '../core/developer_models.dart';

abstract interface class DeveloperSnippetRepository {
  Future<List<DeveloperSnippetModel>> listByWorkspace(String workspaceId);
  Future<List<DeveloperSnippetModel>> listByProject(String projectId);
  Future<DeveloperSnippetModel?> getById(String id);
  Future<List<DeveloperSnippetModel>> getByIds(List<String> ids);
  Future<void> insert(DeveloperSnippetModel snippet);
  Future<void> update(DeveloperSnippetModel snippet);
}
