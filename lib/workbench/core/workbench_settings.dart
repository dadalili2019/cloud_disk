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

class WorkbenchSettingsModel {
  const WorkbenchSettingsModel({
    this.general = const GeneralSettings(),
    this.notes = const NotesSettings(),
  });

  final GeneralSettings general;
  final NotesSettings notes;

  WorkbenchSettingsModel copyWith({
    GeneralSettings? general,
    NotesSettings? notes,
  }) {
    return WorkbenchSettingsModel(
      general: general ?? this.general,
      notes: notes ?? this.notes,
    );
  }
}
