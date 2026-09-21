import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'image_tools_support.dart';

class CollageToolPage extends StatefulWidget {
  const CollageToolPage({super.key});

  @override
  State<CollageToolPage> createState() => _CollageToolPageState();
}

class _CollageToolPageState extends State<CollageToolPage> {
  final List<PlatformFile> _pickedFiles = [];

  int _columns = 3;
  int _cellSize = 360;
  int _gap = 8;
  int _bgR = 255;
  int _bgG = 255;
  int _bgB = 255;

  String _status = '请选择图片并生成拼图';
  String? _lastOutputPath;
  bool _running = false;

  Future<void> _pickImages() async {
    final files = await pickImageFiles();
    if (files == null) return;

    setState(() {
      _pickedFiles
        ..clear()
        ..addAll(files);
      _status = '已选择 ${_pickedFiles.length} 张图片';
    });
  }

  Future<void> _generate() async {
    if (_pickedFiles.isEmpty || _running) return;

    setState(() => _running = true);
    try {
      final maxCount = _pickedFiles.length.clamp(1, 200);
      final cols = _columns.clamp(1, 8);
      final rows = ((maxCount + cols - 1) / cols).floor();

      final width = cols * _cellSize + (cols + 1) * _gap;
      final height = rows * _cellSize + (rows + 1) * _gap;

      final canvas = img.Image(width: width, height: height, numChannels: 4);
      img.fill(canvas, color: img.ColorRgba8(_bgR, _bgG, _bgB, 255));

      for (var i = 0; i < maxCount; i++) {
        final file = _pickedFiles[i];
        final path = file.path;
        if (path == null) continue;

        final bytes = await File(path).readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded == null) continue;

        final fitted = _fitCenterCrop(decoded, _cellSize, _cellSize);
        final row = (i / cols).floor();
        final col = i % cols;
        final x = _gap + col * (_cellSize + _gap);
        final y = _gap + row * (_cellSize + _gap);

        img.compositeImage(canvas, fitted, dstX: x, dstY: y);
      }

      final firstPath = _pickedFiles.first.path!;
      final sourceDir = Directory(p.dirname(firstPath));
      final outDir = Directory(p.join(sourceDir.path, 'offline_collage_output'));
      if (!outDir.existsSync()) outDir.createSync(recursive: true);

      final ts = DateTime.now().millisecondsSinceEpoch;
      final outPath = p.join(outDir.path, 'collage_$ts.png');
      await File(outPath).writeAsBytes(img.encodePng(canvas, level: 6), flush: true);

      setState(() {
        _lastOutputPath = outPath;
        _status = '拼图生成完成';
      });
    } catch (e) {
      setState(() {
        _status = '生成失败：$e';
      });
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  img.Image _fitCenterCrop(img.Image src, int tw, int th) {
    final targetRatio = tw / th;
    final srcRatio = src.width / src.height;

    img.Image cropped;
    if (srcRatio > targetRatio) {
      final h = src.height;
      final w = (h * targetRatio).round();
      final x = ((src.width - w) / 2).round();
      cropped = img.copyCrop(src, x: x, y: 0, width: w, height: h);
    } else {
      final w = src.width;
      final h = (w / targetRatio).round();
      final y = ((src.height - h) / 2).round();
      cropped = img.copyCrop(src, x: 0, y: y, width: w, height: h);
    }
    return img.copyResize(cropped, width: tw, height: th, interpolation: img.Interpolation.average);
  }

  Widget _colorSwatch(int r, int g, int b) {
    final selected = _bgR == r && _bgG == g && _bgB == b;
    return GestureDetector(
      onTap: _running
          ? null
          : () => setState(() {
                _bgR = r;
                _bgG = g;
                _bgB = b;
              }),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, r, g, b),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey[80],
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }

  ) {
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
      content: ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        children: [
          imageToolCard(context, 
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('1. 选择图片', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(children: [
                FilledButton(onPressed: _running ? null : _pickImages, child: const Text('选择图片')),
                const SizedBox(width: 10),
                Text('已选 ${_pickedFiles.length} 张'),
              ]),
            ]),
          ),
          imageToolCard(context, 
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('2. 布局参数', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(children: [
                const Text('列数：'),
                SizedBox(
                  width: 100,
                  child: NumberBox(
                    value: _columns,
                    min: 1,
                    max: 8,
                    mode: SpinButtonPlacementMode.inline,
                    onChanged: _running
                        ? null
                        : (v) => setState(() => _columns = ((v as num?) ?? 3).toInt()),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('单元尺寸：'),
                SizedBox(
                  width: 120,
                  child: NumberBox(
                    value: _cellSize,
                    min: 120,
                    max: 1200,
                    mode: SpinButtonPlacementMode.inline,
                    onChanged: _running
                        ? null
                        : (v) => setState(() => _cellSize = ((v as num?) ?? 360).toInt()),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                const Text('间距：'),
                SizedBox(
                  width: 100,
                  child: NumberBox(
                    value: _gap,
                    min: 0,
                    max: 64,
                    mode: SpinButtonPlacementMode.inline,
                    onChanged: _running
                        ? null
                        : (v) => setState(() => _gap = ((v as num?) ?? 8).toInt()),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              const Text('背景色：'),
              const SizedBox(height: 6),
              Wrap(spacing: 6, children: [
                _colorSwatch(255, 255, 255),
                _colorSwatch(0, 0, 0),
                _colorSwatch(240, 240, 240),
                _colorSwatch(225, 235, 245),
              ]),
            ]),
          ),
          imageToolCard(context, 
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('3. 生成', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              FilledButton(onPressed: (_pickedFiles.isEmpty || _running) ? null : _generate, child: Text(_running ? '生成中...' : '生成拼图')),
              const SizedBox(height: 10),
              Text(_status),
              if (_lastOutputPath != null) ...[
                const SizedBox(height: 8),
                SelectableText('输出：$_lastOutputPath'),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}
