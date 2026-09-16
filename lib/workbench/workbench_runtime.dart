import 'application/ai_context_builder.dart';
import 'application/ai_context_budget.dart';
import 'application/ai_context_preview_service.dart';
import 'application/ai_conversation_service.dart';
import 'application/ai_prompt_builder.dart';
import 'application/continue_service.dart';
import 'application/decision_service.dart';
import 'application/developer_command_service.dart';
import 'application/developer_context_service.dart';
import 'application/developer_project_service.dart';
import 'application/developer_snippet_service.dart';
import 'application/focus_session_service.dart';
import 'application/issue_service.dart';
import 'application/knowledge_distill_service.dart';
import 'application/knowledge_service.dart';
import 'application/openai_compatible_ai_provider.dart';
import 'application/phase2_overview_service.dart';
import 'application/preview_ai_provider.dart';
import 'application/quick_capture_service.dart';
import 'application/resource_service.dart';
import 'application/search_service.dart';
import 'application/task_context_service.dart';
import 'application/today_service.dart';
import 'application/workbench_services.dart';
import 'application/workbench_settings_service.dart';
import 'application/workspace_admin_service.dart';
import 'core/ai_provider_config.dart';
import 'core/app_paths.dart';
import 'core/workbench_database.dart';
import 'data/markdown_store.dart';
import 'data/sqlite_ai_conversation_repository.dart';
import 'data/sqlite_decision_repository.dart';
import 'data/sqlite_developer_command_repository.dart';
import 'data/sqlite_developer_project_repository.dart';
import 'data/sqlite_developer_snippet_repository.dart';
import 'data/sqlite_focus_session_repository.dart';
import 'data/sqlite_issue_repository.dart';
import 'data/sqlite_knowledge_repository.dart';
import 'data/sqlite_repositories.dart';
import 'data/sqlite_resource_repository.dart';
import 'data/sqlite_search_index_repository.dart';
import 'domain/ai_provider.dart';

class WorkbenchRuntime {
  WorkbenchRuntime._({
    required this.paths,
    required this.database,
    required this.settingsService,
    required this.workspaceService,
    required this.workspaceAdminService,
    required this.taskService,
    required this.noteService,
    required this.issueService,
    required this.resourceService,
    required this.decisionService,
    required this.knowledgeService,
    required this.knowledgeDistillService,
    required this.searchService,
    required this.taskContextService,
    required this.aiContextBuilder,
    required this.aiContextBudget,
    required this.aiContextPreviewService,
    required this.aiPromptBuilder,
    required this.aiConversationService,
    required this.aiProvider,
    required this.continueService,
    required this.quickCaptureService,
    required this.focusSessionService,
    required this.todayService,
    required this.entityLinkService,
    required this.overviewService,
    required this.developerProjectService,
    required this.developerCommandService,
    required this.developerSnippetService,
    required this.developerContextService,
  });

  final AppPaths paths;
  final WorkbenchDatabase database;
  final WorkbenchSettingsService settingsService;
  final WorkspaceService workspaceService;
  final WorkspaceAdminService workspaceAdminService;
  final TaskService taskService;
  final NoteService noteService;
  final IssueService issueService;
  final ResourceService resourceService;
  final DecisionService decisionService;
  final KnowledgeService knowledgeService;
  final KnowledgeDistillService knowledgeDistillService;
  final SearchService searchService;
  final TaskContextService taskContextService;
  final AIContextBuilder aiContextBuilder;
  final AIContextBudget aiContextBudget;
  final AIContextPreviewService aiContextPreviewService;
  final AIPromptBuilder aiPromptBuilder;
  final AIConversationService aiConversationService;
  final AIProvider aiProvider;
  final ContinueService continueService;
  final QuickCaptureService quickCaptureService;
  final FocusSessionService focusSessionService;
  final TodayService todayService;
  final EntityLinkService entityLinkService;
  final Phase2WorkspaceOverviewService overviewService;
  final DeveloperProjectService developerProjectService;
  final DeveloperCommandService developerCommandService;
  final DeveloperSnippetService developerSnippetService;
  final DeveloperContextService developerContextService;

  static Future<WorkbenchRuntime>? _instance;

  static Future<WorkbenchRuntime> get instance => _instance ??= _create();

  static Future<WorkbenchRuntime> _create() async {
    final paths = await AppPaths.create();
    final database = await WorkbenchDatabase.open(paths.databasePath);
    final settingsService = await WorkbenchSettingsService.create();
    final workspaceRepository = SqliteWorkspaceRepository(database);
    final taskRepository = SqliteTaskRepository(database);
    final noteRepository = SqliteNoteRepository(database);
    final issueRepository = SqliteIssueRepository(database);
    final resourceRepository = SqliteResourceRepository(database);
    final decisionRepository = SqliteDecisionRepository(database);
    final knowledgeRepository = SqliteKnowledgeRepository(database);
    final focusSessionRepository = SqliteFocusSessionRepository(database);
    final entityLinkRepository = SqliteEntityLinkRepository(database);
    final activityRepository = SqliteActivityRepository(database);
    final searchIndexRepository = SqliteSearchIndexRepository(database);
    final aiThreadRepository = SqliteAIThreadRepository(database);
    final aiMessageRepository = SqliteAIMessageRepository(database);
    final developerProjectRepository = SqliteDeveloperProjectRepository(database);
    final developerCommandRepository = SqliteDeveloperCommandRepository(database);
    final developerSnippetRepository = SqliteDeveloperSnippetRepository(database);
    final markdownStore = MarkdownStore(paths);

    final entityLinkService = EntityLinkService(entityLinkRepository);
    final workspaceService = WorkspaceService(
      paths: paths,
      workspaces: workspaceRepository,
      activities: activityRepository,
    );
    final taskService = TaskService(
      tasks: taskRepository,
      activities: activityRepository,
    );
    final noteService = NoteService(
      paths: paths,
      store: markdownStore,
      workspaces: workspaceRepository,
      tasks: taskRepository,
      notes: noteRepository,
      links: entityLinkService,
      activities: activityRepository,
    );
    final knowledgeService = KnowledgeService(
      paths: paths,
      store: markdownStore,
      knowledge: knowledgeRepository,
      links: entityLinkRepository,
      searchIndex: searchIndexRepository,
    );
    final knowledgeDistillService = KnowledgeDistillService(
      workspaces: workspaceRepository,
      tasks: taskRepository,
      notes: noteRepository,
      issues: issueRepository,
      resources: resourceRepository,
      decisions: decisionRepository,
      store: markdownStore,
      knowledge: knowledgeService,
    );
    final searchService = SearchService(
      workspaces: workspaceRepository,
      tasks: taskRepository,
      notes: noteRepository,
      issues: issueRepository,
      resources: resourceRepository,
      decisions: decisionRepository,
      knowledge: knowledgeRepository,
      developerProjects: developerProjectRepository,
      developerCommands: developerCommandRepository,
      developerSnippets: developerSnippetRepository,
      markdownStore: markdownStore,
      index: searchIndexRepository,
    );
    final taskContextService = TaskContextService(
      notes: noteRepository,
      issues: issueRepository,
      resources: resourceRepository,
      decisions: decisionRepository,
      knowledge: knowledgeRepository,
      links: entityLinkRepository,
      activities: activityRepository,
    );
    final developerProjectService = DeveloperProjectService(
      projects: developerProjectRepository,
      activities: activityRepository,
    );
    final developerCommandService = DeveloperCommandService(
      commands: developerCommandRepository,
      projects: developerProjectRepository,
      activities: activityRepository,
    );
    final developerSnippetService = DeveloperSnippetService(
      snippets: developerSnippetRepository,
      projects: developerProjectRepository,
      activities: activityRepository,
    );
    final developerContextService = DeveloperContextService(
      projects: developerProjectRepository,
      commands: developerCommandRepository,
      snippets: developerSnippetRepository,
      resources: resourceRepository,
    );
    final aiContextBuilder = AIContextBuilder(
      workspaces: workspaceRepository,
      tasks: taskRepository,
      notes: noteRepository,
      issues: issueRepository,
      resources: resourceRepository,
      decisions: decisionRepository,
      knowledge: knowledgeRepository,
      activities: activityRepository,
      markdownStore: markdownStore,
      taskContextService: taskContextService,
      knowledgeService: knowledgeService,
      searchService: searchService,
      developerContextService: developerContextService,
    );
    const aiContextBudget = AIContextBudget();
    final aiContextPreviewService = AIContextPreviewService(
      builder: aiContextBuilder,
      budget: aiContextBudget,
    );
    const aiPromptBuilder = AIPromptBuilder();
    final aiConversationService = AIConversationService(
      threads: aiThreadRepository,
      messages: aiMessageRepository,
      workspaces: workspaceRepository,
      tasks: taskRepository,
      knowledge: knowledgeRepository,
    );
    final aiProviderConfig = AIProviderConfig.fromEnvironment();
    final AIProvider aiProvider = aiProviderConfig.isConfigured
        ? OpenAICompatibleAIProvider(config: aiProviderConfig)
        : const PreviewAIProvider();
    final continueService = ContinueService(
      workspaces: workspaceRepository,
      tasks: taskRepository,
      taskContextService: taskContextService,
    );
    final quickCaptureService = QuickCaptureService(
      workspaces: workspaceService,
      tasks: taskService,
      notes: noteService,
      settings: settingsService,
    );
    final focusSessionService = FocusSessionService(
      sessions: focusSessionRepository,
      workspaces: workspaceRepository,
      tasks: taskRepository,
      activities: activityRepository,
    );
    final todayService = TodayService(focusSessions: focusSessionService);

    return WorkbenchRuntime._(
      paths: paths,
      database: database,
      settingsService: settingsService,
      workspaceService: workspaceService,
      workspaceAdminService: WorkspaceAdminService(
        workspaces: workspaceRepository,
        activities: activityRepository,
      ),
      taskService: taskService,
      noteService: noteService,
      issueService: IssueService(
        issues: issueRepository,
        tasks: taskRepository,
        links: entityLinkRepository,
        activities: activityRepository,
      ),
      resourceService: ResourceService(
        resources: resourceRepository,
        tasks: taskRepository,
        links: entityLinkRepository,
        activities: activityRepository,
      ),
      decisionService: DecisionService(
        decisions: decisionRepository,
        tasks: taskRepository,
        links: entityLinkRepository,
        activities: activityRepository,
      ),
      knowledgeService: knowledgeService,
      knowledgeDistillService: knowledgeDistillService,
      searchService: searchService,
      taskContextService: taskContextService,
      aiContextBuilder: aiContextBuilder,
      aiContextBudget: aiContextBudget,
      aiContextPreviewService: aiContextPreviewService,
      aiPromptBuilder: aiPromptBuilder,
      aiConversationService: aiConversationService,
      aiProvider: aiProvider,
      continueService: continueService,
      quickCaptureService: quickCaptureService,
      focusSessionService: focusSessionService,
      todayService: todayService,
      entityLinkService: entityLinkService,
      overviewService: Phase2WorkspaceOverviewService(
        workspaces: workspaceRepository,
        tasks: taskRepository,
        taskContextService: taskContextService,
        activities: activityRepository,
      ),
      developerProjectService: developerProjectService,
      developerCommandService: developerCommandService,
      developerSnippetService: developerSnippetService,
      developerContextService: developerContextService,
    );
  }
}
