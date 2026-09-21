import 'package:fluent_ui/fluent_ui.dart';

import '../../theme/theme_controller.dart';

double _workbenchHorizontalPadding(double width) {
  if (width >= 1280) return 40;
  if (width >= 960) return 32;
  if (width >= 720) return 26;
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
    this.topPadding = 18,
    this.bottomPadding = 48,
    this.headerGap = 14,
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
                        if (actions.isNotEmpty) ...[
                          WorkbenchPageHeader(
                            title: title,
                            subtitle: subtitle,
                            actions: actions,
                          ),
                          SizedBox(height: headerGap),
                        ],
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
    this.topPadding = 18,
    this.bottomPadding = 32,
    this.headerGap = 14,
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
                      if (actions.isNotEmpty) ...[
                        WorkbenchPageHeader(
                          title: title,
                          subtitle: subtitle,
                          actions: actions,
                          compact: true,
                        ),
                        SizedBox(height: headerGap),
                      ],
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
    final actionBlock = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: actions,
    );

    return Semantics(
      header: true,
      label: title,
      child: SizedBox(
        height: 32,
        child: Align(
          alignment: Alignment.centerRight,
          child: actionBlock,
        ),
      ),
    );
  }
}

class WorkbenchCard extends StatelessWidget {
  const WorkbenchCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
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
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: emphasized
              ? accent.withValues(alpha: 0.38)
              : palette.cardBorder.withValues(alpha: 0.78),
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
                  : theme.typography.body?.color?.withValues(alpha: 0.66),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (description.trim().isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.4,
                    color: theme.typography.body?.color?.withValues(alpha: 0.70),
                  ),
                ),
              ],
            ],
          );
          final action = FilledButton(
            onPressed: onAction,
            child: Text(actionLabel),
          );

          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                copy,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerLeft, child: action),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: copy),
              const SizedBox(width: 16),
              action,
            ],
          );
        },
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
              : theme.typography.body?.color?.withValues(alpha: 0.82),
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


class WorkbenchAsyncList<T> extends StatelessWidget {
  const WorkbenchAsyncList({
    super.key,
    required this.future,
    required this.emptyTitle,
    required this.emptyActionLabel,
    required this.onEmptyAction,
    required this.itemBuilder,
    this.emptyDescription = '',
    this.separatorHeight = 12,
    this.padding = const EdgeInsets.only(bottom: 8),
  });

  final Future<List<T>> future;
  final String emptyTitle;
  final String emptyDescription;
  final String emptyActionLabel;
  final VoidCallback onEmptyAction;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final double separatorHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: ProgressRing());
        }
        if (snapshot.hasError) {
          return Center(child: Text('加载失败：${snapshot.error}'));
        }

        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return WorkbenchEmptyState(
            title: emptyTitle,
            description: emptyDescription,
            actionLabel: emptyActionLabel,
            onAction: onEmptyAction,
          );
        }

        return ListView.separated(
          padding: padding,
          itemCount: items.length,
          separatorBuilder: (_, __) => SizedBox(height: separatorHeight),
          itemBuilder: (context, index) => itemBuilder(context, items[index]),
        );
      },
    );
  }
}
