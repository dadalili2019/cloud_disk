import 'application/continue_service.dart';
import 'application/decision_service.dart';
import 'application/issue_service.dart';
import 'application/phase2_overview_service.dart';
import 'application/quick_capture_service.dart';
import 'application/resource_service.dart';
import 'application/task_context_service.dart';
import 'application/workbench_services.dart';
import 'application/workspace_admin_service.dart';
import 'core/app_paths.dart';
import 'core/workbench_database.dart';
import 'data/markdown_store.dart';
import 'data/sqlite_decision_repository.dart';
import 'data/sqlite_issue_repository.dart';
import 'data/sqlite_repositories.dart';
import 'data/sqlite_resource_repository.dart';

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
    required this.taskContextService,
    required this.continueService,
    required this.quickCaptureService,
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
  final TaskContextService taskContextService;
  final ContinueService continueService;
  final QuickCaptureService quickCaptureService;
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
    final entityLinkRepository = SqliteEntityLinkRepository(database);
    final activityRepository = SqliteActivityRepository(database);
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
    final taskContextService = TaskContextService(
      notes: noteRepository,
      issues: issueRepository,
      resources: resourceRepository,
      decisions: decisionRepository,
      links: entityLinkRepository,
      activities: activityRepository,
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
      taskContextService: taskContextService,
      continueService: continueService,
      quickCaptureService: quickCaptureService,
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
