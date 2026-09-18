import 'package:fluent_ui/fluent_ui.dart';

import '../core/models.dart';
import '../workbench_runtime.dart';
import 'workbench_ui.dart';

class QuickCaptureCard extends StatefulWidget {
  const QuickCaptureCard({
    super.key,
    this.defaultWorkspace,
    required this.onCaptured,
  });

  final WorkspaceModel? defaultWorkspace;
  final VoidCallback onCaptured;

  @override
  State<QuickCaptureCard> createState() => _QuickCaptureCardState();
}

class _QuickCaptureCardState extends State<QuickCaptureCard> {
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<WorkspaceModel?> _resolveWorkspace() async {
    if (widget.defaultWorkspace != null) return widget.defaultWorkspace;

    final runtime = await WorkbenchRuntime.instance;
    final workspaces = await runtime.quickCaptureService.listTargetWorkspaces();
    if (!mounted) return null;

    if (workspaces.isEmpty) {
      await _showMessage('暂无可用工作区，请先创建工作区。');
      return null;
    }

    if (workspaces.length == 1) return workspaces.first;

    return showDialog<WorkspaceModel>(
      context: context,
      builder: (dialogContext) => ContentDialog(
        title: const Text('选择工作区'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: workspaces
                .map(
                  (workspace) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: Button(
                        onPressed: () => Navigator.pop(dialogContext, workspace),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(workspace.name),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Future<void> _capture({required bool asNote}) async {
    final text = _controller.text.trim();
    if (text.isEmpty || _saving) return;

    final workspace = await _resolveWorkspace();
    if (workspace == null || !mounted) return;

    setState(() => _saving = true);
    try {
      final runtime = await WorkbenchRuntime.instance;
      if (asNote) {
        await runtime.quickCaptureService.saveAsNote(
          workspaceId: workspace.id,
          text: text,
        );
      } else {
        await runtime.quickCaptureService.saveAsTask(
          workspaceId: workspace.id,
          text: text,
        );
      }

      if (!mounted) return;
      _controller.clear();
      widget.onCaptured();
      await _showMessage(
        asNote ? '已保存为笔记' : '已保存为任务',
        title: '记录成功',
      );
    } catch (error) {
      if (!mounted) return;
      await _showMessage(error.toString(), title: '保存失败');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showMessage(String message, {String title = '提示'}) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => ContentDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultWorkspace = widget.defaultWorkspace;

    return WorkbenchCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '快速记录',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
              if (defaultWorkspace != null)
                WorkbenchTag(label: defaultWorkspace.name),
            ],
          ),
          const SizedBox(height: 12),
          TextBox(
            controller: _controller,
            minLines: 2,
            maxLines: 4,
            placeholder: '输入任务、想法或临时记录…',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 340;
              final noteButton = Button(
                onPressed: _saving ? null : () => _capture(asNote: true),
                child: const Text('存为笔记'),
              );
              final taskButton = FilledButton(
                onPressed: _saving ? null : () => _capture(asNote: false),
                child: _saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: ProgressRing(strokeWidth: 2),
                      )
                    : const Text('存为任务'),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: double.infinity, child: taskButton),
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: noteButton),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  noteButton,
                  const SizedBox(width: 8),
                  taskButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
