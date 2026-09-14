import 'ai_context_models.dart';

class AIThreadModel {
  const AIThreadModel({
    required this.id,
    required this.scope,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.workspaceId,
    this.taskId,
    this.knowledgeId,
    this.archivedAt,
  });

  final String id;
  final AIContextScope scope;
  final String title;
  final String? workspaceId;
  final String? taskId;
  final String? knowledgeId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
}

class AIMessageModel {
  const AIMessageModel({
    required this.id,
    required this.threadId,
    required this.role,
    required this.content,
    required this.contextSnapshotJson,
    required this.createdAt,
  });

  final String id;
  final String threadId;
  final String role;
  final String content;

  /// Reference snapshot only. Full Note / Knowledge bodies are not duplicated.
  final String contextSnapshotJson;
  final DateTime createdAt;
}
