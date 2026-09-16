import '../core/developer_models.dart';
import '../domain/developer_command_repository.dart';
import '../domain/developer_project_repository.dart';
import '../domain/developer_snippet_repository.dart';
import '../domain/resource_repository.dart';

class DeveloperContextService {
  const DeveloperContextService({
    required this.projects,
    required this.commands,
    required this.snippets,
    required this.resources,
  });

  final DeveloperProjectRepository projects;
  final DeveloperCommandRepository commands;
  final DeveloperSnippetRepository snippets;
  final ResourceRepository resources;

  static const _developerResourceTypes = {
    'repository',
    'local_path',
    'document',
    'service',
    'link',
    'design',
    'command',
  };

  Future<DeveloperContextModel> load(String workspaceId) async {
    final projectList = await projects.listByWorkspace(workspaceId);
    final commandList = await commands.listByWorkspace(workspaceId);
    final snippetList = await snippets.listByWorkspace(workspaceId);
    final allResources = await resources.listByWorkspace(workspaceId);

    DeveloperProjectModel? primary;
    for (final project in projectList) {
      if (project.isPrimary) {
        primary = project;
        break;
      }
    }

    final devResources = allResources
        .where((resource) => _developerResourceTypes.contains(resource.resourceType))
        .toList(growable: false);

    return DeveloperContextModel(
      workspaceId: workspaceId,
      projects: projectList,
      primaryProject: primary,
      commands: commandList,
      snippets: snippetList,
      devResources: devResources,
    );
  }
}
