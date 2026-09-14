import 'application/issue_service.dart';
import 'application/workbench_services.dart';
import 'core/app_paths.dart';
import 'core/workbench_database.dart';
import 'data/markdown_store.dart';
import 'data/sqlite_issue_repository.dart';
import 'data/sqlite_repositories.dart';

class WorkbenchRuntime {
  WorkbenchRuntime._({
    required this.paths,
    required this.database,
    required this.workspaceService,
    required this.taskService,
    required this.noteService,
    required this.issueService,
    required this.entityLinkService,
    required this.overviewService,
  });

  final AppPaths paths;
  final WorkbenchDatabase database;
  final WorkspaceService workspaceService;
  final TaskService taskService;
  final NoteService noteService;
  final IssueService issueService;
  final EntityLinkService entityLinkService;
  final WorkspaceOverviewService overviewService;

  static Future<WorkbenchRuntime>? _instance;

  static Future<WorkbenchRuntime> get instance {
    return _instance ??= _create();
  }

  static Future<WorkbenchRuntime> _create() async {
    final paths = await AppPaths.create();
    final database = await WorkbenchDatabase.open(paths.databasePath);

    final workspaceRepository = SqliteWorkspaceRepository(database);
    final taskRepository = SqliteTaskRepository(database);
    final noteRepository = SqliteNoteRepository(database);
    final issueRepository = SqliteIssueRepository(database);
    final entityLinkRepository = SqliteEntityLinkRepository(database);
    final activityRepository = SqliteActivityRepository(database);
    final markdownStore = MarkdownStore(paths);
    final entityLinkService = EntityLinkService(entityLinkRepository);

    return WorkbenchRuntime._(
      paths: paths,
      database: database,
      workspaceService: WorkspaceService(
        paths: paths,
        workspaces: workspaceRepository,
        activities: activityRepository,
      ),
      taskService: TaskService(
        tasks: taskRepository,
        activities: activityRepository,
      ),
      noteService: NoteService(
        paths: paths,
        store: markdownStore,
        workspaces: workspaceRepository,
        tasks: taskRepository,
        notes: noteRepository,
        links: entityLinkService,
        activities: activityRepository,
      ),
      issueService: IssueService(
        issues: issueRepository,
        tasks: taskRepository,
        links: entityLinkRepository,
        activities: activityRepository,
      ),
      entityLinkService: entityLinkService,
      overviewService: WorkspaceOverviewService(
        workspaces: workspaceRepository,
        tasks: taskRepository,
        notes: noteRepository,
        links: entityLinkService,
        activities: activityRepository,
      ),
    );
  }
}
