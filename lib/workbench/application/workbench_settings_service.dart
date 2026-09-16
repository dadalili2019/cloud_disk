import 'package:shared_preferences/shared_preferences.dart';

import '../core/workbench_settings.dart';

class WorkbenchSettingsService {
  WorkbenchSettingsService._(this._preferences, this._current);

  final SharedPreferences _preferences;
  WorkbenchSettingsModel _current;

  WorkbenchSettingsModel get current => _current;

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
