import '../core/ai_conversation_models.dart';

abstract interface class AIThreadRepository {
  Future<List<AIThreadModel>> listActive({int limit = 50});
  Future<AIThreadModel?> getById(String id);
  Future<List<AIThreadModel>> listByAnchor({
    String? workspaceId,
    String? taskId,
    String? knowledgeId,
    int limit = 50,
  });
  Future<void> insert(AIThreadModel thread);
  Future<void> update(AIThreadModel thread);
}

abstract interface class AIMessageRepository {
  Future<List<AIMessageModel>> listByThread(String threadId);
  Future<void> insert(AIMessageModel message);
}
