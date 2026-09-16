import 'package:shared_preferences/shared_preferences.dart';

import '../core/workbench_settings.dart';

class WorkbenchSettingsService {
  WorkbenchSettingsService._(this._preferences, this._current);

  final SharedPreferences _preferences;
  WorkbenchSettingsModel _current;
  String _sessionAIKey = '';

  WorkbenchSettingsModel get current => _current;
  String get sessionAIKey => _sessionAIKey;

  static Future<WorkbenchSettingsService> create() async {
    final preferences = await SharedPreferences.getInstance();
    return WorkbenchSettingsService._(
      preferences,
      WorkbenchSettingsModel(
        general: GeneralSettings(
          defaultWorkspaceId: _nullableString(
            preferences.getString(_Keys.defaultWorkspaceId),
          ),
          startupPage: _enumValue(
            WorkbenchStartupPage.values,
            preferences.getString(_Keys.startupPage),
            WorkbenchStartupPage.home,
          ),
          quickCaptureToCurrentTask:
              preferences.getBool(_Keys.quickCaptureToCurrentTask) ?? true,
          restoreLastActiveContext:
              preferences.getBool(_Keys.restoreLastActiveContext) ?? true,
        ),
        notes: NotesSettings(
          defaultView: _enumValue(
            NoteDefaultView.values,
            preferences.getString(_Keys.noteDefaultView),
            NoteDefaultView.edit,
          ),
          autoSave: preferences.getBool(_Keys.noteAutoSave) ?? true,
        ),
        ai: AISettings(
          mode: _enumValue(
            AIProviderMode.values,
            preferences.getString(_Keys.aiMode),
            AIProviderMode.environment,
          ),
          baseUrl: preferences.getString(_Keys.aiBaseUrl)?.trim() ?? '',
          model: preferences.getString(_Keys.aiModel)?.trim() ?? '',
          chatPath: preferences.getString(_Keys.aiChatPath)?.trim() ?? '',
          timeoutSeconds: preferences.getInt(_Keys.aiTimeoutSeconds) ?? 90,
        ),
        backup: BackupSettings(
          frequency: _enumValue(
            BackupFrequency.values,
            preferences.getString(_Keys.backupFrequency),
            BackupFrequency.off,
          ),
          keepAutoBackups: preferences.getInt(_Keys.backupKeepCount) ?? 10,
          includeAttachmentsInExport:
              preferences.getBool(_Keys.exportIncludeAttachments) ?? true,
          lastAutoBackupAt: _dateTime(
            preferences.getString(_Keys.lastAutoBackupAt),
          ),
        ),
      ),
    );
  }

  Future<void> updateGeneral(GeneralSettings value) async {
    _current = _current.copyWith(general: value);
    final defaultWorkspaceId = value.defaultWorkspaceId?.trim();
    if (defaultWorkspaceId == null || defaultWorkspaceId.isEmpty) {
      await _preferences.remove(_Keys.defaultWorkspaceId);
    } else {
      await _preferences.setString(_Keys.defaultWorkspaceId, defaultWorkspaceId);
    }
    await _preferences.setString(_Keys.startupPage, value.startupPage.name);
    await _preferences.setBool(
      _Keys.quickCaptureToCurrentTask,
      value.quickCaptureToCurrentTask,
    );
    await _preferences.setBool(
      _Keys.restoreLastActiveContext,
      value.restoreLastActiveContext,
    );
  }

  Future<void> updateNotes(NotesSettings value) async {
    _current = _current.copyWith(notes: value);
    await _preferences.setString(_Keys.noteDefaultView, value.defaultView.name);
    await _preferences.setBool(_Keys.noteAutoSave, value.autoSave);
  }

  Future<void> updateAI(AISettings value) async {
    final timeoutSeconds = value.timeoutSeconds < 5
        ? 5
        : value.timeoutSeconds > 600
            ? 600
            : value.timeoutSeconds;
    final normalized = AISettings(
      mode: value.mode,
      baseUrl: value.baseUrl.trim(),
      model: value.model.trim(),
      chatPath: value.chatPath.trim(),
      timeoutSeconds: timeoutSeconds,
    );
    _current = _current.copyWith(ai: normalized);
    await _preferences.setString(_Keys.aiMode, normalized.mode.name);
    await _preferences.setString(_Keys.aiBaseUrl, normalized.baseUrl);
    await _preferences.setString(_Keys.aiModel, normalized.model);
    await _preferences.setString(_Keys.aiChatPath, normalized.chatPath);
    await _preferences.setInt(_Keys.aiTimeoutSeconds, normalized.timeoutSeconds);
  }

  Future<void> updateBackup(BackupSettings value) async {
    final keepCount = value.keepAutoBackups < 1
        ? 1
        : value.keepAutoBackups > 50
            ? 50
            : value.keepAutoBackups;
    final normalized = BackupSettings(
      frequency: value.frequency,
      keepAutoBackups: keepCount,
      includeAttachmentsInExport: value.includeAttachmentsInExport,
      lastAutoBackupAt: value.lastAutoBackupAt,
    );
    _current = _current.copyWith(backup: normalized);
    await _preferences.setString(
      _Keys.backupFrequency,
      normalized.frequency.name,
    );
    await _preferences.setInt(_Keys.backupKeepCount, normalized.keepAutoBackups);
    await _preferences.setBool(
      _Keys.exportIncludeAttachments,
      normalized.includeAttachmentsInExport,
    );
    if (normalized.lastAutoBackupAt == null) {
      await _preferences.remove(_Keys.lastAutoBackupAt);
    } else {
      await _preferences.setString(
        _Keys.lastAutoBackupAt,
        normalized.lastAutoBackupAt!.toUtc().toIso8601String(),
      );
    }
  }

  Future<void> markAutoBackupCompleted(DateTime value) async {
    await updateBackup(
      _current.backup.copyWith(lastAutoBackupAt: value.toUtc()),
    );
  }

  void setSessionAIKey(String value) {
    _sessionAIKey = value.trim();
  }

  void clearSessionAIKey() {
    _sessionAIKey = '';
  }

  String? get lastActiveLocation =>
      _nullableString(_preferences.getString(_Keys.lastActiveLocation));

  Future<void> rememberLastActiveLocation(String location) async {
    if (!_isRestorableLocation(location)) return;
    await _preferences.setString(_Keys.lastActiveLocation, location);
  }

  Future<void> resetGeneral() async {
    const value = GeneralSettings();
    await updateGeneral(value);
    await _preferences.remove(_Keys.lastActiveLocation);
  }

  Future<void> resetNotes() => updateNotes(const NotesSettings());

  Future<void> resetAI() async {
    clearSessionAIKey();
    await updateAI(const AISettings());
  }

  Future<void> resetBackup() => updateBackup(const BackupSettings());

  static bool _isRestorableLocation(String location) {
    return location == '/home' ||
        location == '/workspace' ||
        location == '/knowledge' ||
        location.startsWith('/workspace/');
  }
}

class _Keys {
  static const defaultWorkspaceId = 'workbench.general.default_workspace_id';
  static const startupPage = 'workbench.general.startup_page';
  static const quickCaptureToCurrentTask =
      'workbench.general.quick_capture_to_current_task';
  static const restoreLastActiveContext =
      'workbench.general.restore_last_active_context';
  static const lastActiveLocation = 'workbench.general.last_active_location';
  static const noteDefaultView = 'workbench.notes.default_view';
  static const noteAutoSave = 'workbench.notes.auto_save';
  static const aiMode = 'workbench.ai.mode';
  static const aiBaseUrl = 'workbench.ai.base_url';
  static const aiModel = 'workbench.ai.model';
  static const aiChatPath = 'workbench.ai.chat_path';
  static const aiTimeoutSeconds = 'workbench.ai.timeout_seconds';
  static const backupFrequency = 'workbench.backup.frequency';
  static const backupKeepCount = 'workbench.backup.keep_count';
  static const exportIncludeAttachments =
      'workbench.export.include_attachments';
  static const lastAutoBackupAt = 'workbench.backup.last_auto_backup_at';
}

T _enumValue<T extends Enum>(
  List<T> values,
  String? raw,
  T fallback,
) {
  if (raw == null || raw.isEmpty) return fallback;
  for (final value in values) {
    if (value.name == raw) return value;
  }
  return fallback;
}

String? _nullableString(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

DateTime? _dateTime(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}
