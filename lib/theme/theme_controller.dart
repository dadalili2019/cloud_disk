///  @author caoqian
/// @since 2025-08-09 15:08
/// @Description:

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;
  AccentColor _accent = Colors.blue.toAccentColor();
  String? _fontFamily; // null = 系统默认

  ThemeMode get mode => _mode;
  AccentColor get accent => _accent;
  String? get fontFamily => _fontFamily;

  set mode(ThemeMode v)        { _mode = v;        _save(); notifyListeners(); }
  set accent(AccentColor v)    { _accent = v;      _save(); notifyListeners(); }
  set fontFamily(String? v)    { _fontFamily = (v?.isEmpty ?? true) ? null : v; _save(); notifyListeners(); }

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _mode       = ThemeMode.values[sp.getInt('theme.mode') ?? ThemeMode.light.index];
    _accent     = _accentFromName(sp.getString('theme.accent') ?? 'blue');
    _fontFamily = sp.getString('theme.font');
    notifyListeners();
  }

  Future<void> reset() async {
    _mode = ThemeMode.light;
    _accent = Colors.blue.toAccentColor();
    _fontFamily = null;
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('theme.mode', _mode.index);
    await sp.setString('theme.accent', _accentName(_accent));
    if (_fontFamily == null) {
      await sp.remove('theme.font');
    } else {
      await sp.setString('theme.font', _fontFamily!);
    }
  }

  // —— 强调色（4.5 版本安全可用）——
  static final Map<String, AccentColor> accents = {
    'blue'  : Colors.blue .toAccentColor(),
    'teal'  : Colors.teal .toAccentColor(),
    'green' : Colors.green.toAccentColor(),
    'purple': Colors.purple.toAccentColor(),
    'orange': Colors.orange.toAccentColor(),
    'red'   : Colors.red  .toAccentColor(),
    'gray'  : Colors.grey .toAccentColor(),
    // 想要“粉色”，用下面自定义的 pink（已配好一个温柔粉）
    'pink'  : _pinkAccent,
  };

  // 自定义粉色（如果不想要粉，删掉上面的 'pink' 和这段即可）
  static final AccentColor _pinkAccent = AccentColor.swatch(const <String, Color>{
    'normal' : Color(0xFFE75D8D),
    'lighter': Color(0xFFF6A8C5),
    'light'  : Color(0xFFEE86AB),
    'dark'   : Color(0xFFD24C7B),
    'darker' : Color(0xFFB53E67),
  });

  static AccentColor _accentFromName(String name) =>
      accents[name] ?? Colors.blue.toAccentColor();

  static String _accentName(AccentColor a) =>
      accents.entries.firstWhere(
            (e) => e.value == a,
        orElse: () => accents.entries.first,
      ).key;

  FluentThemeData buildTheme(Brightness b) => FluentThemeData(
    brightness: b,
    accentColor: _accent,
    fontFamily: _fontFamily,
  );
}

// 全局访问（不依赖第三方状态管理）
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({super.key, required ThemeController controller, required Widget child})
      : super(notifier: controller, child: child);

  static ThemeController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()!.notifier!;
}

