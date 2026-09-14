class WorkspaceModel {
  const WorkspaceModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  final String id;
  final String name;
  final String slug;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
}

class TaskModel {
  const TaskModel({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.description,
    required this.status,
    required this.progress,
    required this.nextStep,
    required this.priority,
    required this.isCurrent,
    required this.createdAt,
    required this.updatedAt,
    this.dueAt,
    this.archivedAt,
  });

  final String id;
  final String workspaceId;
  final String title;
  final String description;
  final String status;
  final int progress;
  final String nextStep;
  final int priority;
  final bool isCurrent;
  final DateTime? dueAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
}

class NoteModel {
  const NoteModel({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.filePath,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  final String id;
  final String workspaceId;
  final String title;
  final String filePath;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
}

class IssueModel {
  const IssueModel({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.status,
    required this.severity,
    required this.impact,
    required this.hypothesis,
    required this.nextInvestigationStep,
    required this.resolution,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  final String id;
  final String workspaceId;
  final String title;
  final String status;
  final String severity;
  final String impact;
  final String hypothesis;
  final String nextInvestigationStep;
  final String resolution;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  bool get isOpen => status != 'resolved' && status != 'archived';
}

class ResourceModel {
  const ResourceModel({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.resourceType,
    required this.uri,
    required this.description,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  final String id;
  final String workspaceId;
  final String name;
  final String resourceType;
  final String uri;
  final String description;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
}

class DecisionModel {
  const DecisionModel({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.decisionText,
    required this.rationale,
    required this.revisitCondition,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  final String id;
  final String workspaceId;
  final String title;
  final String decisionText;
  final String rationale;
  final String revisitCondition;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
}

class ActivityEventModel {
  const ActivityEventModel({
    required this.id,
    required this.workspaceId,
    required this.eventType,
    required this.summary,
    required this.createdAt,
    this.entityType,
    this.entityId,
  });

  final String id;
  final String workspaceId;
  final String? entityType;
  final String? entityId;
  final String eventType;
  final String summary;
  final DateTime createdAt;
}

class WorkspaceOverviewModel {
  const WorkspaceOverviewModel({
    required this.workspace,
    required this.currentTask,
    required this.linkedNotes,
    required this.currentBlockers,
    required this.recentActivity,
  });

  final WorkspaceModel workspace;
  final TaskModel? currentTask;
  final List<NoteModel> linkedNotes;
  final List<IssueModel> currentBlockers;
  final List<ActivityEventModel> recentActivity;

  String get nextStep => currentTask?.nextStep ?? '';
}
