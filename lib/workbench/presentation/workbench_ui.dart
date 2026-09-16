import 'package:fluent_ui/fluent_ui.dart';

import '../../theme/theme_controller.dart';

class WorkbenchPage extends StatelessWidget {
  const WorkbenchPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.actions = const [],
    this.maxWidth = 1180,
    this.topPadding = 26,
    this.bottomPadding = 40,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;
  final double maxWidth;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Container(
        color: palette.appBackground,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 1180 ? 34.0 : 28.0;
            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                topPadding,
                horizontal,
                bottomPadding,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkbenchPageHeader(
                          title: title,
                          subtitle: subtitle,
                          actions: actions,
                        ),
                        const SizedBox(height: 22),
                        ...children,
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class WorkbenchSectionPage extends StatelessWidget {
  const WorkbenchSectionPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.maxWidth = 1180,
    this.topPadding = 20,
    this.bottomPadding = 24,
    this.headerGap = 16,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;
  final double maxWidth;
  final double topPadding;
  final double bottomPadding;
  final double headerGap;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Container(
        color: palette.appBackground,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 1180 ? 34.0 : 28.0;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                topPadding,
                horizontal,
                bottomPadding,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WorkbenchPageHeader(
                        title: title,
                        subtitle: subtitle,
                        actions: actions,
                        compact: true,
                      ),
                      SizedBox(height: headerGap),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class WorkbenchPageHeader extends StatelessWidget {
  const WorkbenchPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: compact ? 20 : 27,
                  height: 1.12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: compact ? -0.1 : -0.3,
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                SizedBox(height: compact ? 4 : 6),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: compact ? 10.5 : 11.5,
                    height: 1.45,
                    color: theme.typography.body?.color?.withOpacity(0.58),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: 18),
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: actions,
            ),
          ),
        ],
      ],
    );
  }
}

class WorkbenchCard extends StatelessWidget {
  const WorkbenchCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.minHeight,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final body = Container(
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      padding: padding,
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.cardBorder),
      ),
      child: child,
    );

    if (onTap == null) return body;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: body),
    );
  }
}

class WorkbenchSectionHeader extends StatelessWidget {
  const WorkbenchSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}

class WorkbenchTag extends StatelessWidget {
  const WorkbenchTag({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final palette = ThemeScope.of(context).palette;
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? palette.navItemSelected : palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? theme.accentColor.withOpacity(0.32)
              : palette.cardBorder.withOpacity(0.78),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          color: theme.typography.body?.color?.withOpacity(0.68),
        ),
      ),
    );

    if (onTap == null) return child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}
