import '../core/developer_models.dart';

abstract interface class DeveloperCommandRepository {
  Future<List<DeveloperCommandModel>> listByWorkspace(String workspaceId);
  Future<List<DeveloperCommandModel>> listByProject(String projectId);
  Future<DeveloperCommandModel?> getById(String id);
  Future<List<DeveloperCommandModel>> getByIds(List<String> ids);
  Future<void> insert(DeveloperCommandModel command);
  Future<void> update(DeveloperCommandModel command);
}
