import 'models.dart';

enum AIContextScope {
  task,
  workspace,
  knowledge,
  global;

  static AIContextScope fromValue(String value) {
    return AIContextScope.values.firstWhere(
      (scope) => scope.name == value,
      orElse: () => throw ArgumentError.value(value, 'value', 'Unsupported AI scope.'),
    );
  }
}

class AIContextRef {
  const AIContextRef({
    required this.entityType,
    required this.entityId,
    required this.title,
    this.workspaceId,
  });

  final String entityType;
  final String entityId;
  final String title;
  final String? workspaceId;

  String get key => '$entityType:$entityId';

  Map<String, Object?> toJson() => {
        'type': entityType,
        'id': entityId,
        'title': title,
        if (workspaceId != null) 'workspace_id': workspaceId,
      };
}

class AIContextRequest {
  const AIContextRequest({
    required this.scope,
    this.query = '',
    this.workspaceId,
    this.taskId,
    this.knowledgeId,
    this.manuallyIncludedEntities = const [],
    this.manuallyExcludedEntities = const [],
  });

  final AIContextScope scope;

  /// Usually the user's current message. Global/workspace scope can use this
  /// to retrieve a small amount of relevant context through SearchService.
  final String query;
  final String? workspaceId;
  final String? taskId;
  final String? knowledgeId;
  final List<AIContextRef> manuallyIncludedEntities;
  final List<AIContextRef> manuallyExcludedEntities;
}

class AIContextItem {
  const AIContextItem({
    required this.ref,
    required this.priority,
    required this.reason,
    required this.content,
  });

  final AIContextRef ref;

  /// Lower number means more important. The fixed Phase 5 order is P0-P4.
  final int priority;
  final String reason;
  final String content;

  int get characterCount => content.length;
}

class AIContextModel {
  const AIContextModel({
    required this.scope,
    required this.generatedAt,
    required this.items,
    required this.excludedRefs,
    this.anchor,
    this.workspace,
  });

  final AIContextScope scope;
  final DateTime generatedAt;
  final AIContextRef? anchor;
  final WorkspaceModel? workspace;
  final List<AIContextItem> items;
  final List<AIContextRef> excludedRefs;

  int get totalCharacters =>
      items.fold(0, (total, item) => total + item.characterCount);

  List<AIContextRef> get includedRefs =>
      items.map((item) => item.ref).toList(growable: false);

  Map<String, Object?> referenceSnapshot() => {
        'scope': scope.name,
        if (workspace != null) 'workspace_id': workspace!.id,
        if (anchor != null) 'anchor': anchor!.toJson(),
        'entities': includedRefs.map((ref) => ref.toJson()).toList(),
      };
}

class AIContextPreviewItem {
  const AIContextPreviewItem({
    required this.ref,
    required this.priority,
    required this.reason,
    required this.characterCount,
    required this.preview,
  });

  final AIContextRef ref;
  final int priority;
  final String reason;
  final int characterCount;
  final String preview;
}

class AIContextPreviewModel {
  const AIContextPreviewModel({
    required this.scope,
    required this.included,
    required this.excluded,
    required this.totalCharacters,
    this.anchor,
    this.workspace,
  });

  final AIContextScope scope;
  final AIContextRef? anchor;
  final WorkspaceModel? workspace;
  final List<AIContextPreviewItem> included;
  final List<AIContextRef> excluded;
  final int totalCharacters;
}
