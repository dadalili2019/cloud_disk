import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../core/models.dart';
import '../workbench_runtime.dart';
import 'workbench_ui.dart';
import 'workbench_workspace_admin_dialog.dart';

class WorkbenchWorkspaceListPage extends StatefulWidget {
  const WorkbenchWorkspaceListPage({super.key});

  @override
  State<WorkbenchWorkspaceListPage> createState() =>
      _WorkbenchWorkspaceListPageState();
}

class _WorkbenchWorkspaceListPageState
    extends State<WorkbenchWorkspaceListPage> {
  late Future<List<WorkspaceModel>> _workspaces;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _workspaces = WorkbenchRuntime.instance.then(
      (runtime) => runtime.workspaceService.listActive(),
    );
  }

  Future<void> _openArchived() async {
    await showArchivedWorkspacesDialog(context);
    if (!mounted) return;
    setState(_reload);
  }

  Future<void> _createWorkspace() async {
    final nameController = TextEditingController();
    final slugController = TextEditingController();

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => ContentDialog(
          title: const Text('新建工作区'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextBox(
                  controller: nameController,
                  placeholder: '工作区名称',
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextBox(
                  controller: slugController,
                  placeholder: '目录标识（可选）',
                ),
              ],
            ),
          ),
          actions: [
            Button(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('创建'),
            ),
          ],
        ),
      );

      if (result != true || !mounted) return;
      final runtime = await WorkbenchRuntime.instance;
      final workspace = await runtime.workspaceService.create(
        name: nameController.text,
        slug: slugController.text,
      );
      if (!mounted) return;
      context.go('/workspace/${workspace.id}/overview');
    } catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => ContentDialog(
          title: const Text('操作失败'),
          content: Text(error.toString()),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    } finally {
      nameController.dispose();
      slugController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return FutureBuilder<List<WorkspaceModel>>(
      future: _workspaces,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const ScaffoldPage(content: Center(child: ProgressRing()));
        }
        if (snapshot.hasError) {
          return ScaffoldPage(
            content: Center(child: Text('加载失败：${snapshot.error}')),
          );
        }

        final workspaces = snapshot.data ?? const <WorkspaceModel>[];

        return WorkbenchPage(
          title: '工作台',
          actions: [
            Button(
              onPressed: _openArchived,
              child: const Text('已归档'),
            ),
            FilledButton(
              onPressed: _createWorkspace,
              child: const Text('新建工作区'),
            ),
          ],
          children: [
            if (workspaces.isEmpty)
              WorkbenchCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '暂无活动工作区',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Button(
                      onPressed: _openArchived,
                      child: const Text('查看归档'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _createWorkspace,
                      child: const Text('新建工作区'),
                    ),
                  ],
                ),
              )
            else ...[

              ...workspaces.map(
                (workspace) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: WorkbenchCard(
                    onTap: () => context.go('/workspace/${workspace.id}/overview'),
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: theme.accentColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            FluentIcons.open_folder_horizontal,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                workspace.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (workspace.slug.trim().isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  workspace.slug,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: theme.typography.body?.color?.withValues(alpha: 0.46),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(FluentIcons.chevron_right, size: 11),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
