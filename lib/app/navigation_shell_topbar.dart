part of 'navigation_page.dart';

enum _NavTarget {
  home,
  workspace,
  time,
  knowledge,
  developer,
  tools,
  settings,
}

const double _shellTopbarHeight = 58;
const double _shellSidebarWidth = 208;

/// 外框单独配色，避免本轮视觉调整改变内页的主题与表单。
class _ShellColors {
  const _ShellColors({
    required this.background,
    required this.surface,
    required this.border,
    required this.text,
    required this.secondary,
    required this.accent,
    required this.selection,
    required this.hover,
  });

  final Color background;
  final Color surface;
  final Color border;
  final Color text;
  final Color secondary;
  final Color accent;
  final Color selection;
  final Color hover;

  factory _ShellColors.of(BuildContext context) {
    final theme = FluentTheme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final accent = dark
        ? Color.lerp(theme.accentColor.normal, Colors.white, 0.38)!
        : theme.accentColor.dark;
    return _ShellColors(
      background: dark ? const Color(0xFF1C1F22) : const Color(0xFFF0F2EF),
      surface: dark ? const Color(0xFF25292C) : const Color(0xFFFAFBF9),
      border: dark ? const Color(0xFF363B3D) : const Color(0xFFDDE2DA),
      text: dark ? const Color(0xFFE8ECE7) : const Color(0xFF262E29),
      secondary: dark ? const Color(0xFF9BA59E) : const Color(0xFF657068),
      accent: accent,
      selection: accent.withValues(alpha: dark ? 0.12 : 0.10),
      hover: dark ? const Color(0xFF292E30) : const Color(0xFFE5EAE3),
    );
  }
}

/// 标题栏只放全局入口，中间留出可拖动区域。

class _Topbar extends StatelessWidget {
  const _Topbar({
    required this.aiOpen,
    required this.onSearchPressed,
    required this.onAiPressed,
  });

  final bool aiOpen;
  final VoidCallback onSearchPressed;
  final VoidCallback onAiPressed;

  @override
  Widget build(BuildContext context) {
    final colors = _ShellColors.of(context);
    return SizedBox(
      height: _shellTopbarHeight,
      child: Row(
        children: [
          SizedBox(
            width: _shellSidebarWidth,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colors.selection,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: colors.accent.withValues(alpha: 0.25)),
                    ),
                    alignment: Alignment.center,
                    child: Text('W',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: colors.accent,
                        )),
                  ),
                  const SizedBox(width: 10),
                  Text('个人工作台',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: colors.text,
                      )),
                ],
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              return Row(children: [
                if (constraints.maxWidth >= 260)
                  SizedBox(
                    width: constraints.maxWidth >= 460 ? 340 : 220,
                    child: _ShellButton(
                      label: '搜索知识与工作内容',
                      onPressed: onSearchPressed,
                      background: colors.surface,
                      child: Row(children: [
                        Icon(FluentIcons.search,
                            size: 14, color: colors.secondary),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(
                          '搜索知识与工作内容',
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 12, color: colors.secondary),
                        )),
                      ]),
                    ),
                  )
                else
                  Tooltip(
                      message: '搜索知识与工作内容',
                      child: SizedBox(
                        width: 36,
                        child: _ShellButton(
                          label: '搜索知识与工作内容',
                          onPressed: onSearchPressed,
                          child: Icon(FluentIcons.search,
                              size: 15, color: colors.secondary),
                        ),
                      )),
                Expanded(child: WindowTitleBarBox(child: MoveWindow())),
              ]);
            }),
          ),
          Tooltip(
              message: '打开 AI 助手',
              child: SizedBox(
                width: 38,
                child: _ShellButton(
                  label: 'AI 助手',
                  selected: aiOpen,
                  onPressed: onAiPressed,
                  child: Icon(FluentIcons.chat_bot,
                      size: 17,
                      color: aiOpen ? colors.accent : colors.secondary),
                ),
              )),
          const SizedBox(width: 12),
          Container(width: 1, height: 18, color: colors.border),
          if (Platform.isWindows)
            const SizedBox(width: 150, child: WindowButtons())
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}

/// 统一外框按钮的悬停与键盘焦点，避免仅靠鼠标手势响应。

class _ShellButton extends StatelessWidget {
  const _ShellButton({
    required this.label,
    required this.onPressed,
    required this.child,
    this.selected = false,
    this.background,
    this.height = 36,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final String label;
  final VoidCallback onPressed;
  final Widget child;
  final bool selected;
  final Color? background;
  final double height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = _ShellColors.of(context);
    return Semantics(
      label: label,
      selected: selected,
      child: Button(
        onPressed: onPressed,
        style: ButtonStyle(
          padding: WidgetStateProperty.all(padding),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (selected) return colors.selection;
            if (states.isHovered || states.isPressed) return colors.hover;
            return background ?? Colors.transparent;
          }),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          )),
        ),
        child: DefaultTextStyle.merge(
          textAlign: TextAlign.left,
          child: SizedBox(height: height, child: child),
        ),
      ),
    );
  }
}
