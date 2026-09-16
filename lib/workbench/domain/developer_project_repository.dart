import '../core/developer_models.dart';

abstract interface class DeveloperProjectRepository {
  Future<List<DeveloperProjectModel>> listByWorkspace(String workspaceId);
  Future<DeveloperProjectModel?> getById(String id);
  Future<DeveloperProjectModel?> getPrimary(String workspaceId);
  Future<List<DeveloperProjectModel>> getByIds(List<String> ids);
  Future<void> insert(DeveloperProjectModel project);
  Future<void> update(DeveloperProjectModel project);
}
