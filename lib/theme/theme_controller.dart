import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePalette {
  const ThemePalette({
    required this.id,
    required this.label,
    required this.accentName,
    required this.appBackground,
    required this.navBackground,
    required this.cardBackground,
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
  AccentColor _accent = Colors.blue.toAccentColor();
  String? _fontFamily;
  String _presetId = 'default';

  ThemeMode get mode => _mode;
  AccentColor get accent => _accent;
  String? get fontFamily => _fontFamily;
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
    _mode = ThemeMode.values[sp.getInt('theme.mode') ?? ThemeMode.light.index];
    _accent = _accentFromName(sp.getString('theme.accent') ?? 'blue');
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
      label: '默认白',
      accentName: 'blue',
      appBackground: Color(0xFFF3F5F8),
      navBackground: Color(0xFFEFF2F6),
      cardBackground: Color(0xFFFFFFFF),
      cardBorder: Color(0xFFE6EAF0),
      navBorder: Color(0xFFDCE3EC),
      navItemHover: Color(0xFFF1F4F8),
      navItemSelected: Color(0xFFE8EEF6),
      appBarBackground: Color(0xFFF8FAFD),
      appBarBorder: Color(0xFFDCE3EC),
      shadow: Color(0x0F0F172A),
    ),
    'mist_blue': const ThemePalette(
      id: 'mist_blue',
      label: '雾蓝',
      accentName: 'teal',
      appBackground: Color(0xFFF0F6FA),
      navBackground: Color(0xFFE7F0F6),
      cardBackground: Color(0xFFFFFFFF),
      cardBorder: Color(0xFFDDE8F0),
      navBorder: Color(0xFFD2E0EB),
      navItemHover: Color(0xFFEEF5FA),
      navItemSelected: Color(0xFFE1EDF7),
      appBarBackground: Color(0xFFF6FAFD),
      appBarBorder: Color(0xFFD2E0EB),
      shadow: Color(0x1020334A),
    ),
    'mint': const ThemePalette(
      id: 'mint',
      label: '薄荷绿',
      accentName: 'green',
      appBackground: Color(0xFFF3F9F6),
      navBackground: Color(0xFFEAF4EE),
      cardBackground: Color(0xFFFFFFFF),
      cardBorder: Color(0xFFDDEDE4),
      navBorder: Color(0xFFD3E7DB),
      navItemHover: Color(0xFFEEF7F2),
      navItemSelected: Color(0xFFE2F1E8),
      appBarBackground: Color(0xFFF7FCF9),
      appBarBorder: Color(0xFFD3E7DB),
      shadow: Color(0x10213428),
    ),
    'sunset': const ThemePalette(
      id: 'sunset',
      label: '暮紫橙',
      accentName: 'orange',
      appBackground: Color(0xFFF7F3F8),
      navBackground: Color(0xFFF1EAF4),
      cardBackground: Color(0xFFFFFFFF),
      cardBorder: Color(0xFFE9DFF0),
      navBorder: Color(0xFFE1D2EC),
      navItemHover: Color(0xFFF6EFFA),
      navItemSelected: Color(0xFFEEE4F5),
      appBarBackground: Color(0xFFFCF8FD),
      appBarBorder: Color(0xFFE1D2EC),
      shadow: Color(0x121F1530),
    ),
  };

  static final AccentColor _pinkAccent = AccentColor.swatch(const <String, Color>{
    'normal': Color(0xFFE75D8D),
    'lighter': Color(0xFFF6A8C5),
    'light': Color(0xFFEE86AB),
    'dark': Color(0xFFD24C7B),
    'darker': Color(0xFFB53E67),
  });

  static AccentColor _accentFromName(String name) => accents[name] ?? Colors.blue.toAccentColor();

  static String _accentName(AccentColor a) {
    return accents.entries.firstWhere(
      (e) => e.value == a,
      orElse: () => accents.entries.first,
    ).key;
  }

  FluentThemeData buildTheme(Brightness b) => FluentThemeData(
        brightness: b,
        accentColor: _accent,
        fontFamily: _fontFamily,
      );
}

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({super.key, required ThemeController controller, required Widget child})
      : super(notifier: controller, child: child);

  static ThemeController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()!.notifier!;
}
