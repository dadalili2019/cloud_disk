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
  ThemeMode _mode = ThemeMode.light;
  AccentColor _accent = Colors.teal.toAccentColor();
  String? _fontFamily;
  String _presetId = 'default';

  ThemeMode get mode => _mode;
  AccentColor get accent => _accent;
  String? get fontFamily => _fontFamily;
  String get effectiveFontFamily => _fontFamily ?? 'Microsoft YaHei UI';
  String get presetId => _presetId;
  ThemePalette get palette => palettes[_presetId] ?? palettes['default']!;

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
    final modeIndex = sp.getInt('theme.mode') ?? ThemeMode.light.index;
    final safeModeIndex =
        modeIndex.clamp(0, ThemeMode.values.length - 1).toInt();
    _mode = ThemeMode.values[safeModeIndex];
    _accent = _accentFromName(sp.getString('theme.accent') ?? 'teal');
    _fontFamily = sp.getString('theme.font');
    _presetId = sp.getString('theme.preset') ?? 'default';
    if (!palettes.containsKey(_presetId)) {
      _presetId = 'default';
    }
    notifyListeners();
  }

  Future<void> reset() async {
    _mode = ThemeMode.light;
    _presetId = 'default';
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
  };

  static final Map<String, ThemePalette> palettes = {
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
    final isLight = b == Brightness.light;
    return FluentThemeData(
      brightness: b,
      accentColor: _accent,
      fontFamily: effectiveFontFamily,
      scaffoldBackgroundColor: isLight ? palette.appBackground : null,
      cardColor: isLight ? palette.cardBackground : null,
      inactiveColor: isLight ? palette.cardBorder : null,
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
