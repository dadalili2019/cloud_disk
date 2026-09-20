import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

class WatermarkToolPage extends StatefulWidget {
  const WatermarkToolPage({super.key});

  @override
  State<WatermarkToolPage> createState() => _WatermarkToolPageState();
}

enum _OutputFormat { jpg, png }
enum _WatermarkPosition { topLeft, topRight, bottomLeft, bottomRight, center }

class _FailedTask {
  const _FailedTask({required this.name, required this.path, required this.reason});

  final String name;
  final String path;
  final String reason;
}

class _WatermarkToolPageState extends State<WatermarkToolPage> {
  final List<PlatformFile> _pickedFiles = [];
  final List<_FailedTask> _failedTasks = [];

  final TextEditingController _watermarkController = TextEditingController(text: 'cloud_disk');
  _WatermarkPosition _watermarkPosition = _WatermarkPosition.bottomRight;
  double _watermarkOpacity = 0.78;
  int _watermarkFontSize = 24;
  int _wmR = 20;
  int _wmG = 20;
  int _wmB = 20;

  _OutputFormat _outputFormat = _OutputFormat.jpg;
  double _quality = 86;

  String? _outputDirPath;
  Uint8List? _previewBytes;
  bool _previewLoading = false;

  bool _running = false;
  double _progress = 0;
  String _status = '请选择图片后添加水印';

  @override
  void dispose() {
    _watermarkController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
    );
    if (result == null) return;

    setState(() {
      _pickedFiles
        ..clear()
        ..addAll(result.files.where((e) => e.path != null));
      _failedTasks.clear();
      _status = '已选择 ${_pickedFiles.length} 张图片';
    });
    _refreshPreview();
  }

  Future<void> _pickOutputDir() async {
    final picked = await FilePicker.platform.getDirectoryPath(dialogTitle: '选择输出目录');
    if (picked == null || picked.isEmpty) return;
    setState(() => _outputDirPath = picked);
  }

  Future<void> _refreshPreview() async {
    if (_pickedFiles.isEmpty) {
      if (!mounted) return;
      setState(() => _previewBytes = null);
      return;
    }

    final path = _pickedFiles.first.path;
    if (path == null) return;

    setState(() => _previewLoading = true);
    try {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return;

      var target = decoded;
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

      target = _applyWatermark(target);
      final out = Uint8List.fromList(img.encodePng(target, level: 4));
      if (!mounted) return;
      setState(() => _previewBytes = out);
    } finally {
      if (mounted) {
        setState(() => _previewLoading = false);
      }
    }
  }

  Future<Directory> _resolveOutputDir() async {
    if (_outputDirPath != null && _outputDirPath!.isNotEmpty) {
      final custom = Directory(_outputDirPath!);
      if (!custom.existsSync()) {
        custom.createSync(recursive: true);
      }
      return custom;
    }

    final firstPath = _pickedFiles.first.path!;
    final sourceDir = Directory(p.dirname(firstPath));
    final outputDir = Directory(p.join(sourceDir.path, 'offline_watermark_output'));
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }
    return outputDir;
  }

  Future<void> _runProcess() async {
    if (_pickedFiles.isEmpty || _running) return;

    final outputDir = await _resolveOutputDir();
    setState(() {
      _running = true;
      _progress = 0;
      _failedTasks.clear();
      _outputDirPath = outputDir.path;
    });

    var success = 0;
    for (var i = 0; i < _pickedFiles.length; i++) {
      final file = _pickedFiles[i];
      final ok = await _processSingle(file, outputDir);
      if (ok) success++;

      if (!mounted) return;
      setState(() {
        _progress = (i + 1) / _pickedFiles.length;
        _status = '处理中 ${i + 1}/${_pickedFiles.length} · ${file.name}';
      });
    }

    if (!mounted) return;
    setState(() {
      _running = false;
      _status = '处理完成：成功 $success/${_pickedFiles.length}，失败 ${_failedTasks.length}';
    });
  }

  Future<void> _retryFailed() async {
    if (_failedTasks.isEmpty || _running) return;

    final outputDir = await _resolveOutputDir();
    final retry = List<_FailedTask>.from(_failedTasks);

    setState(() {
      _running = true;
      _progress = 0;
      _failedTasks.clear();
    });

    var success = 0;
    for (var i = 0; i < retry.length; i++) {
      final item = retry[i];
      final ok = await _processPath(item.path, item.name, outputDir);
      if (ok) success++;

      if (!mounted) return;
      setState(() {
        _progress = (i + 1) / retry.length;
        _status = '重试 ${i + 1}/${retry.length} · ${item.name}';
      });
    }

    if (!mounted) return;
    setState(() {
      _running = false;
      _status = '重试完成：成功 $success/${retry.length}，仍失败 ${_failedTasks.length}';
    });
  }

  Future<bool> _processSingle(PlatformFile f, Directory outputDir) async {
    if (f.path == null) {
      _failedTasks.add(const _FailedTask(name: 'unknown', path: '', reason: '文件路径为空'));
      return false;
    }
    return _processPath(f.path!, f.name, outputDir);
  }

  Future<bool> _processPath(String path, String name, Directory outputDir) async {
    try {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        _failedTasks.add(_FailedTask(name: name, path: path, reason: '无法解析图像'));
        return false;
      }

      final target = _applyWatermark(decoded);
      final ext = _outputFormat == _OutputFormat.jpg ? 'jpg' : 'png';
      final outPath = p.join(outputDir.path, '${p.basenameWithoutExtension(path)}_wm.$ext');

      Uint8List out;
      if (_outputFormat == _OutputFormat.jpg) {
        out = Uint8List.fromList(img.encodeJpg(target, quality: _quality.round()));
      } else {
        out = Uint8List.fromList(img.encodePng(target, level: 6));
      }
      await File(outPath).writeAsBytes(out, flush: true);
      return true;
    } catch (e) {
      _failedTasks.add(_FailedTask(name: name, path: path, reason: e.toString()));
      return false;
    }
  }

  img.Image _applyWatermark(img.Image target) {
    final text = _watermarkController.text.trim();
    if (text.isEmpty) return target;

    final padding = (target.width * 0.015).clamp(8.0, 24.0).round();
    final estimatedW = ((text.length * _watermarkFontSize) * 0.6).round();
    final estimatedH = (_watermarkFontSize * 1.2).round();
    int x = padding;
    int y = padding;

    switch (_watermarkPosition) {
      case _WatermarkPosition.topLeft:
        x = padding;
        y = padding;
        break;
      case _WatermarkPosition.topRight:
        x = (target.width - estimatedW - padding).clamp(0, target.width);
        y = padding;
        break;
      case _WatermarkPosition.bottomLeft:
        x = padding;
        y = (target.height - estimatedH - padding).clamp(0, target.height);
        break;
      case _WatermarkPosition.bottomRight:
        x = (target.width - estimatedW - padding).clamp(0, target.width);
        y = (target.height - estimatedH - padding).clamp(0, target.height);
        break;
      case _WatermarkPosition.center:
        x = ((target.width - estimatedW) / 2).round().clamp(0, target.width);
        y = ((target.height - estimatedH) / 2).round().clamp(0, target.height);
        break;
    }

    final alpha = (_watermarkOpacity * 255).round().clamp(30, 255);
    final foreground = img.ColorRgba8(_wmR, _wmG, _wmB, alpha);
    final brightness = (_wmR + _wmG + _wmB) / 3;
    final shadow = brightness < 128
        ? img.ColorRgba8(255, 255, 255, (alpha * 0.35).round().clamp(20, 180))
        : img.ColorRgba8(0, 0, 0, (alpha * 0.45).round().clamp(20, 200));

    final font = _fontBySize(_watermarkFontSize);
    img.drawString(
      target,
      text,
      font: font,
      x: (x + 1).clamp(0, target.width),
      y: (y + 1).clamp(0, target.height),
      color: shadow,
    );
    img.drawString(target, text, font: font, x: x, y: y, color: foreground);
    return target;
  }

  img.BitmapFont _fontBySize(int size) {
    if (size <= 14) return img.arial14;
    if (size <= 24) return img.arial24;
    if (size <= 48) return img.arial48;
    return img.arial24;
  }

  Widget _colorSwatch(int r, int g, int b) {
    final selected = _wmR == r && _wmG == g && _wmB == b;
    return GestureDetector(
      onTap: _running
          ? null
          : () {
              setState(() {
                _wmR = r;
                _wmG = g;
                _wmB = b;
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
      content: ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        children: [
          _card(
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
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('2. 水印设置', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                TextBox(controller: _watermarkController, placeholder: '输入水印文字', onChanged: (_) => _refreshPreview()),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('位置：'),
                    const SizedBox(width: 8),
                    ComboBox<_WatermarkPosition>(
                      value: _watermarkPosition,
                      items: const [
                        ComboBoxItem(value: _WatermarkPosition.topLeft, child: Text('左上')),
                        ComboBoxItem(value: _WatermarkPosition.topRight, child: Text('右上')),
                        ComboBoxItem(value: _WatermarkPosition.bottomLeft, child: Text('左下')),
                        ComboBoxItem(value: _WatermarkPosition.bottomRight, child: Text('右下')),
                        ComboBoxItem(value: _WatermarkPosition.center, child: Text('居中')),
                      ],
                      onChanged: _running
                          ? null
                          : (v) {
                              setState(() => _watermarkPosition = v!);
                              _refreshPreview();
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('调色盘：'),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        _colorSwatch(20, 20, 20),
                        _colorSwatch(255, 255, 255),
                        _colorSwatch(220, 20, 60),
                        _colorSwatch(30, 144, 255),
                        _colorSwatch(46, 204, 113),
                        _colorSwatch(255, 140, 0),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('RGB：($_wmR, $_wmG, $_wmB)'),
                Slider(
                  value: _wmR.toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  label: 'R=$_wmR',
                  onChanged: _running
                      ? null
                      : (v) {
                          setState(() => _wmR = v.round());
                          _refreshPreview();
                        },
                ),
                Slider(
                  value: _wmG.toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  label: 'G=$_wmG',
                  onChanged: _running
                      ? null
                      : (v) {
                          setState(() => _wmG = v.round());
                          _refreshPreview();
                        },
                ),
                Slider(
                  value: _wmB.toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  label: 'B=$_wmB',
                  onChanged: _running
                      ? null
                      : (v) {
                          setState(() => _wmB = v.round());
                          _refreshPreview();
                        },
                ),
                const Text('透明度：'),
                Slider(
                  value: _watermarkOpacity,
                  min: 0.2,
                  max: 1.0,
                  divisions: 16,
                  label: _watermarkOpacity.toStringAsFixed(2),
                  onChanged: _running
                      ? null
                      : (v) {
                          setState(() => _watermarkOpacity = v);
                          _refreshPreview();
                        },
                ),
                const Text('字号：'),
                Slider(
                  value: _watermarkFontSize.toDouble(),
                  min: 14,
                  max: 48,
                  divisions: 17,
                  label: _watermarkFontSize.toString(),
                  onChanged: _running
                      ? null
                      : (v) {
                          setState(() => _watermarkFontSize = v.round());
                          _refreshPreview();
                        },
                ),
              ],
            ),
          ),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('3. 导出设置', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('输出格式：'),
                    const SizedBox(width: 8),
                    ComboBox<_OutputFormat>(
                      value: _outputFormat,
                      items: const [
                        ComboBoxItem(value: _OutputFormat.jpg, child: Text('JPG')),
                        ComboBoxItem(value: _OutputFormat.png, child: Text('PNG')),
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilledButton(onPressed: _running ? null : _pickOutputDir, child: const Text('选择输出目录')),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _outputDirPath == null ? '未设置（默认输出到源目录/offline_watermark_output）' : _outputDirPath!,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('4. 执行', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilledButton(
                      onPressed: (_pickedFiles.isEmpty || _running) ? null : _runProcess,
                      child: Text(_running ? '处理中...' : '开始处理'),
                    ),
                    const SizedBox(width: 10),
                    Button(
                      onPressed: (_failedTasks.isEmpty || _running) ? null : _retryFailed,
                      child: Text('重试失败项（${_failedTasks.length}）'),
                    ),
                  ],
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
