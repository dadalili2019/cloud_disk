import '../core/ai_context_models.dart';
import '../core/developer_models.dart';
import '../core/models.dart';
import '../data/markdown_store.dart';
import '../domain/decision_repository.dart';
import '../domain/issue_repository.dart';
import '../domain/knowledge_repository.dart';
import '../domain/repositories.dart';
import '../domain/resource_repository.dart';
import 'developer_context_service.dart';
import 'knowledge_service.dart';
import 'search_service.dart';
import 'task_context_service.dart';


part 'ai_context_builder_scopes.dart';
part 'ai_context_builder_collection.dart';
part 'ai_context_builder_entities.dart';
part 'ai_context_builder_formatters.dart';

class AIContextBuilder {
  const AIContextBuilder({
    required this.workspaces,
    required this.tasks,
    required this.notes,
    required this.issues,
    required this.resources,
    required this.decisions,
    required this.knowledge,
    required this.activities,
    required this.markdownStore,
    required this.taskContextService,
    required this.knowledgeService,
    required this.searchService,
    required this.developerContextService,
  });

  final WorkspaceRepository workspaces;
  final TaskRepository tasks;
  final NoteRepository notes;
  final IssueRepository issues;
  final ResourceRepository resources;
  final DecisionRepository decisions;
  final KnowledgeRepository knowledge;
  final ActivityRepository activities;
  final MarkdownStore markdownStore;
  final TaskContextService taskContextService;
  final KnowledgeService knowledgeService;
  final SearchService searchService;
  final DeveloperContextService developerContextService;

  Future<AIContextModel> build(AIContextRequest request) async {
    return switch (request.scope) {
      AIContextScope.task => _buildTask(request),
      AIContextScope.workspace => _buildWorkspace(request),
      AIContextScope.knowledge => _buildKnowledge(request),
      AIContextScope.global => _buildGlobal(request),
    };
  }

}
