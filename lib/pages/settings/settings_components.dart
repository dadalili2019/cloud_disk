part of 'settings_page.dart';

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
