import 'models.dart';

class DeveloperProjectModel {
  const DeveloperProjectModel({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.localPath,
    required this.repositoryUrl,
    required this.branch,
    required this.techStack,
    required this.notes,
    required this.isPrimary,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  final String id;
  final String workspaceId;
  final String name;
  final String localPath;
  final String repositoryUrl;
  final String branch;
  final String techStack;
  final String notes;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
}

class DeveloperCommandModel {
  const DeveloperCommandModel({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.command,
    required this.category,
    required this.notes,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
    this.projectId,
    this.workingDirectory,
    this.archivedAt,
  });

  final String id;
  final String workspaceId;
  final String? projectId;
  final String name;
  final String command;
  final String? workingDirectory;
  final String category;
  final String notes;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
}

class DeveloperSnippetModel {
  const DeveloperSnippetModel({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.language,
    required this.content,
    required this.notes,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
    this.projectId,
    this.archivedAt,
  });

  final String id;
  final String workspaceId;
  final String? projectId;
  final String title;
  final String language;
  final String content;
  final String notes;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
}

class DeveloperContextModel {
  const DeveloperContextModel({
    required this.workspaceId,
    this.projects = const [],
    this.primaryProject,
    this.commands = const [],
    this.snippets = const [],
    this.devResources = const [],
  });

  final String workspaceId;
  final List<DeveloperProjectModel> projects;
  final DeveloperProjectModel? primaryProject;
  final List<DeveloperCommandModel> commands;
  final List<DeveloperSnippetModel> snippets;
  final List<ResourceModel> devResources;
}
