import 'application/ai_context_builder.dart';
import 'application/ai_context_budget.dart';
import 'application/ai_context_preview_service.dart';
import 'application/continue_service.dart';
import 'application/decision_service.dart';
import 'application/focus_session_service.dart';
import 'application/issue_service.dart';
import 'application/knowledge_distill_service.dart';
import 'application/knowledge_service.dart';
import 'application/phase2_overview_service.dart';
import 'application/quick_capture_service.dart';
import 'application/resource_service.dart';
import 'application/search_service.dart';
import 'application/task_context_service.dart';
import 'application/today_service.dart';
import 'application/workbench_services.dart';
import 'application/workspace_admin_service.dart';
import 'core/app_paths.dart';
import 'core/workbench_database.dart';
import 'data/markdown_store.dart';
import 'data/sqlite_decision_repository.dart';
import 'data/sqlite_focus_session_repository.dart';
import 'data/sqlite_issue_repository.dart';
import 'data/sqlite_knowledge_repository.dart';
import 'data/sqlite_repositories.dart';
import 'data/sqlite_resource_repository.dart';
import 'data/sqlite_search_index_repository.dart';

class WorkbenchRuntime {
  WorkbenchRuntime._({
    required this.paths,
    required this.database,
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
    required this.continueService,
    required this.quickCaptureService,
    required this.focusSessionService,
    required this.todayService,
    required this.entityLinkService,
    required this.overviewService,
  });

  final AppPaths paths;
  final WorkbenchDatabase database;
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
  final ContinueService continueService;
  final QuickCaptureService quickCaptureService;
  final FocusSessionService focusSessionService;
  final TodayService todayService;
  final EntityLinkService entityLinkService;
  final Phase2WorkspaceOverviewService overviewService;

  static Future<WorkbenchRuntime>? _instance;

  static Future<WorkbenchRuntime> get instance => _instance ??= _create();

  static Future<WorkbenchRuntime> _create() async {
    final paths = await AppPaths.create();
    final database = await WorkbenchDatabase.open(paths.databasePath);
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
    );
    const aiContextBudget = AIContextBudget();
    final aiContextPreviewService = AIContextPreviewService(
      builder: aiContextBuilder,
      budget: aiContextBudget,
    );
    final continueService = ContinueService(
      workspaces: workspaceRepository,
      tasks: taskRepository,
      taskContextService: taskContextService,
    );
    final quickCaptureService = QuickCaptureService(
      workspaces: workspaceService,
      tasks: taskService,
      notes: noteService,
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
    );
  }
}
