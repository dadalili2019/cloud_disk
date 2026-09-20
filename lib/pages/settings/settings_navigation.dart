part of 'settings_page.dart';

class _SettingsNavigation extends StatelessWidget {
  const _SettingsNavigation({
    required this.section,
    required this.onChanged,
  });

  final _SettingsSection section;
  final ValueChanged<_SettingsSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _SettingsSection.values
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _SettingsNavigationItem(
                item: item,
                selected: item == section,
                onTap: () => onChanged(item),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _CompactNavigation extends StatelessWidget {
  const _CompactNavigation({
    required this.section,
    required this.onChanged,
  });

  final _SettingsSection section;
  final ValueChanged<_SettingsSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.cardBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _SettingsSection.values
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _SettingsNavigationItem(
                    item: item,
                    selected: item == section,
                    compact: true,
                    onTap: () => onChanged(item),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _SettingsNavigationItem extends StatelessWidget {
  const _SettingsNavigationItem({
    required this.item,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final _SettingsSection item;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final theme = FluentTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        height: 36,
        constraints: compact ? null : const BoxConstraints(minWidth: double.infinity),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? palette.navItemSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(
              _sectionIcon(item),
              size: 13,
              color: selected
                  ? theme.accentColor.normal
                  : theme.typography.body?.color?.withValues(alpha: 0.56),
            ),
            const SizedBox(width: 9),
            Text(
              _sectionLabel(item),
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? theme.accentColor.normal : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
