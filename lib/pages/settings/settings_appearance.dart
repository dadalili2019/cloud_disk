part of 'settings_page.dart';

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
