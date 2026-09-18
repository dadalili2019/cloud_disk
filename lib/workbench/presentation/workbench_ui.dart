import 'package:fluent_ui/fluent_ui.dart';

import '../../theme/theme_controller.dart';

double _workbenchHorizontalPadding(double width) {
  if (width >= 1280) return 34;
  if (width >= 960) return 28;
  if (width >= 720) return 24;
  return 16;
}

class WorkbenchPage extends StatelessWidget {
  const WorkbenchPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.actions = const [],
    this.maxWidth = 1180,
    this.topPadding = 24,
    this.bottomPadding = 48,
    this.headerGap = 20,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget> children;
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
            final horizontal = _workbenchHorizontalPadding(constraints.maxWidth);
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
                        SizedBox(height: headerGap),
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
            final horizontal = _workbenchHorizontalPadding(constraints.maxWidth);
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackActions = actions.isNotEmpty && constraints.maxWidth < 560;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: compact ? 20 : 26,
                height: 1.14,
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
                  color: theme.typography.body?.color?.withValues(alpha: 0.56),
                ),
              ),
            ],
          ],
        );

        final actionBlock = Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: actions,
        );

        if (stackActions) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleBlock,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: actionBlock),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: 18),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: actionBlock,
              ),
            ],
          ],
        );
      },
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
    this.backgroundColor,
    this.borderColor,
    this.radius = 12,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double? minHeight;
  final Color? backgroundColor;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final body = Container(
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.cardBackground,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? palette.cardBorder),
      ),
      child: child,
    );

    if (onTap == null) return body;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: body,
      ),
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
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}

class WorkbenchInfoBlock extends StatelessWidget {
  const WorkbenchInfoBlock({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final palette = ThemeScope.of(context).palette;
    final accent = theme.accentColor.normal;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        color: emphasized ? palette.softAccent : palette.surfaceMuted,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: palette.cardBorder.withValues(alpha: 0.78),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.55,
              color: emphasized
                  ? accent
                  : theme.typography.body?.color?.withValues(alpha: 0.46),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, height: 1.42),
          ),
        ],
      ),
    );
  }
}

class WorkbenchEmptyState extends StatelessWidget {
  const WorkbenchEmptyState({
    super.key,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return WorkbenchCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.4,
                    color: theme.typography.body?.color?.withValues(alpha: 0.52),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
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
              ? theme.accentColor.withValues(alpha: 0.32)
              : palette.cardBorder.withValues(alpha: 0.78),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          color: selected
              ? theme.accentColor.normal
              : theme.typography.body?.color?.withValues(alpha: 0.68),
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
