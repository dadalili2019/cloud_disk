import 'dart:async';

import 'application/ai_context_builder.dart';
import 'application/ai_context_budget.dart';
import 'application/ai_context_preview_service.dart';
import 'application/ai_conversation_service.dart';
import 'application/ai_prompt_builder.dart';
import 'application/backup_service.dart';
import 'application/configurable_ai_provider.dart';
import 'application/continue_service.dart';
import 'application/decision_service.dart';
import 'application/developer_command_service.dart';
import 'application/developer_context_service.dart';
import 'application/developer_project_service.dart';
import 'application/developer_snippet_service.dart';
import 'application/export_service.dart';
import 'application/focus_session_service.dart';
import 'application/issue_service.dart';
import 'application/knowledge_distill_service.dart';
import 'application/knowledge_service.dart';
import 'application/workspace_overview_service.dart';
import 'application/quick_capture_service.dart';
import 'application/resource_service.dart';
import 'application/restore_service.dart';
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

part 'workbench_runtime_composition.dart';

class WorkbenchRuntime {
  WorkbenchRuntime._({
    required this.paths,
    required this.database,
    required this.settingsService,
    required this.backupService,
    required this.exportService,
    required this.restoreService,
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
  final BackupService backupService;
  final ExportService exportService;
  final RestoreService restoreService;
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
  final WorkspaceOverviewService overviewService;
  final DeveloperProjectService developerProjectService;
  final DeveloperCommandService developerCommandService;
  final DeveloperSnippetService developerSnippetService;
  final DeveloperContextService developerContextService;

  static Future<WorkbenchRuntime>? _instance;

  static Future<WorkbenchRuntime  static Future<WorkbenchRuntime> _create() => _createWorkbenchRuntime();
utoBackup(runtime));
    return runtime;
  }
}

Future<void> _runAutoBackup(WorkbenchRuntime runtime) async {
  final settings = runtime.settingsService.current.backup;
  if (!settings.shouldRunAutoBackup(DateTime.now())) return;
  try {
    await runtime.backupService.createAutoBackup();
    await runtime.backupService.pruneAutoBackups(keep: settings.keepAutoBackups);
    await runtime.settingsService.markAutoBackupCompleted(DateTime.now());
  } catch (_) {
    // Auto backup must never prevent Workbench startup. A manual backup still
    // surfaces the actual error in Settings > Data & Backup.
  }
}
