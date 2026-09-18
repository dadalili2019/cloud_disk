import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../application/continue_service.dart';
import 'workbench_ui.dart';

class ResumeContextDrawer extends StatelessWidget {
  const ResumeContextDrawer({
    super.key,
    required this.item,
    required this.onClose,
  });

  final ContinueItem item;
  final VoidCallback onClose;

  String _targetRoute() {
    final notes = [...item.context.notes]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final issues = [...item.context.openIssues]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (notes.isNotEmpty &&
        (issues.isEmpty || notes.first.updatedAt.isAfter(issues.first.updatedAt))) {
      return '/workspace/${item.workspace.id}/notes';
    }
    if (issues.isNotEmpty) {
      return '/workspace/${item.workspace.id}/issues';
    }
    return '/workspace/${item.workspace.id}/overview';
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final theme = FluentTheme.of(context);
    final task = item.context.task;
    final blockers = item.context.openIssues;
    final activity = item.context.recentActivity;
    final lastContext = activity.isNotEmpty
        ? activity.first.summary
        : task.description.trim().isNotEmpty
            ? task.description.trim()
            : '暂无最近上下文。';
    final secondary = theme.typography.body?.color?.withValues(alpha: 0.56);

    return Container(
      width: 620,
      decoration: BoxDecoration(
        color: palette.appBackground,
        border: Border(left: BorderSide(color: palette.cardBorder)),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(-8, 0),
            color: palette.shadow.withValues(alpha: 0.28),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: palette.cardBorder)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '继续工作',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(FluentIcons.chrome_close, size: 13),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.workspace.name,
                            style: TextStyle(fontSize: 10.5, color: secondary),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    WorkbenchTag(
                      label: task.status == 'doing' ? '进行中' : task.status,
                      selected: true,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                WorkbenchInfoBlock(
                  label: '下一步',
                  value: task.nextStep.trim().isEmpty
                      ? '暂未设置下一步。'
                      : task.nextStep.trim(),
                  emphasized: true,
                ),
                if (blockers.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  WorkbenchInfoBlock(
                    label: '当前阻塞',
                    value: blockers.first.title,
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  '最近上下文',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: secondary,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  lastContext,
                  style: const TextStyle(fontSize: 12.5, height: 1.55),
                ),
                const SizedBox(height: 20),
                Text(
                  '最近相关内容',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: secondary,
                  ),
                ),
                const SizedBox(height: 8),
                if (item.context.notes.isNotEmpty)
                  _ContextRow(
                    icon: FluentIcons.edit_note,
                    title: item.context.notes.first.title,
                    subtitle: '笔记',
                  ),
                if (blockers.isNotEmpty)
                  _ContextRow(
                    icon: FluentIcons.warning,
                    title: blockers.first.title,
                    subtitle: '问题 · 正在排查',
                  ),
                if (item.context.resources.isNotEmpty)
                  _ContextRow(
                    icon: FluentIcons.link,
                    title: item.context.resources.first.name,
                    subtitle: '资源',
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: palette.cardBorder)),
            ),
            child: Row(
              children: [
                Button(
                  onPressed: () {
                    onClose();
                    context.go('/workspace/${item.workspace.id}/overview');
                  },
                  child: const Text('打开工作区'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    final target = _targetRoute();
                    onClose();
                    context.go(target);
                  },
                  child: const Text('开始继续'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final secondary =
        FluentTheme.of(context).typography.body?.color?.withValues(alpha: 0.48);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5),
            ),
          ),
          const SizedBox(width: 10),
          Text(subtitle, style: TextStyle(fontSize: 9.5, color: secondary)),
        ],
      ),
    );
  }
}
