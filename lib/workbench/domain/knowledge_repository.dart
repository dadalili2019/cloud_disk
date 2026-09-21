import '../core/models.dart';

abstract interface class KnowledgeRepository {
  Future<List<KnowledgeModel>> listActive({String? category});
  Future<KnowledgeModel?> getById(String id);
  Future<List<KnowledgeModel>> getByIds(List<String> ids);
  Future<void> insert(KnowledgeModel knowledge);
  Future<void> update(KnowledgeModel knowledge);
  Future<void> delete(String id);
}
