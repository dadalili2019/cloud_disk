import 'package:fluent_ui/fluent_ui.dart';

import '../../theme/theme_controller.dart';

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
  static const List<String?> fonts = <String?>[
    null,
    'Microsoft YaHei UI',
    'Segoe UI',
    'Microsoft YaHei',
    'Roboto',
    'Noto Sans SC',
  ];

  _SettingsSection _section = _SettingsSection.appearance;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;

    return ScaffoldPage(
      header: const PageHeader(title: Text('设置')),
      content: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: compact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _CompactNavigation(
                              section: _section,
                              onChanged: _setSection,
                            ),
                            const SizedBox(height: 12),
                            _sectionContent(palette),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 190,
                              child: _SettingsNavigation(
                                section: _section,
                                onChanged: _setSection,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: _sectionContent(palette)),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _setSection(_SettingsSection value) {
    if (_section == value) return;
    setState(() => _section = value);
  }

  Widget _sectionContent(ThemePalette palette) {
    return switch (_section) {
      _SettingsSection.general => const _PendingSection(
          title: '常规',
          rows: ['默认工作区', '启动页面', '快速记录', '恢复上次工作上下文'],
        ),
      _SettingsSection.appearance => _AppearanceSection(fonts: fonts),
      _SettingsSection.notes => const _PendingSection(
          title: '笔记',
          rows: ['Markdown 格式', '默认视图', '自动保存', '笔记目录'],
        ),
      _SettingsSection.ai => const _PendingSection(
          title: 'AI',
          rows: ['Provider', 'Base URL', 'Model', 'API Key', '连接测试'],
        ),
      _SettingsSection.data => const _PendingSection(
          title: '数据与备份',
          rows: ['本地数据目录', '自动备份', '导出', '恢复'],
        ),
      _SettingsSection.shortcuts => const _PendingSection(
          title: '快捷键',
          rows: ['全局搜索', '快速记录', 'AI', '继续工作', '保存笔记'],
        ),
    };
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
    final palette = ThemeScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        children: _SettingsSection.values
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: _SettingsNavigationItem(
                  item: item,
                  selected: item == section,
                  onTap: () => onChanged(item),
                ),
              ),
            )
            .toList(growable: false),
      ),
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
        borderRadius: BorderRadius.circular(11),
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
                  : theme.typography.body?.color?.withOpacity(0.56),
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

  final List<String?> fonts;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeading(title: '外观'),
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
                                child: Text(name),
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
                child: ComboBox<String?>(
                  value: themeCtrl.fontFamily,
                  isExpanded: true,
                  items: fonts
                      .map(
                        (font) => ComboBoxItem<String?>(
                          value: font,
                          child: Text(font ?? '系统默认'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (font) => themeCtrl.fontFamily = font,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SettingsGroup(
          title: '预览',
          children: [
            Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Workbench',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SwatchBox(label: '页面', color: palette.appBackground),
                      _SwatchBox(label: '导航', color: palette.navBackground),
                      _SwatchBox(label: '卡片', color: palette.cardBackground),
                      _SwatchBox(label: '边框', color: palette.cardBorder),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: HyperlinkButton(
            onPressed: themeCtrl.reset,
            child: const Text('恢复默认外观'),
          ),
        ),
      ],
    );
  }
}

class _PendingSection extends StatelessWidget {
  const _PendingSection({required this.title, required this.rows});

  final String title;
  final List<String> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(title: title),
        _SettingsGroup(
          title: title,
          children: rows
              .map(
                (row) => _SettingRow(
                  title: row,
                  control: const Text(
                    '待配置',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
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
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: palette.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 10),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: theme.typography.body?.color?.withOpacity(0.48),
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
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
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
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: theme.typography.body?.color?.withOpacity(0.48),
                    ),
                  ),
                ],
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

class _SwatchBox extends StatelessWidget {
  const _SwatchBox({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: palette.cardBorder),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10.5)),
      ],
    );
  }
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
