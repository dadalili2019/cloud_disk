import 'package:fluent_ui/fluent_ui.dart';

import '../../theme/theme_controller.dart';
import '../../workbench/core/models.dart';
import '../../workbench/core/workbench_settings.dart';
import '../../workbench/workbench_runtime.dart';
import 'ai_settings_section.dart';
import 'data_backup_section.dart';

part 'settings_sections.dart';
part 'settings_navigation.dart';
part 'settings_appearance.dart';
part 'settings_components.dart';

enum _SettingsSection {
  general,
  appearance,
  notes,
  ai,
  data,
  shortcuts,
}

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  static const String _systemFont = '__system__';
  static const List<String> fonts = <String>[
    _systemFont,
    'Microsoft YaHei UI',
    'Segoe UI',
    'Microsoft YaHei',
    'Roboto',
    'Noto Sans SC',
  ];

  final ScrollController _scrollController = ScrollController();
  _SettingsSection _section = _SettingsSection.appearance;
  WorkbenchRuntime? _runtime;
  WorkbenchSettingsModel _settings = const WorkbenchSettingsModel();
  List<WorkspaceModel> _workspaces = const [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final runtime = await WorkbenchRuntime.instance;
      final workspaces = await runtime.workspaceService.listActive();
      if (!mounted) return;
      setState(() {
        _runtime = runtime;
        _settings = runtime.settingsService.current;
        _workspaces = workspaces;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _updateGeneral(GeneralSettings value) async {
    final runtime = _runtime;
    if (runtime == null) return;
    await runtime.settingsService.updateGeneral(value);
    if (!mounted) return;
    setState(() => _settings = runtime.settingsService.current);
  }

  Future<void> _updateNotes(NotesSettings value) async {
    final runtime = _runtime;
    if (runtime == null) return;
    await runtime.settingsService.updateNotes(value);
    if (!mounted) return;
    setState(() => _settings = runtime.settingsService.current);
  }

  void _refreshSettings() {
    final runtime = _runtime;
    if (runtime == null || !mounted) return;
    setState(() => _settings = runtime.settingsService.current);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: Container(
        color: ThemeScope.of(context).palette.appBackground,
        child: _loading
            ? const Center(child: ProgressRing())
            : _error != null
                ? Center(child: Text('设置加载失败：$_error'))
                : LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 760;
                    final horizontal = constraints.maxWidth >= 1280
                        ? 40.0
                        : constraints.maxWidth >= 960
                            ? 32.0
                            : 24.0;
                    return ListView(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        18,
                        horizontal,
                        36,
                      ),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1180),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (compact)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _CompactNavigation(
                                        section: _section,
                                        onChanged: _setSection,
                                      ),
                                      const SizedBox(height: 16),
                                      _sectionContent(),
                                    ],
                                  )
                                else
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 168,
                                        child: _SettingsNavigation(
                                          section: _section,
                                          onChanged: _setSection,
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(child: _sectionContent()),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
      ),
    );
  }

  void _setSection(_SettingsSection value) {
    if (_section == value) return;
    setState(() => _section = value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  Widget _sectionContent() {
    return switch (_section) {
      _SettingsSection.general => _GeneralSection(
          settings: _settings.general,
          workspaces: _workspaces,
          onChanged: _updateGeneral,
        ),
      _SettingsSection.appearance => const _AppearanceSection(fonts: fonts),
      _SettingsSection.notes => _NotesSection(
          settings: _settings.notes,
          notesPath: _runtime == null
              ? 'PersonalWorkbench/workspaces/<workspace>/notes'
              : '${_runtime!.paths.workspacesDirectory.path}\\<workspace>\\notes',
          onChanged: _updateNotes,
        ),
      _SettingsSection.ai => _runtime == null
          ? const Center(child: ProgressRing())
          : AISettingsSection(
              runtime: _runtime!,
              settings: _settings.ai,
              onSettingsChanged: _refreshSettings,
            ),
      _SettingsSection.data => _runtime == null
          ? const Center(child: ProgressRing())
          : DataBackupSection(
              runtime: _runtime!,
              settings: _settings.backup,
              onSettingsChanged: _refreshSettings,
            ),
      _SettingsSection.shortcuts => const _ShortcutsSection(),
    };
  }
}

