import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

import '../../theme/theme_controller.dart';
import '../../workbench/core/workbench_settings.dart';
import '../../workbench/workbench_runtime.dart';
import 'restore_panel.dart';

class DataBackupSection extends StatefulWidget {
  const DataBackupSection({
    super.key,
    required this.runtime,
    required this.settings,
    required this.onSettingsChanged,
  });

  final WorkbenchRuntime runtime;
  final BackupSettings settings;
  final VoidCallback onSettingsChanged;

  @override
  State<DataBackupSection> createState() => _DataBackupSectionState();
}

class _DataBackupSectionState extends State<DataBackupSection> {
  bool _backupRunning = false;
  bool _exportRunning = false;
  String? _success;
  String? _error;

  Future<void> _update(BackupSettings value) async {
    await widget.runtime.settingsService.updateBackup(value);
    widget.onSettingsChanged();
    if (mounted) setState(() {});
  }

  Future<void> _createBackup() async {
    if (_backupRunning || _exportRunning) return;
    setState(() {
      _backupRunning = true;
      _success = null;
      _error = null;
    });
    try {
      final result = await widget.runtime.backupService.createManualBackup();
      if (!mounted) return;
      setState(() {
        _success = '备份完成：${result.file.path}';
      });
      await _showCompletedDialog(
        title: '备份完成',
        description: 'Personal Workbench 备份已创建。',
        path: result.file.path,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _readableError(error));
    } finally {
      if (mounted) setState(() => _backupRunning = false);
    }
  }

  Future<void> _exportAll() async {
    if (_backupRunning || _exportRunning) return;

    final destinationPath = await FilePicker.platform.saveFile(
      dialogTitle: '导出 Personal Workbench 数据',
      fileName: widget.runtime.exportService.suggestedFileName(),
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    if (destinationPath == null || destinationPath.trim().isEmpty) return;

    setState(() {
      _exportRunning = true;
      _success = null;
      _error = null;
    });
    try {
      final result = await widget.runtime.exportService.exportAll(
        includeAttachments: widget.settings.includeAttachmentsInExport,
        destinationPath: destinationPath,
      );
      if (!mounted) return;
      setState(() {
        _success = '导出完成：${result.file.path}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _readableError(error));
    } finally {
      if (mounted) setState(() => _exportRunning = false);
    }
  }

  Future<void> _showCompletedDialog({
    required String title,
    required String description,
    required String path,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final palette = ThemeScope.of(dialogContext).palette;
        return ContentDialog(
          title: Text(title),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(description, style: const TextStyle(fontSize: 11)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.cardBorder),
                  ),
                  child: SelectableText(
                    path,
                    style: const TextStyle(fontSize: 10.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Button(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: path));
              },
              child: const Text('复制路径'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeading(title: '数据与备份'),
        _Group(
          title: '本地数据',
          children: [
            _Row(
              title: '本地数据目录',
              subtitle: 'Personal Workbench 的数据库、Markdown、附件、备份和导出都位于该目录下。',
              control: SizedBox(
                width: 390,
                child: SelectableText(
                  widget.runtime.paths.root.path,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            _Row(
              title: '数据库',
              subtitle: '当前 schema v6；备份时会先生成一致性 SQLite 快照。',
              control: _Badge(widget.runtime.paths.databasePath),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Group(
          title: '备份',
          children: [
            _Row(
              title: '自动备份',
              subtitle: '应用启动时检查是否达到备份周期；不会依赖 Windows Task Scheduler。',
              control: SizedBox(
                width: 230,
                child: ComboBox<BackupFrequency>(
                  value: settings.frequency,
                  isExpanded: true,
                  items: const [
                    ComboBoxItem(
                      value: BackupFrequency.off,
                      child: Text('关闭'),
                    ),
                    ComboBoxItem(
                      value: BackupFrequency.daily,
                      child: Text('每天'),
                    ),
                    ComboBoxItem(
                      value: BackupFrequency.weekly,
                      child: Text('每周'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _update(settings.copyWith(frequency: value));
                    }
                  },
                ),
              ),
            ),
            _Row(
              title: '自动备份保留数量',
              subtitle: '仅清理自动备份；手动备份和安全备份不会自动删除。',
              control: SizedBox(
                width: 230,
                child: NumberBox<int>(
                  value: settings.keepAutoBackups,
                  min: 1,
                  max: 50,
                  mode: SpinButtonPlacementMode.inline,
                  onChanged: (value) {
                    if (value != null) {
                      _update(settings.copyWith(keepAutoBackups: value));
                    }
                  },
                ),
              ),
            ),
            _Row(
              title: '上次自动备份',
              control: _Badge(
                settings.lastAutoBackupAt == null
                    ? '尚未执行'
                    : _formatDateTime(settings.lastAutoBackupAt!),
              ),
            ),
            _Row(
              title: '备份目录',
              control: _Badge(widget.runtime.paths.backupsDirectory.path),
            ),
            _Row(
              title: '立即备份',
              subtitle: '包含 workbench.db 一致性快照、工作区 Markdown、知识、附件与非敏感设置。',
              control: FilledButton(
                onPressed: _backupRunning || _exportRunning ? null : _createBackup,
                child: Text(_backupRunning ? '备份中…' : '创建备份'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Group(
          title: '导出',
          children: [
            _Row(
              title: '导出附件',
              subtitle: '关闭后，可移植导出只包含结构化 JSON 与 Markdown。',
              control: ToggleSwitch(
                checked: settings.includeAttachmentsInExport,
                onChanged: (value) => _update(
                  settings.copyWith(includeAttachmentsInExport: value),
                ),
              ),
            ),
            const _Row(
              title: '导出位置',
              subtitle: '点击“导出”后，通过 Windows“另存为”窗口选择保存目录和文件名。',
              control: _Badge('每次导出时选择'),
            ),
            _Row(
              title: '导出全部数据',
              subtitle: '生成可移植 ZIP：业务数据 JSON + 笔记 / 知识 Markdown；该文件不用于恢复。',
              control: Button(
                onPressed: _backupRunning || _exportRunning ? null : _exportAll,
                child: Text(_exportRunning ? '导出中…' : '导出'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Group(
          title: '恢复',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              child: RestorePanel(runtime: widget.runtime),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          InfoBar(
            title: const Text('数据操作失败'),
            content: Text(_error!),
            severity: InfoBarSeverity.error,
            isLong: true,
          ),
        ],
        if (_success != null) ...[
          const SizedBox(height: 12),
          InfoBar(
            title: const Text('数据操作完成'),
            content: SelectableText(_success!),
            severity: InfoBarSeverity.success,
            isLong: true,
          ),
        ],
        const SizedBox(height: 4),
        Text(
          '备份和导出不包含 API Key、会话 Key 或其他敏感信息。',
          style: TextStyle(
            fontSize: 9.5,
            color: FluentTheme.of(context).typography.body?.color?.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textColor = FluentTheme.of(context).typography.body?.color;
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 10),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: textColor?.withValues(alpha: 0.48),
              ),
            ),
          ),
          Container(height: 1, color: palette.cardBorder),
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Container(height: 1, color: palette.cardBorder),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.control, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final textColor = FluentTheme.of(context).typography.body?.color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final label = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.35,
                    color: textColor?.withValues(alpha: 0.48),
                  ),
                ),
              ],
            ],
          );

          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                label,
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerLeft, child: control),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: label),
              const SizedBox(width: 18),
              control,
            ],
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    return Container(
      constraints: const BoxConstraints(maxWidth: 390),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: palette.cardBorder),
      ),
      child: SelectableText(
        value,
        maxLines: 2,
        style: const TextStyle(fontSize: 10),
      ),
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
  if (value.length > 420) value = '${value.substring(0, 420)}…';
  return value;
}
