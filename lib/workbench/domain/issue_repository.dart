import '../core/models.dart';

abstract interface class IssueRepository {
  Future<List<IssueModel>> listByWorkspace(String workspaceId);
  Future<IssueModel?> getById(String id);
  Future<List<IssueModel>> getByIds(List<String> ids);
  Future<void> insert(IssueModel issue);
  Future<void> update(IssueModel issue);
}
