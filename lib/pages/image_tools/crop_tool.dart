import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'image_tools_support.dart';

class CropToolPage extends StatefulWidget {
  const CropToolPage({super.key});

  @override
  State<CropToolPage> createState() => _CropToolPageState();
}

enum _CropRatio { original, square, r4x3, r16x9, r3x4, r9x16 }

class _CropToolPageState extends State<CropToolPage> {
  final List<PlatformFile> _pickedFiles = [];

  ImageOutputFormat _outputFormat = ImageOutputFormat.jpg;
  _CropRatio _cropRatio = _CropRatio.original;
  double _quality = 88;

  bool _expandCanvas = false;
  int _canvasWidth = 1920;
  int _canvasHeight = 1080;
  int _bgR = 255;
  int _bgG = 255;
  int _bgB = 255;

  String? _outputDirPath;
  Uint8List? _previewBytes;
  bool _previewLoading = false;

  bool _running = false;
  double _progress = 0;
  String _status = '请选择图片开始处理';

  Future<void> _pickImages() async {
    final files = await pickImageFiles();
    if (files == null) return;

    setState(() {
      _pickedFiles
        ..clear()
        ..addAll(files);
      _status = '已选择 ${_pickedFiles.length} 张图片';
    });
    _refreshPreview();
  }

  Future<void> _pickOutputDir() async {
    final picked = await pickImageOutputDirectory();
    if (picked == null) return;
    setState(() => _outputDirPath = picked);
  }

  Future<Directory> _resolveOutputDir() {
    return resolveImageOutputDirectory(
      selectedPath: _outputDirPath,
      sourcePath: _pickedFiles.first.path!,
      defaultFolderName: 'offline_crop_output',
    );
  }

  Future<void> _refreshPreview() async {
    if (_pickedFiles.isEmpty) {
      if (!mounted) return;
      setState(() => _previewBytes = null);
      return;
    }

    final path = _pickedFiles.first.path;
    if (path == null) return;

    if (!mounted) return;
    setState(() => _previewLoading = true);

    try {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return;

      var target = _applyTransforms(decoded);
      const maxPreviewEdge = 560;
      final maxSide = target.width > target.height ? target.width : target.height;
      if (maxSide > maxPreviewEdge) {
        final ratio = maxPreviewEdge / maxSide;
        target = img.copyResize(
          target,
          width: (target.width * ratio).round(),
          height: (target.height * ratio).round(),
          interpolation: img.Interpolation.average,
        );
      }

      final out = Uint8List.fromList(img.encodePng(target, level: 4));
      if (!mounted) return;
      setState(() => _previewBytes = out);
    } finally {
      if (mounted) {
        setState(() => _previewLoading = false);
      }
    }
  }

  img.Image _applyTransforms(img.Image src) {
    var out = src;

    if (_cropRatio != _CropRatio.original) {
      final ratio = _ratioValue(_cropRatio);
      final current = out.width / out.height;

      int cropW;
      int cropH;
      if (current > ratio) {
        cropH = out.height;
        cropW = (cropH * ratio).round();
      } else {
        cropW = out.width;
        cropH = (cropW / ratio).round();
      }

      final x = ((out.width - cropW) / 2).round().clamp(0, out.width);
      final y = ((out.height - cropH) / 2).round().clamp(0, out.height);
      out = img.copyCrop(out, x: x, y: y, width: cropW, height: cropH);
    }

    if (_expandCanvas) {
      final w = _canvasWidth.clamp(32, 10000);
      final h = _canvasHeight.clamp(32, 10000);
      final canvas = img.Image(width: w, height: h, numChannels: 4);
      img.fill(canvas, color: img.ColorRgba8(_bgR, _bgG, _bgB, 255));

      final x = ((w - out.width) / 2).round();
      final y = ((h - out.height) / 2).round();
      img.compositeImage(canvas, out, dstX: x, dstY: y);
      out = canvas;
    }

    return out;
  }

  double _ratioValue(_CropRatio ratio) {
    switch (ratio) {
      case _CropRatio.original:
        return 1;
      case _CropRatio.square:
        return 1;
      case _CropRatio.r4x3:
        return 4 / 3;
      case _CropRatio.r16x9:
        return 16 / 9;
      case _CropRatio.r3x4:
        return 3 / 4;
      case _CropRatio.r9x16:
        return 9 / 16;
    }
  }

  Future<void> _runProcess() async {
    if (_pickedFiles.isEmpty || _running) return;

    final outputDir = await _resolveOutputDir();
    setState(() {
      _running = true;
      _progress = 0;
      _outputDirPath = outputDir.path;
    });

    var success = 0;
    for (var i = 0; i < _pickedFiles.length; i++) {
      final item = _pickedFiles[i];
      final ok = await _processOne(item, outputDir);
      if (ok) success++;

      if (!mounted) return;
      setState(() {
        _progress = (i + 1) / _pickedFiles.length;
        _status = '处理中 ${i + 1}/${_pickedFiles.length} · ${item.name}';
      });
    }

    if (!mounted) return;
    setState(() {
      _running = false;
      _status = '处理完成：成功 $success/${_pickedFiles.length}';
    });
  }

  Future<bool> _processOne(PlatformFile file, Directory outputDir) async {
    try {
      if (file.path == null) return false;
      final bytes = await File(file.path!).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return false;

      final transformed = _applyTransforms(decoded);
      final outPath = p.join(
        outputDir.path,
        '${p.basenameWithoutExtension(file.path!)}_crop.${_outputFormat.extension}',
      );
      final outBytes = _outputFormat.encode(
        transformed,
        jpgQuality: _quality.round(),
      );
      await File(outPath).writeAsBytes(outBytes, flush: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  Widget _colorSwatch(int r, int g, int b) {
    final selected = _bgR == r && _bgG == g && _bgB == b;
    return GestureDetector(
      onTap: _running
          ? null
          : () {
              setState(() {
                _bgR = r;
                _bgG = g;
                _bgB = b;
              });
              _refreshPreview();
            },
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

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        children: [
          imageToolCard(context, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('1. 选择图片', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilledButton(onPressed: _running ? null : _pickImages, child: const Text('选择图片')),
                    const SizedBox(width: 10),
                    Text('已选 ${_pickedFiles.length} 张'),
                  ],
                ),
                if (_pickedFiles.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('实时预览（首张图片）'),
                  const SizedBox(height: 6),
                  Container(
                    height: 220,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: FluentTheme.of(context).resources.cardBackgroundFillColorSecondary,
                    ),
                    child: _previewLoading
                        ? const ProgressRing()
                        : (_previewBytes == null
                            ? const Text('暂无预览')
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(_previewBytes!, fit: BoxFit.contain),
                              )),
                  ),
                ],
              ],
            ),
          ),
          imageToolCard(context, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('2. 裁剪参数', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('比例：'),
                    const SizedBox(width: 8),
                    ComboBox<_CropRatio>(
                      value: _cropRatio,
                      items: const [
                        ComboBoxItem(value: _CropRatio.original, child: Text('原图比例')),
                        ComboBoxItem(value: _CropRatio.square, child: Text('1:1')),
                        ComboBoxItem(value: _CropRatio.r4x3, child: Text('4:3')),
                        ComboBoxItem(value: _CropRatio.r16x9, child: Text('16:9')),
                        ComboBoxItem(value: _CropRatio.r3x4, child: Text('3:4')),
                        ComboBoxItem(value: _CropRatio.r9x16, child: Text('9:16')),
                      ],
                      onChanged: _running
                          ? null
                          : (v) {
                              setState(() => _cropRatio = v!);
                              _refreshPreview();
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Checkbox(
                  checked: _expandCanvas,
                  content: const Text('扩展画布（居中留白）'),
                  onChanged: _running
                      ? null
                      : (v) {
                          setState(() => _expandCanvas = v ?? false);
                          _refreshPreview();
                        },
                ),
                if (_expandCanvas) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('宽：'),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 110,
                        child: NumberBox(
                          value: _canvasWidth,
                          min: 32,
                          max: 10000,
                          mode: SpinButtonPlacementMode.inline,
                          onChanged: (v) {
                            setState(() => _canvasWidth = (v ?? 1920).round());
                            _refreshPreview();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('高：'),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 110,
                        child: NumberBox(
                          value: _canvasHeight,
                          min: 32,
                          max: 10000,
                          mode: SpinButtonPlacementMode.inline,
                          onChanged: (v) {
                            setState(() => _canvasHeight = (v ?? 1080).round());
                            _refreshPreview();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('背景色：'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      _colorSwatch(255, 255, 255),
                      _colorSwatch(0, 0, 0),
                      _colorSwatch(240, 240, 240),
                      _colorSwatch(30, 30, 30),
                      _colorSwatch(225, 235, 245),
                    ],
                  ),
                ],
              ],
            ),
          ),
          imageToolCard(context, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('3. 导出', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('输出格式：'),
                    const SizedBox(width: 8),
                    ComboBox<ImageOutputFormat>(
                      value: _outputFormat,
                      items: const [
                        ComboBoxItem(value: ImageOutputFormat.jpg, child: Text('JPG')),
                        ComboBoxItem(value: ImageOutputFormat.png, child: Text('PNG')),
                      ],
                      onChanged: _running ? null : (v) => setState(() => _outputFormat = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('质量（JPG生效）：'),
                Slider(
                  value: _quality,
                  min: 40,
                  max: 100,
                  divisions: 12,
                  label: _quality.round().toString(),
                  onChanged: _running ? null : (v) => setState(() => _quality = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton(onPressed: _running ? null : _pickOutputDir, child: const Text('选择输出目录')),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _outputDirPath == null ? '未设置（默认输出到源目录/offline_crop_output）' : _outputDirPath!,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: (_pickedFiles.isEmpty || _running) ? null : _runProcess,
                  child: Text(_running ? '处理中...' : '开始处理'),
                ),
                const SizedBox(height: 12),
                ProgressBar(value: _running ? _progress : (_progress == 0 ? null : _progress)),
                const SizedBox(height: 8),
                Text(_status),
              ],
            ),
          ),
        ],
      ),
    );
  }


}
