import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';

class DedupeToolPage extends StatefulWidget {
  const DedupeToolPage({super.key});

  @override
  State<DedupeToolPage> createState() => _DedupeToolPageState();
}

class _DedupeItem {
  const _DedupeItem({required this.path, required this.size});
  final String path;
  final int size;
}

class _DedupeToolPageState extends State<DedupeToolPage> {
  final List<String> _imagePaths = [];
  final List<List<_DedupeItem>> _duplicateGroups = [];

  bool _running = false;
  String _status = '请选择图片后开始扫描';
  int _wastedBytes = 0;

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
    );
    if (result == null) return;

    setState(() {
      _imagePaths
        ..clear()
        ..addAll(result.files.where((e) => e.path != null).map((e) => e.path!));
      _duplicateGroups.clear();
      _wastedBytes = 0;
      _status = '已选择 ${_imagePaths.length} 张图片';
    });
  }

  Future<void> _scanDuplicates() async {
    if (_imagePaths.isEmpty || _running) return;

    setState(() {
      _running = true;
      _duplicateGroups.clear();
      _wastedBytes = 0;
      _status = '扫描中...';
    });

    try {
      final sizeMap = <int, List<String>>{};
      for (final path in _imagePaths) {
        final f = File(path);
        if (!await f.exists()) continue;
        final stat = await f.stat();
        sizeMap.putIfAbsent(stat.size, () => []).add(path);
      }

      final groups = <List<_DedupeItem>>[];
      var wasted = 0;

      for (final entry in sizeMap.entries) {
        if (entry.value.length < 2) continue;

        final byFingerprint = <String, List<String>>{};
        for (final path in entry.value) {
          try {
            final fingerprint = await _fingerprint(path);
            byFingerprint.putIfAbsent(fingerprint, () => []).add(path);
          } catch (_) {
            // Ignore unreadable file.
          }
        }

        for (final groupPaths in byFingerprint.values) {
          if (groupPaths.length < 2) continue;
          final group = groupPaths.map((e) => _DedupeItem(path: e, size: entry.key)).toList();
          groups.add(group);
          wasted += entry.key * (group.length - 1);
        }
      }

      setState(() {
        _duplicateGroups
          ..clear()
          ..addAll(groups);
        _wastedBytes = wasted;
        _status = '扫描完成：发现 ${groups.length} 组重复';
      });
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<String> _fingerprint(String path) async {
    final f = File(path);
    final len = await f.length();
    final raf = await f.open();
    try {
      final headSize = len < 2048 ? len : 2048;
      final head = await raf.read(headSize);

      List<int> tail = const [];
      if (len > 4096) {
        await raf.setPosition(len - 2048);
        tail = await raf.read(2048);
      }

      final checksum = _simpleChecksum(head) ^ _simpleChecksum(tail);
      return '$len-$checksum';
    } finally {
      await raf.close();
    }
  }

  int _simpleChecksum(List<int> bytes) {
    var sum = 0;
    for (var i = 0; i < bytes.length; i++) {
      sum = (sum + bytes[i] * (i + 1)) & 0x7fffffff;
    }
    return sum;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }

  Widget _card({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: FluentTheme.of(context).resources.cardBackgroundFillColorDefault,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('去重与清理')),
      content: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('1. 选择图片', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(children: [
                FilledButton(onPressed: _running ? null : _pickImages, child: const Text('选择图片')),
                const SizedBox(width: 10),
                Text('已选 ${_imagePaths.length} 张'),
              ]),
            ]),
          ),
          _card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('2. 扫描重复', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              FilledButton(onPressed: (_imagePaths.isEmpty || _running) ? null : _scanDuplicates, child: Text(_running ? '扫描中...' : '开始扫描')),
              const SizedBox(height: 10),
              Text(_status),
              const SizedBox(height: 6),
              Text('可回收空间（估算）：${_formatSize(_wastedBytes)}'),
            ]),
          ),
          if (_duplicateGroups.isNotEmpty)
            _card(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('3. 重复分组（${_duplicateGroups.length} 组）', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 320,
                  child: ListView.builder(
                    itemCount: _duplicateGroups.length,
                    itemBuilder: (_, i) {
                      final g = _duplicateGroups[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('组 ${i + 1} · ${g.length} 个文件 · 单文件 ${_formatSize(g.first.size)}'),
                            const SizedBox(height: 4),
                            ...g.map((e) => Text('• ${e.path}', overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}
