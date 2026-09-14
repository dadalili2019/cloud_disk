import '../core/models.dart';

abstract interface class DecisionRepository {
  Future<List<DecisionModel>> listByWorkspace(String workspaceId);
  Future<DecisionModel?> getById(String id);
  Future<List<DecisionModel>> getByIds(List<String> ids);
  Future<void> insert(DecisionModel decision);
  Future<void> update(DecisionModel decision);
}
