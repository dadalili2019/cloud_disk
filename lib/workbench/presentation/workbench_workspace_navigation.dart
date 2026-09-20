part of 'workbench_workspace_overview_page.dart';

class _WorkspaceNavigation extends StatelessWidget {
  const _WorkspaceNavigation({
    required this.workspaceId,
    required this.section,
    required this.onSettings,
  });

  final String workspaceId;
  final String section;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: palette.appBackground,
        border: Border(
          bottom: BorderSide(color: palette.cardBorder.withValues(alpha: 0.68)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 1180 ? 40.0 : 32.0;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _WorkspaceTab(
                              label: '概览',
                              selected: section == 'overview',
                              onTap: () => context.go('/workspace/$workspaceId/overview'),
                            ),
                            _WorkspaceTab(
                              label: '任务',
                              selected: section == 'tasks',
                              onTap: () => context.go('/workspace/$workspaceId/tasks'),
                            ),
                            _WorkspaceTab(
                              label: '笔记',
                              selected: section == 'notes',
                              onTap: () => context.go('/workspace/$workspaceId/notes'),
                            ),
                            _WorkspaceTab(
                              label: '问题',
                              selected: section == 'issues',
                              onTap: () => context.go('/workspace/$workspaceId/issues'),
                            ),
                            _WorkspaceTab(
                              label: '资源',
                              selected: section == 'resources',
                              onTap: () => context.go('/workspace/$workspaceId/resources'),
                            ),
                            _WorkspaceTab(
                              label: '决策',
                              selected: section == 'decisions',
                              onTap: () => context.go('/workspace/$workspaceId/decisions'),
                            ),
                            _WorkspaceTab(
                              label: '开发',
                              selected: section == 'developer',
                              onTap: () => context.go('/workspace/$workspaceId/developer'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(FluentIcons.settings, size: 14),
                      onPressed: onSettings,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WorkspaceTab extends StatelessWidget {
  const _WorkspaceTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? palette.navItemSelected : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: selected
                  ? Border.all(color: palette.cardBorder.withValues(alpha: 0.86))
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? theme.accentColor.normal
                    : theme.typography.body?.color?.withValues(alpha: 0.68),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
