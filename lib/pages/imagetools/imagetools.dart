import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

class ImageToolsPage extends StatefulWidget {
  const ImageToolsPage({super.key});

  @override
  State<ImageToolsPage> createState() => _ImageToolsPageState();
}

enum _OutputFormat { jpg, png }
enum _WatermarkPosition { topLeft, topRight, bottomLeft, bottomRight, center }

class _FailedTask {
  const _FailedTask({required this.name, required this.path, required this.reason});

  final String name;
  final String path;
  final String reason;
}

img.BitmapFont _imageToolsFontBySize(int size) {
  if (size <= 14) return img.arial14;
  if (size <= 24) return img.arial24;
  if (size <= 48) return img.arial48;
  return img.arial24;
}

img.Image _applyImageToolsTransforms(
  img.Image source,
  Map<String, dynamic> args,
) {
  var target = source;

  final resizeEnabled = args['resizeEnabled'] as bool? ?? false;
  final maxEdge = args['maxEdge'] as int? ?? 1600;
  if (resizeEnabled) {
    final maxSide = target.width > target.height ? target.width : target.height;
    if (maxSide > maxEdge) {
      final ratio = maxEdge / maxSide;
      target = img.copyResize(
        target,
        width: (target.width * ratio).round(),
        height: (target.height * ratio).round(),
        interpolation: img.Interpolation.average,
      );
    }
  }

  if (args['grayscaleEnabled'] as bool? ?? false) {
    target = img.grayscale(target);
  }

  final watermarkEnabled = args['watermarkEnabled'] as bool? ?? false;
  final text = (args['watermarkText'] as String? ?? '').trim();
  if (watermarkEnabled && text.isNotEmpty) {
    final fontSize = args['watermarkFontSize'] as int? ?? 24;
    final position = args['watermarkPosition'] as int? ?? 3;
    final opacity = args['watermarkOpacity'] as double? ?? 0.78;
    final r = args['wmR'] as int? ?? 20;
    final g = args['wmG'] as int? ?? 20;
    final b = args['wmB'] as int? ?? 20;

    final padding = (target.width * 0.015).clamp(8.0, 24.0).round();
    final estimatedW = ((text.length * fontSize) * 0.6).round();
    final estimatedH = (fontSize * 1.2).round();
    var x = padding;
    var y = padding;

    switch (position) {
      case 0:
        x = padding;
        y = padding;
        break;
      case 1:
        x = (target.width - estimatedW - padding).clamp(0, target.width);
        y = padding;
        break;
      case 2:
        x = padding;
        y = (target.height - estimatedH - padding).clamp(0, target.height);
        break;
      case 4:
        x = ((target.width - estimatedW) / 2).round().clamp(0, target.width);
        y = ((target.height - estimatedH) / 2).round().clamp(0, target.height);
        break;
      case 3:
      default:
        x = (target.width - estimatedW - padding).clamp(0, target.width);
        y = (target.height - estimatedH - padding).clamp(0, target.height);
        break;
    }

    final alpha = (opacity * 255).round().clamp(30, 255);
    final foreground = img.ColorRgba8(r, g, b, alpha);
    final brightness = (r + g + b) / 3;
    final shadow = brightness < 128
        ? img.ColorRgba8(
            255,
            255,
            255,
            (alpha * 0.35).round().clamp(20, 180),
          )
        : img.ColorRgba8(
            0,
            0,
            0,
            (alpha * 0.45).round().clamp(20, 200),
          );

    final font = _imageToolsFontBySize(fontSize);
    img.drawString(
      target,
      text,
      font: font,
      x: (x + 1).clamp(0, target.width),
      y: (y + 1).clamp(0, target.height),
      color: shadow,
    );
    img.drawString(
      target,
      text,
      font: font,
      x: x,
      y: y,
      color: foreground,
    );
  }

  return target;
}

Future<Uint8List?> _buildImageToolsPreview(Map<String, dynamic> args) async {
  final path = args['path'] as String?;
  if (path == null || path.isEmpty) return null;

  final bytes = await File(path).readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

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

  target = _applyImageToolsTransforms(target, args);
  return Uint8List.fromList(img.encodePng(target, level: 4));
}

Future<Map<String, dynamic>> _processImageToolsFile(
  Map<String, dynamic> args,
) async {
  final path = args['path'] as String;
  final outputDirPath = args['outputDirPath'] as String;
  final outputFormat = args['outputFormat'] as int? ?? 0;
  final quality = (args['quality'] as num? ?? 82).round();

  try {
    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return <String, dynamic>{
        'ok': false,
        'reason': '无法解析图像',
        'outputBytes': 0,
      };
    }

    final target = _applyImageToolsTransforms(decoded, args);
    final base = p.basenameWithoutExtension(path);
    final ext = outputFormat == 0 ? 'jpg' : 'png';
    final outputPath = p.join(outputDirPath, '${base}_offline.$ext');

    late Uint8List outBytes;
    if (outputFormat == 0) {
      outBytes = Uint8List.fromList(img.encodeJpg(target, quality: quality));
    } else {
      outBytes = Uint8List.fromList(img.encodePng(target, level: 6));
    }

    await File(outputPath).writeAsBytes(outBytes, flush: true);
    return <String, dynamic>{
      'ok': true,
      'reason': '',
      'outputBytes': outBytes.length,
    };
  } catch (e) {
    return <String, dynamic>{
      'ok': false,
      'reason': e.toString(),
      'outputBytes': 0,
    };
  }
}

class _ImageToolsPageState extends State<ImageToolsPage> {
  final List<PlatformFile> _pickedFiles = [];
  final List<_FailedTask> _failedTasks = [];

  _OutputFormat _outputFormat = _OutputFormat.jpg;
  double _quality = 82;
  bool _resizeEnabled = false;
  bool _grayscaleEnabled = false;
  bool _watermarkEnabled = false;
  _WatermarkPosition _watermarkPosition = _WatermarkPosition.bottomRight;
  double _watermarkOpacity = 0.78;
  int _watermarkFontSize = 24;
  int _wmR = 20;
  int _wmG = 20;
  int _wmB = 20;
  int _maxEdge = 1600;
  final TextEditingController _watermarkController =
      TextEditingController(text: 'cloud_disk');

  bool _running = false;
  double _progress = 0;
  String _status = '请选择图片开始处理';

  String? _outputDirPath;
  int _originalBytesTotal = 0;
  int _outputBytesTotal = 0;
  Uint8List? _previewBytes;
  bool _previewLoading = false;

  Timer? _previewDebounce;
  int _previewRequestId = 0;

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _watermarkController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _processingArgs() {
    return <String, dynamic>{
      'outputFormat': _outputFormat.index,
      'quality': _quality,
      'resizeEnabled': _resizeEnabled,
      'grayscaleEnabled': _grayscaleEnabled,
      'watermarkEnabled': _watermarkEnabled,
      'watermarkPosition': _watermarkPosition.index,
      'watermarkOpacity': _watermarkOpacity,
      'watermarkFontSize': _watermarkFontSize,
      'wmR': _wmR,
      'wmG': _wmG,
      'wmB': _wmB,
      'maxEdge': _maxEdge,
      'watermarkText': _watermarkController.text,
    };
  }

  void _schedulePreview({Duration delay = const Duration(milliseconds: 250)}) {
    _previewDebounce?.cancel();
    final requestId = ++_previewRequestId;
    _previewDebounce = Timer(delay, () => _refreshPreview(requestId));
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
    );
    if (result == null) return;

    final files = result.files.where((e) => e.path != null).toList();
    final bytesTotal = await _sumOriginalSize(files);

    if (!mounted) return;
    setState(() {
      _pickedFiles
        ..clear()
        ..addAll(files);
      _failedTasks.clear();
      _originalBytesTotal = bytesTotal;
      _outputBytesTotal = 0;
      _status = '已选择 ${_pickedFiles.length} 张图片';
    });
    _schedulePreview(delay: Duration.zero);
  }

  Future<int> _sumOriginalSize(List<PlatformFile> files) async {
    var sum = 0;
    for (final f in files) {
      final path = f.path;
      if (path == null) continue;
      try {
        final stat = await File(path).stat();
        sum += stat.size;
      } catch (_) {
        // Ignore size failures for individual files.
      }
    }
    return sum;
  }

  Future<void> _pickOutputDir() async {
    final picked = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择输出目录',
    );
    if (picked == null || picked.isEmpty) return;
    if (!mounted) return;
    setState(() => _outputDirPath = picked);
  }

  Future<void> _refreshPreview(int requestId) async {
    if (_pickedFiles.isEmpty) {
      if (!mounted) return;
      setState(() => _previewBytes = null);
      return;
    }

    final path = _pickedFiles.first.path;
    if (path == null) return;

    if (!mounted || requestId != _previewRequestId) return;
    setState(() => _previewLoading = true);

    final args = <String, dynamic>{
      ..._processingArgs(),
      'path': path,
    };

    try {
      final out = await compute(_buildImageToolsPreview, args);
      if (!mounted || requestId != _previewRequestId) return;
      setState(() => _previewBytes = out);
    } catch (_) {
      if (!mounted || requestId != _previewRequestId) return;
      setState(() => _previewBytes = null);
    } finally {
      if (mounted && requestId == _previewRequestId) {
        setState(() => _previewLoading = false);
      }
    }
  }

  Future<void> _runProcess() async {
    if (_pickedFiles.isEmpty || _running) return;

    final outputDir = await _resolveOutputDir();
    if (!mounted) return;
    setState(() {
      _running = true;
      _progress = 0;
      _failedTasks.clear();
      _outputBytesTotal = 0;
      _outputDirPath = outputDir.path;
    });

    var success = 0;

    for (var i = 0; i < _pickedFiles.length; i++) {
      final f = _pickedFiles[i];
      final ok = await _processSingleFile(f, outputDir);
      if (ok) success++;

      if (!mounted) return;
      setState(() {
        _progress = (i + 1) / _pickedFiles.length;
        _status = '处理中 ${i + 1}/${_pickedFiles.length} · ${f.name}';
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
    final retryItems = List<_FailedTask>.from(_failedTasks);

    if (!mounted) return;
    setState(() {
      _running = true;
      _progress = 0;
      _failedTasks.clear();
      _status = '开始重试失败项...';
    });

    var success = 0;
    for (var i = 0; i < retryItems.length; i++) {
      final t = retryItems[i];
      final ok = await _processFilePath(t.path, t.name, outputDir);
      if (ok) success++;

      if (!mounted) return;
      setState(() {
        _progress = (i + 1) / retryItems.length;
        _status = '重试 ${i + 1}/${retryItems.length} · ${t.name}';
      });
    }

    if (!mounted) return;
    setState(() {
      _running = false;
      _status = '重试完成：成功 $success/${retryItems.length}，仍失败 ${_failedTasks.length}';
    });
  }

  Future<Directory> _resolveOutputDir() async {
    if (_outputDirPath != null && _outputDirPath!.isNotEmpty) {
      final custom = Directory(_outputDirPath!);
      if (!await custom.exists()) {
        await custom.create(recursive: true);
      }
      return custom;
    }

    final firstPath = _pickedFiles.first.path!;
    final sourceDir = Directory(p.dirname(firstPath));
    final outputDir =
        Directory(p.join(sourceDir.path, 'offline_image_tools_output'));
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    return outputDir;
  }

  Future<bool> _processSingleFile(
    PlatformFile file,
    Directory outputDir,
  ) async {
    final path = file.path;
    if (path == null) {
      _failedTasks.add(
        const _FailedTask(name: 'unknown', path: '', reason: '文件路径为空'),
      );
      return false;
    }
    return _processFilePath(path, file.name, outputDir);
  }

  Future<bool> _processFilePath(
    String path,
    String displayName,
    Directory outputDir,
  ) async {
    final args = <String, dynamic>{
      ..._processingArgs(),
      'path': path,
      'outputDirPath': outputDir.path,
    };

    final result = await compute(_processImageToolsFile, args);
    final ok = result['ok'] as bool? ?? false;
    if (ok) {
      _outputBytesTotal += result['outputBytes'] as int? ?? 0;
      return true;
    }

    _failedTasks.add(
      _FailedTask(
        name: displayName,
        path: path,
        reason: result['reason']?.toString() ?? '未知错误',
      ),
    );
    return false;
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

  @override
  Widget build(BuildContext context) {
    final savedBytes = _originalBytesTotal - _outputBytesTotal;
    final savedRatio = _originalBytesTotal > 0
        ? (savedBytes / _originalBytesTotal * 100)
            .clamp(-999, 999)
            .toStringAsFixed(1)
        : '0.0';

    return ScaffoldPage(
      header: const PageHeader(title: Text('批量转换')),
      content: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. 选择图片',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilledButton(
                      onPressed: _running ? null : _pickImages,
                      child: const Text('选择图片'),
                    ),
                    const SizedBox(width: 10),
                    Text('已选 ${_pickedFiles.length} 张'),
                  ],
                ),
                if (_pickedFiles.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      itemCount: _pickedFiles.length,
                      itemBuilder: (_, i) {
                        final f = _pickedFiles[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• ${f.name}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('实时预览（首张图片）'),
                  const SizedBox(height: 6),
                  Container(
                    height: 220,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: FluentTheme.of(context)
                          .resources
                          .cardBackgroundFillColorSecondary,
                    ),
                    child: _previewLoading
                        ? const ProgressRing()
                        : (_previewBytes == null
                            ? const Text('暂无预览')
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(
                                  _previewBytes!,
                                  fit: BoxFit.contain,
                                ),
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
                const Text(
                  '2. 处理参数',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('输出格式：'),
                    const SizedBox(width: 8),
                    ComboBox<_OutputFormat>(
                      value: _outputFormat,
                      items: const [
                        ComboBoxItem(
                          value: _OutputFormat.jpg,
                          child: Text('JPG'),
                        ),
                        ComboBoxItem(
                          value: _OutputFormat.png,
                          child: Text('PNG'),
                        ),
                      ],
                      onChanged: _running
                          ? null
                          : (v) => setState(() => _outputFormat = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('质量（JPG生效）：'),
                Slider(
                  value: _quality,
                  min: 40,
                  max: 100,
                  divisions: 12,
                  label: _quality.round().toString(),
                  onChanged: _running
                      ? null
                      : (v) => setState(() => _quality = v),
                ),
                const SizedBox(height: 6),
                Checkbox(
                  checked: _resizeEnabled,
                  content: const Text('开启缩放（限制最长边）'),
                  onChanged: _running
                      ? null
                      : (v) {
                          setState(() => _resizeEnabled = v ?? false);
                          _schedulePreview();
                        },
                ),
                Checkbox(
                  checked: _grayscaleEnabled,
                  content: const Text('应用灰度滤镜'),
                  onChanged: _running
                      ? null
                      : (v) {
                          setState(() => _grayscaleEnabled = v ?? false);
                          _schedulePreview();
                        },
                ),
                Checkbox(
                  checked: _watermarkEnabled,
                  content: const Text('添加文字水印'),
                  onChanged: _running
                      ? null
                      : (v) {
                          setState(() => _watermarkEnabled = v ?? false);
                          _schedulePreview();
                        },
                ),
                if (_watermarkEnabled) ...[
                  const SizedBox(height: 8),
                  TextBox(
                    controller: _watermarkController,
                    placeholder: '输入水印文字',
                    onChanged: (_) => _schedulePreview(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('位置：'),
                      const SizedBox(width: 8),
                      ComboBox<_WatermarkPosition>(
                        value: _watermarkPosition,
                        items: const [
                          ComboBoxItem(
                            value: _WatermarkPosition.topLeft,
                            child: Text('左上'),
                          ),
                          ComboBoxItem(
                            value: _WatermarkPosition.topRight,
                            child: Text('右上'),
                          ),
                          ComboBoxItem(
                            value: _WatermarkPosition.bottomLeft,
                            child: Text('左下'),
                          ),
                          ComboBoxItem(
                            value: _WatermarkPosition.bottomRight,
                            child: Text('右下'),
                          ),
                          ComboBoxItem(
                            value: _WatermarkPosition.center,
                            child: Text('居中'),
                          ),
                        ],
                        onChanged: _running
                            ? null
                            : (v) {
                                setState(() => _watermarkPosition = v!);
                                _schedulePreview();
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
                            _schedulePreview();
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
                            _schedulePreview();
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
                            _schedulePreview();
                          },
                  ),
                  const SizedBox(height: 8),
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
                            _schedulePreview();
                          },
                  ),
                  const SizedBox(height: 8),
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
                            _schedulePreview();
                          },
                  ),
                ],
                if (_resizeEnabled) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('最长边：'),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: NumberBox(
                          value: _maxEdge,
                          min: 320,
                          max: 4096,
                          mode: SpinButtonPlacementMode.inline,
                          onChanged: (v) {
                            setState(() => _maxEdge = (v ?? 1600).round());
                            _schedulePreview();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton(
                      onPressed: _running ? null : _pickOutputDir,
                      child: const Text('选择输出目录'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _outputDirPath == null
                            ? '未设置（默认输出到源目录/offline_image_tools_output）'
                            : _outputDirPath!,
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
                const Text(
                  '3. 执行与结果',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilledButton(
                      onPressed:
                          (_pickedFiles.isEmpty || _running) ? null : _runProcess,
                      child: Text(_running ? '处理中...' : '开始处理'),
                    ),
                    const SizedBox(width: 10),
                    Button(
                      onPressed:
                          (_failedTasks.isEmpty || _running) ? null : _retryFailed,
                      child: Text('重试失败项（${_failedTasks.length}）'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ProgressBar(
                  value: _running
                      ? _progress
                      : (_progress == 0 ? null : _progress),
                ),
                const SizedBox(height: 8),
                Text(_status),
                const SizedBox(height: 12),
                InfoLabel(
                  label: '体积对比',
                  child: Text(
                    '原始：${_formatSize(_originalBytesTotal)}  →  输出：${_formatSize(_outputBytesTotal)}  （节省 ${_formatSize(savedBytes > 0 ? savedBytes : 0)}，$savedRatio%）',
                  ),
                ),
                if (_outputDirPath != null) ...[
                  const SizedBox(height: 8),
                  SelectableText('输出目录：$_outputDirPath'),
                ],
              ],
            ),
          ),
          if (_failedTasks.isNotEmpty)
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '失败列表（${_failedTasks.length}）',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      itemCount: _failedTasks.length,
                      itemBuilder: (_, i) {
                        final f = _failedTasks[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '• ${f.name}  |  ${f.reason}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
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
              _schedulePreview();
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
}
