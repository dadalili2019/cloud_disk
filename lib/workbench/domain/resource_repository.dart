import '../core/models.dart';

abstract interface class ResourceRepository {
  Future<List<ResourceModel>> listByWorkspace(String workspaceId);
  Future<ResourceModel?> getById(String id);
  Future<List<ResourceModel>> getByIds(List<String> ids);
  Future<void> insert(ResourceModel resource);
  Future<void> update(ResourceModel resource);
}
