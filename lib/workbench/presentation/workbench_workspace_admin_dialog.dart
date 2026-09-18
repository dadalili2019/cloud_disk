import 'package:fluent_ui/fluent_ui.dart';

import '../core/models.dart';
import '../workbench_runtime.dart';

Future<String?> showWorkspaceSettingsDialog(
  BuildContext context,
  WorkspaceModel workspace,
) async {
  final name = TextEditingController(text: workspace.name);
  String? error;
  var saving = false;

  try {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => ContentDialog(
          title: const Text('工作区设置'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('工作区名称', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 7),
                TextBox(controller: name),
                const SizedBox(height: 18),
                const Text('目录标识', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 7),
                SelectableText(workspace.slug, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                Text(
                  '目录标识在当前阶段保持只读，避免移动已有 Markdown 文件。',
                  style: TextStyle(fontSize: 11, color: FluentTheme.of(context).typography.body?.color?.withValues(alpha: 0.50)),
                ),
                if (error != null) ...[
                  const SizedBox(height: 14),
                  Text('操作失败：$error', style: const TextStyle(fontSize: 11)),
                ],
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: FluentTheme.of(context).inactiveColor.withValues(alpha: 0.18)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('归档工作区', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text('数据和 Markdown 文件都会保留，可随时恢复。', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                      Button(
                        onPressed: saving ? null : () => Navigator.pop(dialogContext, 'archive'),
                        child: const Text('归档'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Button(
              onPressed: () => Navigator.pop(dialogContext, 'archived_list'),
              child: const Text('已归档工作区'),
            ),
            Button(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消')),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setState(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        final runtime = await WorkbenchRuntime.instance;
                        await runtime.workspaceAdminService.rename(workspace: workspace, name: name.text);
                        if (dialogContext.mounted) Navigator.pop(dialogContext, 'saved');
                      } catch (e) {
                        setState(() {
                          saving = false;
                          error = e.toString();
                        });
                      }
                    },
              child: Text(saving ? '保存中…' : '保存'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted) return null;

    if (result == 'archive') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => ContentDialog(
          title: const Text('归档工作区'),
          content: Text('确定归档“${workspace.name}”吗？\n\n不会删除任务、笔记、问题、资源、决策或 Markdown 文件。'),
          actions: [
            Button(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('归档')),
          ],
        ),
      );
      if (confirmed == true) {
        final runtime = await WorkbenchRuntime.instance;
        await runtime.workspaceAdminService.archive(workspace);
        return 'archived';
      }
      return null;
    }

    if (result == 'archived_list') {
      await showArchivedWorkspacesDialog(context);
      return null;
    }

    return result == 'saved' ? 'saved' : null;
  } finally {
    name.dispose();
  }
}

Future<void> showArchivedWorkspacesDialog(BuildContext context) async {
  final runtime = await WorkbenchRuntime.instance;
  var archived = await runtime.workspaceAdminService.listArchived();
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => ContentDialog(
        title: const Text('已归档工作区'),
        content: SizedBox(
          width: 540,
          height: 320,
          child: archived.isEmpty
              ? const Center(child: Text('暂无已归档工作区'))
              : ListView.separated(
                  itemCount: archived.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final workspace = archived[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: FluentTheme.of(context).inactiveColor.withValues(alpha: 0.16)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(workspace.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(workspace.slug, style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                          Button(
                            onPressed: () async {
                              await runtime.workspaceAdminService.restore(workspace);
                              archived = await runtime.workspaceAdminService.listArchived();
                              if (context.mounted) setState(() {});
                            },
                            child: const Text('恢复'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('完成')),
        ],
      ),
    ),
  );
}
