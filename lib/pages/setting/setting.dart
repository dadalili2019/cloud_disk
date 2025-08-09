import 'package:fluent_ui/fluent_ui.dart';
import '../../theme/theme_controller.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  // 可选字体（需要系统已安装；null=系统默认）
  static const List<String?> fonts = <String?>[
    null, // 系统默认
    'Segoe UI',
    'Microsoft YaHei',
    'Roboto',
    'Noto Sans SC',
  ];

  @override
  Widget build(BuildContext context) {
    final themeCtrl = ThemeScope.of(context);
    final currentAccentName = ThemeController.accents.entries
        .firstWhere((e) => e.value == themeCtrl.accent, orElse: () => ThemeController.accents.entries.first)
        .key;

    return ScaffoldPage(
      header: const PageHeader(title: Text('外观设置')),
      content: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // 主题模式
          _Card(
            title: '主题模式',
            child: ComboBox<ThemeMode>(
              value: themeCtrl.mode,
              isExpanded: true,
              items: const [
                ComboBoxItem(value: ThemeMode.light, child: Text('浅色')),
                ComboBoxItem(value: ThemeMode.dark,  child: Text('深色')),
                ComboBoxItem(value: ThemeMode.system, child: Text('跟随系统')),
              ],
              onChanged: (v) => themeCtrl.mode = v!,
            ),
          ),

          // 强调色
          _Card(
            title: '主题颜色（强调色）',
            child: Row(
              children: [
                Expanded(
                  child: ComboBox<String>(
                    value: currentAccentName,
                    isExpanded: true,
                    items: ThemeController.accents.keys
                        .map((k) => ComboBoxItem<String>(value: k, child: Text(k)))
                        .toList(),
                    onChanged: (name) => themeCtrl.accent = ThemeController.accents[name]!,
                  ),
                ),
                const SizedBox(width: 12),
                // 小预览块
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: themeCtrl.accent.defaultBrushFor(themeCtrl.mode == ThemeMode.dark ? Brightness.dark : Brightness.light),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black.withOpacity(0.1)),
                  ),
                ),
              ],
            ),
          ),

          // 字体
          _Card(
            title: '字体',
            child: ComboBox<String?>(
              value: themeCtrl.fontFamily,
              isExpanded: true,
              items: fonts.map((f) {
                final label = f ?? '系统默认';
                return ComboBoxItem<String?>(value: f, child: Text(label));
              }).toList(),
              onChanged: (f) => themeCtrl.fontFamily = f,
            ),
          ),

          // 预览
          _Card(
            title: '预览',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('标题 ABCD abcd 1234', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text('这是一段示例文本，用于预览当前主题颜色与字体效果。'),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: HyperlinkButton(
              child: const Text('恢复默认'),
              onPressed: () {
                themeCtrl.mode = ThemeMode.light;
                themeCtrl.accent = Colors.blue.toAccentColor();
                themeCtrl.fontFamily = null;
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 小卡片外观
class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = FluentTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.resources.cardBackgroundFillColorDefault,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(blurRadius: 10, offset: Offset(0, 4), color: Color(0x14000000))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
