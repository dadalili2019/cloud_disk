import 'package:fluent_ui/fluent_ui.dart';

import '../../theme/theme_controller.dart';
import '../../workbench/core/models.dart';
import '../../workbench/core/workbench_settings.dart';
import '../../workbench/workbench_runtime.dart';
import 'ai_settings_section.dart';
import 'data_backup_section.dart';

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
      _SettingsSection.appearance => _AppearanceSection(fonts: fonts),
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

class _GeneralSection extends StatelessWidget {
  const _GeneralSection({
    required this.settings,
    required this.workspaces,
    required this.onChanged,
  });

  final GeneralSettings settings;
  final List<WorkspaceModel> workspaces;
  final ValueChanged<GeneralSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final defaultWorkspaceValid = settings.defaultWorkspaceId != null &&
        workspaces.any((item) => item.id == settings.defaultWorkspaceId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsGroup(
          title: '常规',
          children: [
            _SettingRow(
              title: '默认工作区',
              control: SizedBox(
                width: 250,
                child: ComboBox<String>(
                  value: defaultWorkspaceValid
                      ? settings.defaultWorkspaceId
                      : '__none__',
                  isExpanded: true,
                  items: [
                    const ComboBoxItem(
                      value: '__none__',
                      child: Text('不指定'),
                    ),
                    ...workspaces.map(
                      (workspace) => ComboBoxItem(
                        value: workspace.id,
                        child: Text(workspace.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    if (value == '__none__') {
                      onChanged(settings.copyWith(clearDefaultWorkspace: true));
                    } else {
                      onChanged(settings.copyWith(defaultWorkspaceId: value));
                    }
                  },
                ),
              ),
            ),
            _SettingRow(
              title: '启动页面',
              control: SizedBox(
                width: 250,
                child: ComboBox<WorkbenchStartupPage>(
                  value: settings.startupPage,
                  isExpanded: true,
                  items: const [
                    ComboBoxItem(
                      value: WorkbenchStartupPage.home,
                      child: Text('首页'),
                    ),
                    ComboBoxItem(
                      value: WorkbenchStartupPage.workspace,
                      child: Text('工作台'),
                    ),
                    ComboBoxItem(
                      value: WorkbenchStartupPage.knowledge,
                      child: Text('知识'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onChanged(settings.copyWith(startupPage: value));
                    }
                  },
                ),
              ),
            ),
            _SettingRow(
              title: '快速记录关联当前任务',
              control: ToggleSwitch(
                checked: settings.quickCaptureToCurrentTask,
                onChanged: (value) => onChanged(
                  settings.copyWith(quickCaptureToCurrentTask: value),
                ),
              ),
            ),
            _SettingRow(
              title: '恢复上次工作上下文',
              control: ToggleSwitch(
                checked: settings.restoreLastActiveContext,
                onChanged: (value) => onChanged(
                  settings.copyWith(restoreLastActiveContext: value),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({
    required this.settings,
    required this.notesPath,
    required this.onChanged,
  });

  final NotesSettings settings;
  final String notesPath;
  final ValueChanged<NotesSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsGroup(
          title: 'Markdown 笔记',
          children: [
            const _SettingRow(
              title: '存储格式',
              control: _ValueBadge('.md'),
            ),
            _SettingRow(
              title: '默认视图',
              control: SizedBox(
                width: 250,
                child: ComboBox<NoteDefaultView>(
                  value: settings.defaultView,
                  isExpanded: true,
                  items: const [
                    ComboBoxItem(
                      value: NoteDefaultView.edit,
                      child: Text('编辑'),
                    ),
                    ComboBoxItem(
                      value: NoteDefaultView.preview,
                      child: Text('预览'),
                    ),
                    ComboBoxItem(
                      value: NoteDefaultView.split,
                      child: Text('分栏'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onChanged(settings.copyWith(defaultView: value));
                    }
                  },
                ),
              ),
            ),
            _SettingRow(
              title: '自动保存',
              control: ToggleSwitch(
                checked: settings.autoSave,
                onChanged: (value) =>
                    onChanged(settings.copyWith(autoSave: value)),
              ),
            ),
            _SettingRow(
              title: '笔记目录',
              control: SizedBox(
                width: 320,
                child: SelectableText(
                  notesPath,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShortcutsSection extends StatelessWidget {
  const _ShortcutsSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsGroup(
          title: '快捷键',
          children: [
            _SettingRow(
              title: '保存笔记',
              control: _ValueBadge('Ctrl + S'),
            ),
            _SettingRow(
              title: '发送 AI 消息',
              control: _ValueBadge('Ctrl + Enter'),
            ),
            _SettingRow(
              title: '关闭 AI 助手',
              control: _ValueBadge('Esc'),
            ),
            _SettingRow(
              title: '全局搜索',
              control: _ValueBadge('未绑定'),
            ),
            _SettingRow(
              title: '快速记录',
              control: _ValueBadge('未绑定'),
            ),
            _SettingRow(
              title: '打开 AI',
              control: _ValueBadge('未绑定'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsNavigation extends StatelessWidget {
  const _SettingsNavigation({
    required this.section,
    required this.onChanged,
  });

  final _SettingsSection section;
  final ValueChanged<_SettingsSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _SettingsSection.values
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _SettingsNavigationItem(
                item: item,
                selected: item == section,
                onTap: () => onChanged(item),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _CompactNavigation extends StatelessWidget {
  const _CompactNavigation({
    required this.section,
    required this.onChanged,
  });

  final _SettingsSection section;
  final ValueChanged<_SettingsSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.cardBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _SettingsSection.values
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _SettingsNavigationItem(
                    item: item,
                    selected: item == section,
                    compact: true,
                    onTap: () => onChanged(item),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _SettingsNavigationItem extends StatelessWidget {
  const _SettingsNavigationItem({
    required this.item,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final _SettingsSection item;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final theme = FluentTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        height: 36,
        constraints: compact ? null : const BoxConstraints(minWidth: double.infinity),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? palette.navItemSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(
              _sectionIcon(item),
              size: 13,
              color: selected
                  ? theme.accentColor.normal
                  : theme.typography.body?.color?.withValues(alpha: 0.56),
            ),
            const SizedBox(width: 9),
            Text(
              _sectionLabel(item),
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? theme.accentColor.normal : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection({required this.fonts});

  final List<String> fonts;

  @override
  Widget build(BuildContext context) {
    final themeCtrl = ThemeScope.of(context);
    final palette = themeCtrl.palette;
    final brightness =
        themeCtrl.mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
    final currentAccentName = ThemeController.accents.entries
        .firstWhere(
          (entry) => entry.value == themeCtrl.accent,
          orElse: () => ThemeController.accents.entries.first,
        )
        .key;
    final fontValue = themeCtrl.fontFamily ?? _SettingsPageDefaults.systemFont;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsGroup(
          title: '主题',
          children: [
            _SettingRow(
              title: '主题预设',
              control: SizedBox(
                width: 230,
                child: ComboBox<String>(
                  value: themeCtrl.presetId,
                  isExpanded: true,
                  items: ThemeController.palettes.values
                      .map(
                        (item) => ComboBoxItem<String>(
                          value: item.id,
                          child: Text(item.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (id) {
                    if (id != null) themeCtrl.presetId = id;
                  },
                ),
              ),
            ),
            _SettingRow(
              title: '显示模式',
              control: SizedBox(
                width: 230,
                child: ComboBox<ThemeMode>(
                  value: themeCtrl.mode,
                  isExpanded: true,
                  items: const [
                    ComboBoxItem(value: ThemeMode.light, child: Text('浅色')),
                    ComboBoxItem(value: ThemeMode.dark, child: Text('深色')),
                    ComboBoxItem(value: ThemeMode.system, child: Text('跟随系统')),
                  ],
                  onChanged: (value) {
                    if (value != null) themeCtrl.mode = value;
                  },
                ),
              ),
            ),
            _SettingRow(
              title: '强调色',
              control: SizedBox(
                width: 230,
                child: Row(
                  children: [
                    Expanded(
                      child: ComboBox<String>(
                        value: currentAccentName,
                        isExpanded: true,
                        items: ThemeController.accents.keys
                            .map(
                              (name) => ComboBoxItem<String>(
                                value: name,
                                child: Text(_accentLabel(name)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (name) {
                          if (name != null) {
                            themeCtrl.accent = ThemeController.accents[name]!;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: themeCtrl.accent.defaultBrushFor(brightness),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: palette.cardBorder),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _SettingRow(
              title: '字体',
              control: SizedBox(
                width: 230,
                child: ComboBox<String>(
                  value: fontValue,
                  isExpanded: true,
                  items: fonts
                      .map(
                        (font) => ComboBoxItem<String>(
                          value: font,
                          child: Text(
                            font == _SettingsPageDefaults.systemFont
                                ? '系统默认'
                                : font,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (font) {
                    if (font == null) return;
                    themeCtrl.fontFamily =
                        font == _SettingsPageDefaults.systemFont ? null : font;
                  },
                ),
              ),
            ),
            _SettingRow(
              title: '恢复默认',
              control: Button(
                onPressed: themeCtrl.reset,
                child: const Text('恢复'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final theme = FluentTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: theme.typography.body?.color?.withValues(alpha: 0.48),
              ),
            ),
          ),
          Container(height: 1, color: palette.cardBorder),
          ..._withDividers(children, palette),
        ],
      ),
    );
  }

  static List<Widget> _withDividers(
    List<Widget> children,
    ThemePalette palette,
  ) {
    final result = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      result.add(children[index]);
      if (index != children.length - 1) {
        result.add(Container(height: 1, color: palette.cardBorder));
      }
    }
    return result;
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.control,
  });

  final String title;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          control,
        ],
      ),
    );
  }
}

class _ValueBadge extends StatelessWidget {
  const _ValueBadge(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Text(value, style: const TextStyle(fontSize: 10)),
    );
  }
}

class _SettingsPageDefaults {
  static const systemFont = '__system__';
}

String _sectionLabel(_SettingsSection section) {
  return switch (section) {
    _SettingsSection.general => '常规',
    _SettingsSection.appearance => '外观',
    _SettingsSection.notes => '笔记',
    _SettingsSection.ai => 'AI',
    _SettingsSection.data => '数据与备份',
    _SettingsSection.shortcuts => '快捷键',
  };
}

IconData _sectionIcon(_SettingsSection section) {
  return switch (section) {
    _SettingsSection.general => FluentIcons.settings,
    _SettingsSection.appearance => FluentIcons.color,
    _SettingsSection.notes => FluentIcons.edit_note,
    _SettingsSection.ai => FluentIcons.chat_bot,
    _SettingsSection.data => FluentIcons.database,
    _SettingsSection.shortcuts => FluentIcons.keyboard_classic,
  };
}

String _accentLabel(String value) {
  switch (value.toLowerCase()) {
    case 'green':
      return '绿色';
    case 'blue':
      return '蓝色';
    case 'purple':
      return '紫色';
    case 'orange':
      return '橙色';
    case 'red':
      return '红色';
    case 'teal':
      return '青绿色';
    case 'pink':
      return '粉色';
    case 'lime':
      return '柔和绿';
    default:
      return value;
  }
}
