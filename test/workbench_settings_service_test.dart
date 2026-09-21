import 'package:cloud_disk/workbench/application/workbench_settings_service.dart';
import 'package:cloud_disk/workbench/core/workbench_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('WorkbenchSettingsService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('create uses stable defaults when preferences are empty', () async {
      final service = await WorkbenchSettingsService.create();

      expect(service.current.general.defaultWorkspaceId, isNull);
      expect(service.current.general.startupPage, WorkbenchStartupPage.home);
      expect(service.current.general.quickCaptureToCurrentTask, isTrue);
      expect(service.current.general.restoreLastActiveContext, isTrue);

      expect(service.current.notes.defaultView, NoteDefaultView.edit);
      expect(service.current.notes.autoSave, isTrue);

      expect(service.current.ai.mode, AIProviderMode.environment);
      expect(service.current.ai.baseUrl, isEmpty);
      expect(service.current.ai.model, isEmpty);
      expect(service.current.ai.chatPath, isEmpty);
      expect(service.current.ai.timeoutSeconds, 90);

      expect(service.current.backup.frequency, BackupFrequency.off);
      expect(service.current.backup.keepAutoBackups, 10);
      expect(service.current.backup.includeAttachmentsInExport, isTrue);
      expect(service.current.backup.lastAutoBackupAt, isNull);
      expect(service.sessionAIKey, isEmpty);
    });

    test('general and notes settings persist across service recreation', () async {
      final service = await WorkbenchSettingsService.create();

      await service.updateGeneral(
        const GeneralSettings(
          defaultWorkspaceId: '  workspace-1  ',
          startupPage: WorkbenchStartupPage.knowledge,
          quickCaptureToCurrentTask: false,
          restoreLastActiveContext: false,
        ),
      );
      await service.updateNotes(
        const NotesSettings(
          defaultView: NoteDefaultView.split,
          autoSave: false,
        ),
      );

      final recreated = await WorkbenchSettingsService.create();

      expect(recreated.current.general.defaultWorkspaceId, 'workspace-1');
      expect(
        recreated.current.general.startupPage,
        WorkbenchStartupPage.knowledge,
      );
      expect(recreated.current.general.quickCaptureToCurrentTask, isFalse);
      expect(recreated.current.general.restoreLastActiveContext, isFalse);
      expect(recreated.current.notes.defaultView, NoteDefaultView.split);
      expect(recreated.current.notes.autoSave, isFalse);
    });

    test('AI settings trim text, clamp timeout and never persist session key', () async {
      final service = await WorkbenchSettingsService.create();

      await service.updateAI(
        const AISettings(
          mode: AIProviderMode.openAICompatible,
          baseUrl: '  https://example.test/v1  ',
          model: '  model-x  ',
          chatPath: '  /chat/completions  ',
          timeoutSeconds: 2,
        ),
      );
      service.setSessionAIKey('  secret-key  ');

      expect(service.current.ai.baseUrl, 'https://example.test/v1');
      expect(service.current.ai.model, 'model-x');
      expect(service.current.ai.chatPath, '/chat/completions');
      expect(service.current.ai.timeoutSeconds, 5);
      expect(service.sessionAIKey, 'secret-key');

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getKeys().where(
          (key) =>
              key.toLowerCase().contains('api_key') ||
              key.toLowerCase().contains('apikey') ||
              key.toLowerCase().contains('secret') ||
              key.toLowerCase().contains('token'),
        ),
        isEmpty,
      );

      final recreated = await WorkbenchSettingsService.create();
      expect(recreated.sessionAIKey, isEmpty);
      expect(recreated.current.ai.baseUrl, 'https://example.test/v1');
      expect(recreated.current.ai.timeoutSeconds, 5);
    });

    test('AI timeout and backup retention enforce upper bounds', () async {
      final service = await WorkbenchSettingsService.create();

      await service.updateAI(
        const AISettings(timeoutSeconds: 9999),
      );
      await service.updateBackup(
        const BackupSettings(
          frequency: BackupFrequency.daily,
          keepAutoBackups: 999,
          includeAttachmentsInExport: false,
        ),
      );

      expect(service.current.ai.timeoutSeconds, 600);
      expect(service.current.backup.keepAutoBackups, 50);
      expect(service.current.backup.frequency, BackupFrequency.daily);
      expect(
        service.current.backup.includeAttachmentsInExport,
        isFalse,
      );

      await service.updateBackup(
        const BackupSettings(keepAutoBackups: 0),
      );
      expect(service.current.backup.keepAutoBackups, 1);
    });

    test('last active location only persists supported routes', () async {
      final service = await WorkbenchSettingsService.create();

      await service.rememberLastActiveLocation('/settings');
      expect(service.lastActiveLocation, isNull);

      await service.rememberLastActiveLocation('/workspace/workspace-1/task');
      expect(
        service.lastActiveLocation,
        '/workspace/workspace-1/task',
      );

      await service.rememberLastActiveLocation('/knowledge');
      expect(service.lastActiveLocation, '/knowledge');
    });

    test('resetAI clears session key and persisted AI configuration', () async {
      final service = await WorkbenchSettingsService.create();

      await service.updateAI(
        const AISettings(
          mode: AIProviderMode.deepseek,
          baseUrl: 'https://example.test',
          model: 'model-x',
          chatPath: '/chat',
          timeoutSeconds: 120,
        ),
      );
      service.setSessionAIKey('secret-key');

      await service.resetAI();

      expect(service.sessionAIKey, isEmpty);
      expect(service.current.ai.mode, AIProviderMode.environment);
      expect(service.current.ai.baseUrl, isEmpty);
      expect(service.current.ai.model, isEmpty);
      expect(service.current.ai.chatPath, isEmpty);
      expect(service.current.ai.timeoutSeconds, 90);

      final recreated = await WorkbenchSettingsService.create();
      expect(recreated.current.ai.mode, AIProviderMode.environment);
      expect(recreated.current.ai.baseUrl, isEmpty);
      expect(recreated.current.ai.timeoutSeconds, 90);
    });

    test('invalid persisted enum values fall back to defaults', () async {
      SharedPreferences.setMockInitialValues({
        'workbench.general.startup_page': 'unknown',
        'workbench.notes.default_view': 'unknown',
        'workbench.ai.mode': 'unknown',
        'workbench.backup.frequency': 'unknown',
      });

      final service = await WorkbenchSettingsService.create();

      expect(service.current.general.startupPage, WorkbenchStartupPage.home);
      expect(service.current.notes.defaultView, NoteDefaultView.edit);
      expect(service.current.ai.mode, AIProviderMode.environment);
      expect(service.current.backup.frequency, BackupFrequency.off);
    });
  });
}
