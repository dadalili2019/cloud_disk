import 'package:fluent_ui/fluent_ui.dart';

import '../theme/theme_controller.dart';

class CloudCard extends StatelessWidget {
  const CloudCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.backgroundColor,
    this.radius = 8,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double radius;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.cardBackground,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: palette.cardBorder.withOpacity(0.72),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: elevated ? 12 : 4,
            offset: Offset(0, elevated ? 5 : 2),
            color: palette.shadow.withOpacity(elevated ? 0.22 : 0.10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SoftPill extends StatelessWidget {
  const SoftPill({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final palette = ThemeScope.of(context).palette;
    final fg = foregroundColor ?? theme.accentColor.darkest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.softAccent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.06), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel({
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
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.accentColor,
    this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final Color accentColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;

    return CloudCard(
      elevated: false,
      backgroundColor: backgroundColor ?? palette.surfaceMuted,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 3),
          Opacity(
            opacity: 0.68,
            child: Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
