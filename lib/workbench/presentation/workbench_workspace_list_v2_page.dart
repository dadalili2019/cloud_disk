import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../core/models.dart';
import '../workbench_runtime.dart';
import 'workbench_workspace_admin_dialog.dart';

class WorkbenchWorkspaceListPageV2 extends StatefulWidget {
  const WorkbenchWorkspaceListPageV2({super.key});

  @override
  State<WorkbenchWorkspaceListPageV2> createState() =>
      _WorkbenchWorkspaceListPageV2State();
}

class _WorkbenchWorkspaceListPageV2State
    extends State<WorkbenchWorkspaceListPageV2> {
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

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('工作区'),
        commandBar: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button(
              onPressed: _openArchived,
              child: const Text('已归档工作区'),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: _createWorkspace,
              child: const Text('新建工作区'),
            ),
          ],
        ),
      ),
      content: FutureBuilder<List<WorkspaceModel>>(
        future: _workspaces,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: ProgressRing());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }

          final workspaces = snapshot.data ?? const <WorkspaceModel>[];
          if (workspaces.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '暂无活动工作区',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.typography.body?.color?.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Button(
                        onPressed: _openArchived,
                        child: const Text('查看已归档工作区'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _createWorkspace,
                        child: const Text('新建工作区'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
            itemCount: workspaces.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final workspace = workspaces[index];
              return GestureDetector(
                onTap: () => context.go('/workspace/${workspace.id}/overview'),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.inactiveColor.withOpacity(0.14),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          FluentIcons.open_folder_horizontal,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            workspace.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          workspace.slug,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.typography.body?.color?.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(FluentIcons.chevron_right, size: 12),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
