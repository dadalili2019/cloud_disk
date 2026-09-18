import 'package:fluent_ui/fluent_ui.dart';

import '../../theme/theme_controller.dart';
import '../core/models.dart';
import '../workbench_runtime.dart';
import 'workbench_ui.dart';

enum QuickCaptureType { note, task, issue }

class QuickCaptureDrawer extends StatefulWidget {
  const QuickCaptureDrawer({
    super.key,
    this.defaultWorkspace,
    required this.onClose,
    required this.onCaptured,
  });

  final WorkspaceModel? defaultWorkspace;
  final VoidCallback onClose;
  final VoidCallback onCaptured;

  @override
  State<QuickCaptureDrawer> createState() => _QuickCaptureDrawerState();
}

class _QuickCaptureDrawerState extends State<QuickCaptureDrawer> {
  final TextEditingController _controller = TextEditingController();
  QuickCaptureType _type = QuickCaptureType.note;
  WorkspaceModel? _workspace;
  List<WorkspaceModel> _workspaces = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _workspace = widget.defaultWorkspace;
    _loadTargets();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadTargets() async {
    try {
      final runtime = await WorkbenchRuntime.instance;
      final items = await runtime.quickCaptureService.listTargetWorkspaces();
      if (!mounted) return;
      final preferredId = _workspace?.id;
      setState(() {
        _workspaces = items;
        _workspace = items.isEmpty
            ? null
            : items.firstWhere(
                (item) => item.id == preferredId,
                orElse: () => items.first,
              );
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final workspace = _workspace;
    final text = _controller.text.trim();
    if (workspace == null || text.isEmpty || _saving) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final runtime = await WorkbenchRuntime.instance;
      switch (_type) {
        case QuickCaptureType.note:
          await runtime.quickCaptureService.saveAsNote(
            workspaceId: workspace.id,
            text: text,
          );
          break;
        case QuickCaptureType.task:
          await runtime.quickCaptureService.saveAsTask(
            workspaceId: workspace.id,
            text: text,
          );
          break;
        case QuickCaptureType.issue:
          await runtime.quickCaptureService.saveAsIssue(
            workspaceId: workspace.id,
            text: text,
          );
          break;
      }

      if (!mounted) return;
      widget.onCaptured();
      widget.onClose();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final theme = FluentTheme.of(context);
    final secondary = theme.typography.body?.color?.withValues(alpha: 0.55);

    return Container(
      width: 500,
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
                    '快速记录',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(FluentIcons.chrome_close, size: 13),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: ProgressRing())
                : ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      Row(
                        children: [
                          _TypeButton(
                            label: '笔记',
                            selected: _type == QuickCaptureType.note,
                            onPressed: () =>
                                setState(() => _type = QuickCaptureType.note),
                          ),
                          const SizedBox(width: 8),
                          _TypeButton(
                            label: '任务',
                            selected: _type == QuickCaptureType.task,
                            onPressed: () =>
                                setState(() => _type = QuickCaptureType.task),
                          ),
                          const SizedBox(width: 8),
                          _TypeButton(
                            label: '问题',
                            selected: _type == QuickCaptureType.issue,
                            onPressed: () =>
                                setState(() => _type = QuickCaptureType.issue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextBox(
                        controller: _controller,
                        minLines: 7,
                        maxLines: 12,
                        autofocus: true,
                        placeholder: _placeholder(_type),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '关联到',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ComboBox<WorkspaceModel>(
                        value: _workspace,
                        isExpanded: true,
                        placeholder: const Text('选择工作区'),
                        items: _workspaces
                            .map(
                              (workspace) => ComboBoxItem<WorkspaceModel>(
                                value: workspace,
                                child: Text(workspace.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _workspace = value),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _type == QuickCaptureType.task
                            ? '新建任务不会替换当前任务。'
                            : '存在当前任务时，会自动关联当前上下文。',
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.4,
                          color: secondary,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFFFF8F8F),
                          ),
                        ),
                      ],
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
                Text(
                  'Ctrl + Enter 保存',
                  style: TextStyle(fontSize: 9.5, color: secondary),
                ),
                const Spacer(),
                Button(onPressed: widget.onClose, child: const Text('取消')),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: ProgressRing(strokeWidth: 2),
                        )
                      : const Text('保存'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return selected
        ? FilledButton(onPressed: onPressed, child: Text(label))
        : Button(onPressed: onPressed, child: Text(label));
  }
}

String _placeholder(QuickCaptureType type) {
  return switch (type) {
    QuickCaptureType.note => '记录点什么…',
    QuickCaptureType.task => '要做什么？',
    QuickCaptureType.issue => '遇到了什么问题？',
  };
}
