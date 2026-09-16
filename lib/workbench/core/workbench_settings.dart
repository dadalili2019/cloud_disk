enum WorkbenchStartupPage {
  home,
  workspace,
  knowledge,
}

enum NoteDefaultView {
  edit,
  preview,
  split,
}

enum AIProviderMode {
  environment,
  preview,
  deepseek,
  openAICompatible,
}

enum BackupFrequency {
  off,
  daily,
  weekly,
}

class GeneralSettings {
  const GeneralSettings({
    this.defaultWorkspaceId,
    this.startupPage = WorkbenchStartupPage.home,
    this.quickCaptureToCurrentTask = true,
    this.restoreLastActiveContext = true,
  });

  final String? defaultWorkspaceId;
  final WorkbenchStartupPage startupPage;
  final bool quickCaptureToCurrentTask;
  final bool restoreLastActiveContext;

  GeneralSettings copyWith({
    String? defaultWorkspaceId,
    bool clearDefaultWorkspace = false,
    WorkbenchStartupPage? startupPage,
    bool? quickCaptureToCurrentTask,
    bool? restoreLastActiveContext,
  }) {
    return GeneralSettings(
      defaultWorkspaceId: clearDefaultWorkspace
          ? null
          : (defaultWorkspaceId ?? this.defaultWorkspaceId),
      startupPage: startupPage ?? this.startupPage,
      quickCaptureToCurrentTask:
          quickCaptureToCurrentTask ?? this.quickCaptureToCurrentTask,
      restoreLastActiveContext:
          restoreLastActiveContext ?? this.restoreLastActiveContext,
    );
  }
}

class NotesSettings {
  const NotesSettings({
    this.defaultView = NoteDefaultView.edit,
    this.autoSave = true,
  });

  final NoteDefaultView defaultView;
  final bool autoSave;

  NotesSettings copyWith({
    NoteDefaultView? defaultView,
    bool? autoSave,
  }) {
    return NotesSettings(
      defaultView: defaultView ?? this.defaultView,
      autoSave: autoSave ?? this.autoSave,
    );
  }
}

class AISettings {
  const AISettings({
    this.mode = AIProviderMode.environment,
    this.baseUrl = '',
    this.model = '',
    this.chatPath = '',
    this.timeoutSeconds = 90,
  });

  final AIProviderMode mode;
  final String baseUrl;
  final String model;
  final String chatPath;
  final int timeoutSeconds;

  bool get usesCustomConfiguration =>
      mode == AIProviderMode.deepseek ||
      mode == AIProviderMode.openAICompatible;

  AISettings copyWith({
    AIProviderMode? mode,
    String? baseUrl,
    String? model,
    String? chatPath,
    int? timeoutSeconds,
  }) {
    return AISettings(
      mode: mode ?? this.mode,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      chatPath: chatPath ?? this.chatPath,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    );
  }
}

class BackupSettings {
  const BackupSettings({
    this.frequency = BackupFrequency.off,
    this.keepAutoBackups = 10,
    this.includeAttachmentsInExport = true,
    this.lastAutoBackupAt,
  });

  final BackupFrequency frequency;
  final int keepAutoBackups;
  final bool includeAttachmentsInExport;
  final DateTime? lastAutoBackupAt;

  bool shouldRunAutoBackup(DateTime now) {
    if (frequency == BackupFrequency.off) return false;
    final last = lastAutoBackupAt;
    if (last == null) return true;
    final elapsed = now.difference(last);
    return switch (frequency) {
      BackupFrequency.off => false,
      BackupFrequency.daily => elapsed >= const Duration(hours: 24),
      BackupFrequency.weekly => elapsed >= const Duration(days: 7),
    };
  }

  BackupSettings copyWith({
    BackupFrequency? frequency,
    int? keepAutoBackups,
    bool? includeAttachmentsInExport,
    DateTime? lastAutoBackupAt,
    bool clearLastAutoBackupAt = false,
  }) {
    return BackupSettings(
      frequency: frequency ?? this.frequency,
      keepAutoBackups: keepAutoBackups ?? this.keepAutoBackups,
      includeAttachmentsInExport:
          includeAttachmentsInExport ?? this.includeAttachmentsInExport,
      lastAutoBackupAt: clearLastAutoBackupAt
          ? null
          : (lastAutoBackupAt ?? this.lastAutoBackupAt),
    );
  }
}

class WorkbenchSettingsModel {
  const WorkbenchSettingsModel({
    this.general = const GeneralSettings(),
    this.notes = const NotesSettings(),
    this.ai = const AISettings(),
    this.backup = const BackupSettings(),
  });

  final GeneralSettings general;
  final NotesSettings notes;
  final AISettings ai;
  final BackupSettings backup;

  WorkbenchSettingsModel copyWith({
    GeneralSettings? general,
    NotesSettings? notes,
    AISettings? ai,
    BackupSettings? backup,
  }) {
    return WorkbenchSettingsModel(
      general: general ?? this.general,
      notes: notes ?? this.notes,
      ai: ai ?? this.ai,
      backup: backup ?? this.backup,
    );
  }
}
