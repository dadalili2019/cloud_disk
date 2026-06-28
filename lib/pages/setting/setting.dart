import 'package:fluent_ui/fluent_ui.dart';

import '../../theme/theme_controller.dart';

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

  @override
  Widget build(BuildContext context) {
    final themeCtrl = ThemeScope.of(context);
    final palette = themeCtrl.palette;
    final brightness =
        themeCtrl.mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
    final currentAccentName = ThemeController.accents.entries
        .firstWhere(
          (e) => e.value == themeCtrl.accent,
          orElse: () => ThemeController.accents.entries.first,
        )
        .key;

    return ScaffoldPage(
      header: const PageHeader(title: Text('Appearance')),
      content: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                children: [
                  _Card(
                    title: 'Theme Preset',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ComboBox<String>(
                          value: themeCtrl.presetId,
                          isExpanded: true,
                          items: ThemeController.palettes.values
                              .map((p) => ComboBoxItem<String>(
                                  value: p.id, child: Text(p.label)))
                              .toList(),
                          onChanged: (id) {
                            if (id != null) themeCtrl.presetId = id;
                          },
                        ),
                        const SizedBox(height: 12),
                        _PalettePreview(palette: palette),
                      ],
                    ),
                  ),
                  _Card(
                    title: 'Theme Mode',
                    child: ComboBox<ThemeMode>(
                      value: themeCtrl.mode,
                      isExpanded: true,
                      items: const [
                        ComboBoxItem(
                            value: ThemeMode.light, child: Text('Light')),
                        ComboBoxItem(
                            value: ThemeMode.dark, child: Text('Dark')),
                        ComboBoxItem(
                            value: ThemeMode.system, child: Text('System')),
                      ],
                      onChanged: (v) {
                        if (v != null) themeCtrl.mode = v;
                      },
                    ),
                  ),
                  _Card(
                    title: 'Accent Color',
                    child: Row(
                      children: [
                        Expanded(
                          child: ComboBox<String>(
                            value: currentAccentName,
                            isExpanded: true,
                            items: ThemeController.accents.keys
                                .map((k) => ComboBoxItem<String>(
                                    value: k, child: Text(k)))
                                .toList(),
                            onChanged: (name) {
                              if (name != null) {
                                themeCtrl.accent =
                                    ThemeController.accents[name]!;
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: themeCtrl.accent.defaultBrushFor(brightness),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.black.withOpacity(0.1)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Card(
                    title: 'Font Family',
                    child: ComboBox<String?>(
                      value: themeCtrl.fontFamily,
                      isExpanded: true,
                      items: fonts
                          .map((f) => ComboBoxItem<String?>(
                              value: f, child: Text(f ?? 'System Default')))
                          .toList(),
                      onChanged: (f) => themeCtrl.fontFamily = f,
                    ),
                  ),
                  const _Card(
                    title: 'Preview',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme Preview ABCD 1234',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 8),
                        Text(
                            'Preset changes page background, nav background, card border and shadow.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: HyperlinkButton(
                      onPressed: themeCtrl.reset,
                      child: const Text('Reset Default'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PalettePreview extends StatelessWidget {
  const _PalettePreview({required this.palette});

  final ThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SwatchBox(label: 'Page', color: palette.appBackground),
        _SwatchBox(label: 'Nav', color: palette.navBackground),
        _SwatchBox(label: 'Card', color: palette.cardBackground),
        _SwatchBox(label: 'Border', color: palette.cardBorder),
      ],
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
            border: Border.all(
                color: palette.cardBorder.withOpacity(0.75), width: 0.8),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    final palette = ThemeScope.of(context).palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: t.resources.cardBackgroundFillColorDefault,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: palette.cardBorder.withOpacity(0.72), width: 0.8),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 6),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
