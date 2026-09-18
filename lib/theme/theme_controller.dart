import 'package:fluent_ui/fluent_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePalette {
  const ThemePalette({
    required this.id,
    required this.label,
    required this.accentName,
    required this.appBackground,
    required this.navBackground,
    required this.cardBackground,
    required this.surfaceMuted,
    required this.softAccent,
    required this.successSoft,
    required this.dangerSoft,
    required this.cardBorder,
    required this.navBorder,
    required this.navItemHover,
    required this.navItemSelected,
    required this.appBarBackground,
    required this.appBarBorder,
    required this.shadow,
  });

  final String id;
  final String label;
  final String accentName;
  final Color appBackground;
  final Color navBackground;
  final Color cardBackground;
  final Color surfaceMuted;
  final Color softAccent;
  final Color successSoft;
  final Color dangerSoft;
  final Color cardBorder;
  final Color navBorder;
  final Color navItemHover;
  final Color navItemSelected;
  final Color appBarBackground;
  final Color appBarBorder;
  final Color shadow;
}

class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;
  AccentColor _accent = _limeAccent;
  String? _fontFamily;
  String _presetId = 'comfort_dark';

  ThemeMode get mode => _mode;
  AccentColor get accent => _accent;
  String? get fontFamily => _fontFamily;
  String get effectiveFontFamily => _fontFamily ?? 'Microsoft YaHei UI';
  String get presetId => _presetId;
  ThemePalette get palette => palettes[_presetId] ?? palettes['comfort_dark']!;

  set mode(ThemeMode v) {
    _mode = v;
    _save();
    notifyListeners();
  }

  set accent(AccentColor v) {
    _accent = v;
    _save();
    notifyListeners();
  }

  set fontFamily(String? v) {
    _fontFamily = (v?.isEmpty ?? true) ? null : v;
    _save();
    notifyListeners();
  }

  set presetId(String id) {
    final next = palettes[id];
    if (next == null) return;
    _presetId = id;
    _accent = _accentFromName(next.accentName);
    _save();
    notifyListeners();
  }

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final modeIndex = sp.getInt('theme.mode') ?? ThemeMode.dark.index;
    final safeModeIndex =
        modeIndex.clamp(0, ThemeMode.values.length - 1).toInt();
    _mode = ThemeMode.values[safeModeIndex];
    _accent = _accentFromName(sp.getString('theme.accent') ?? 'lime');
    _fontFamily = sp.getString('theme.font');
    _presetId = sp.getString('theme.preset') ?? 'comfort_dark';

    final migrated = sp.getBool('theme.workbench_v1_4_migrated') ?? false;
    if (!migrated) {
      _presetId = 'comfort_dark';
      _mode = ThemeMode.dark;
      _accent = _limeAccent;
      await _save();
      await sp.setBool('theme.workbench_v1_4_migrated', true);
    } else if (!palettes.containsKey(_presetId)) {
      _presetId = 'comfort_dark';
      _mode = ThemeMode.dark;
      _accent = _limeAccent;
      await _save();
    }

    notifyListeners();
  }

  Future<void> reset() async {
    _mode = ThemeMode.dark;
    _presetId = 'comfort_dark';
    _accent = _accentFromName(palette.accentName);
    _fontFamily = null;
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('theme.mode', _mode.index);
    await sp.setString('theme.accent', _accentName(_accent));
    await sp.setString('theme.preset', _presetId);
    if (_fontFamily == null) {
      await sp.remove('theme.font');
    } else {
      await sp.setString('theme.font', _fontFamily!);
    }
  }

  static final Map<String, AccentColor> accents = {
    'blue': Colors.blue.toAccentColor(),
    'teal': Colors.teal.toAccentColor(),
    'green': Colors.green.toAccentColor(),
    'purple': Colors.purple.toAccentColor(),
    'orange': Colors.orange.toAccentColor(),
    'red': Colors.red.toAccentColor(),
    'gray': Colors.grey.toAccentColor(),
    'pink': _pinkAccent,
    'lime': _limeAccent,
  };

  static final Map<String, ThemePalette> palettes = {
    'comfort_dark': const ThemePalette(
      id: 'comfort_dark',
      label: 'Comfort Dark',
      accentName: 'lime',
      appBackground: Color(0xFF202224),
      navBackground: Color(0xFF1E2022),
      cardBackground: Color(0xFF26292B),
      surfaceMuted: Color(0xFF2D3133),
      softAccent: Color(0xFF303630),
      successSoft: Color(0xFF2C362C),
      dangerSoft: Color(0xFF382D2F),
      cardBorder: Color(0xFF35393C),
      navBorder: Color(0xFF313538),
      navItemHover: Color(0xFF292C2F),
      navItemSelected: Color(0xFF303438),
      appBarBackground: Color(0xFF1E2022),
      appBarBorder: Color(0xFF313538),
      shadow: Color(0xFF111312),
    ),
    'default': const ThemePalette(
      id: 'default',
      label: '奶油薄荷',
      accentName: 'teal',
      appBackground: Color(0xFFF8F6F1),
      navBackground: Color(0xFFFFFBF6),
      cardBackground: Color(0xFFFFFFFF),
      surfaceMuted: Color(0xFFF4FAF6),
      softAccent: Color(0xFFEAF5FF),
      successSoft: Color(0xFFEAF8EF),
      dangerSoft: Color(0xFFFFF0F4),
      cardBorder: Color(0xFFF0E8E1),
      navBorder: Color(0xFFF1EAE2),
      navItemHover: Color(0xFFFAF5EF),
      navItemSelected: Color(0xFFF1FAF4),
      appBarBackground: Color(0xFFFFFCF7),
      appBarBorder: Color(0xFFF0E8E1),
      shadow: Color(0xFF6E7D74),
    ),
    'mist_blue': const ThemePalette(
      id: 'mist_blue',
      label: '雾蓝',
      accentName: 'teal',
      appBackground: Color(0xFFF4F8FB),
      navBackground: Color(0xFFF9FCFE),
      cardBackground: Color(0xFFFFFFFF),
      surfaceMuted: Color(0xFFEEF6FA),
      softAccent: Color(0xFFE6F2FB),
      successSoft: Color(0xFFEAF8F2),
      dangerSoft: Color(0xFFFFF0F5),
      cardBorder: Color(0xFFE8F0F5),
      navBorder: Color(0xFFE1EBF2),
      navItemHover: Color(0xFFF4F9FC),
      navItemSelected: Color(0xFFEDF7FC),
      appBarBackground: Color(0xFFF7FBFE),
      appBarBorder: Color(0xFFE3EDF4),
      shadow: Color(0xFF65798A),
    ),
    'mint': const ThemePalette(
      id: 'mint',
      label: '薄荷绿',
      accentName: 'green',
      appBackground: Color(0xFFF5FAF6),
      navBackground: Color(0xFFFBFEFC),
      cardBackground: Color(0xFFFFFFFF),
      surfaceMuted: Color(0xFFECF7F0),
      softAccent: Color(0xFFEAF5FF),
      successSoft: Color(0xFFE1F4E8),
      dangerSoft: Color(0xFFFFF0F4),
      cardBorder: Color(0xFFE8F1EA),
      navBorder: Color(0xFFE1EEE5),
      navItemHover: Color(0xFFF4FAF6),
      navItemSelected: Color(0xFFEDF8F1),
      appBarBackground: Color(0xFFF8FCF9),
      appBarBorder: Color(0xFFE2EFE6),
      shadow: Color(0xFF6F806F),
    ),
    'sunset': const ThemePalette(
      id: 'sunset',
      label: '蜜桃晚霞',
      accentName: 'orange',
      appBackground: Color(0xFFFAF5F7),
      navBackground: Color(0xFFFFFBFC),
      cardBackground: Color(0xFFFFFFFF),
      surfaceMuted: Color(0xFFFFF3EE),
      softAccent: Color(0xFFF0EBFF),
      successSoft: Color(0xFFEAF8EF),
      dangerSoft: Color(0xFFFFEEF4),
      cardBorder: Color(0xFFF2E6EB),
      navBorder: Color(0xFFF0E2E8),
      navItemHover: Color(0xFFFCF3F6),
      navItemSelected: Color(0xFFFFF3EE),
      appBarBackground: Color(0xFFFFFAFB),
      appBarBorder: Color(0xFFF0E2E8),
      shadow: Color(0xFF856E79),
    ),
  };

  static final AccentColor _limeAccent =
      AccentColor.swatch(const <String, Color>{
    'normal': Color(0xFF7D9B69),
    'lighter': Color(0xFF9EB48C),
    'light': Color(0xFF8DA779),
    'dark': Color(0xFF678254),
    'darker': Color(0xFF526943),
  });

  static final AccentColor _pinkAccent =
      AccentColor.swatch(const <String, Color>{
    'normal': Color(0xFFE75D8D),
    'lighter': Color(0xFFF6A8C5),
    'light': Color(0xFFEE86AB),
    'dark': Color(0xFFD24C7B),
    'darker': Color(0xFFB53E67),
  });

  static AccentColor _accentFromName(String name) =>
      accents[name] ?? Colors.teal.toAccentColor();

  static String _accentName(AccentColor a) {
    return accents.entries
        .firstWhere(
          (e) => e.value == a,
          orElse: () => accents.entries.first,
        )
        .key;
  }

  FluentThemeData buildTheme(Brightness b) {
    final isDark = b == Brightness.dark;
    final primaryText = isDark
        ? const Color(0xFFB2BAB2)
        : const Color(0xFF333A35);
    final secondaryText = isDark
        ? const Color(0xFF8D958E)
        : const Color(0xFF667068);
    final tertiaryText = isDark
        ? const Color(0xFF6F7871)
        : const Color(0xFF858E87);

    return FluentThemeData(
      brightness: b,
      accentColor: _accent,
      fontFamily: effectiveFontFamily,
      typography: Typography.fromBrightness(
        brightness: b,
        color: primaryText,
      ),
      resources: isDark
          ? ResourceDictionary.dark(
              textFillColorPrimary: primaryText,
              textFillColorSecondary: secondaryText,
              textFillColorTertiary: tertiaryText,
              textFillColorDisabled: const Color(0xFF5E6660),
              textOnAccentFillColorPrimary: const Color(0xFF182017),
              textOnAccentFillColorSecondary: const Color(0xFF283126),
              controlStrongFillColorDefault: const Color(0xFF838B84),
              controlStrongStrokeColorDefault: const Color(0xFF838B84),
              focusStrokeColorOuter: const Color(0xFF7D9B69),
              dividerStrokeColorDefault: const Color(0xFF35393C),
            )
          : ResourceDictionary.light(),
      scaffoldBackgroundColor: palette.appBackground,
      cardColor: palette.cardBackground,
      inactiveColor: palette.cardBorder,
    );
  }
}

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static ThemeController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()!.notifier!;
}
