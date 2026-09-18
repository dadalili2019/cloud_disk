import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../workbench/application/restore_service.dart';
import '../../workbench/workbench_runtime.dart';

class RestorePanel extends StatefulWidget {
  const RestorePanel({super.key, required this.runtime});

  final WorkbenchRuntime runtime;

  @override
  State<RestorePanel> createState() => _RestorePanelState();
}

class _RestorePanelState extends State<RestorePanel> {
  bool _running = false;
  String? _status;
  bool _success = false;

  Future<void> _chooseAndRestore() async {
    if (_running) return;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      allowMultiple: false,
      dialogTitle: '选择 Personal Workbench 备份文件',
    );
    final path = picked?.files.single.path;
    if (path == null || path.trim().isEmpty || !mounted) return;

    setState(() {
      _running = true;
      _status = null;
      _success = false;
    });

    try {
      final file = File(path);
      final validation = await widget.runtime.restoreService.validateBackup(file);
      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => ContentDialog(
          title: const Text('恢复 Personal Workbench'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '恢复会在下次启动时替换当前本地 Workbench 数据。执行前系统会自动创建 Safety Backup。',
                ),
                const SizedBox(height: 12),
                Text('备份文件：${file.path}'),
                const SizedBox(height: 4),
                Text('Schema：v${validation.schemaVersion}'),
                if (validation.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text('创建时间：${_formatDateTime(validation.createdAt!)}'),
                ],
                const SizedBox(height: 12),
                const Text(
                  '当前应用不会立即覆盖正在使用的数据库；确认后将 staging，完全退出并重新打开应用后才会应用恢复。',
                  style: TextStyle(fontWeight: FontWeight.w600),
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
              child: const Text('创建安全备份并准备恢复'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
      final result = await widget.runtime.restoreService.stageRestore(file);
      if (!mounted) return;
      setState(() {
        _success = true;
        _status = '恢复已准备完成。安全备份：${result.safetyBackup.path}\n'
            '请完全关闭 Personal Workbench 后重新打开，恢复会在数据库启动前自动完成。';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _success = false;
        _status = _readableError(error);
      });
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '从 Backup 恢复',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '仅接受 Personal Workbench 备份 ZIP；可移植导出文件不能用于恢复。',
                    style: TextStyle(fontSize: 9.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Button(
              onPressed: _running ? null : _chooseAndRestore,
              child: Text(_running ? '校验中…' : '选择备份并恢复'),
            ),
          ],
        ),
        if (_status != null) ...[
          const SizedBox(height: 10),
          InfoBar(
            title: Text(_success ? '恢复已准备' : '恢复失败'),
            content: SelectableText(_status!),
            severity:
                _success ? InfoBarSeverity.success : InfoBarSeverity.error,
            isLong: true,
          ),
        ],
      ],
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}

String _readableError(Object error) {
  var value = error.toString().trim();
  value = value.replaceFirst(RegExp(r'^(StateError|Exception):\s*'), '');
  if (value.length > 500) value = '${value.substring(0, 500)}…';
  return value;
}
