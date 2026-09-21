part of 'workbench_runtime.dart';

  Future<WorkbenchRuntime> _createWorkbenchRuntime() async {
  final paths = await AppPaths.create();
  final restored = await RestoreService.applyPendingRestoreIfPresent(paths);
  final database = await WorkbenchDatabase.open(paths.databasePath);
  final settingsService = await WorkbenchSettingsService.create();
  final backupService = BackupService(paths: paths, database: database);
  final exportService = ExportService(paths: paths, database: database);
  final restoreService = RestoreService(
    paths: paths,
    backupService: backupService,
  );
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
  final environmentAIConfig = AIProviderConfig.fromEnvironment();
  final AIProvider aiProvider = ConfigurableAIProvider(
    settings: settingsService,
    environmentConfig: environmentAIConfig,
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
    issues: IssueService(
      issues: issueRepository,
      tasks: taskRepository,
      links: entityLinkRepository,
      activities: activityRepository,
    ),
    settings: settingsService,
  );
  final focusSessionService = FocusSessionService(
    sessions: focusSessionRepository,
    workspaces: workspaceRepository,
    tasks: taskRepository,
    activities: activityRepository,
  );
  final todayService = TodayService(focusSessions: focusSessionService);

  if (restored) {
    await searchService.rebuildIndex();
}

  final runtime = WorkbenchRuntime._(
    paths: paths,
    database: database,
    settingsService: settingsService,
    backupService: backupService,
    exportService: exportService,
    restoreService: restoreService,
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
    overviewService: WorkspaceOverviewService(
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

  unawaited(_runAutoBackup(runtime));
  return runtime;
}
