import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'image_tools_support.dart';

class ImageToolsPage extends StatefulWidget {
  const ImageToolsPage({super.key});

  @override
  State<ImageToolsPage> createState() => _ImageToolsPageState();
}

enum _WatermarkPosition { topLeft, topRight, bottomLeft, bottomRight, center }

class _FailedTask {
  const _FailedTask({required this.name, required this.path, required this.reason});

  final String name;
  final String path;
  final String reason;
}

class _ImageToolsPageState extends State<ImageToolsPage> {
  final List<PlatformFile> _pickedFiles = [];
  final List<_FailedTask> _failedTasks = [];

  ImageOutputFormat _outputFormat = ImageOutputFormat.jpg;
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
  final TextEditingController _watermarkController = TextEditingController(text: 'cloud_disk');

  bool _running = false;
  double _progress = 0;
  String _status = '请选择图片开始处理';

  String? _outputDirPath;
  int _originalBytesTotal = 0;
  int _outputBytesTotal = 0;
  Uint8List? _previewBytes;
  bool _previewLoading = false;

  @override
  void dispose() {
    _watermarkController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await pickImageFiles();
    if (files == null) return;

    final bytesTotal = await _sumOriginalSize(files);

    setState(() {
      _pickedFiles
        ..clear()
        ..addAll(files);
      _failedTasks.clear();
      _originalBytesTotal = bytesTotal;
      _outputBytesTotal = 0;
      _status = '已选择 ${_pickedFiles.length} 张图片';
    });
    _refreshPreview();
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
    final picked = await pickImageOutputDirectory();
    if (picked == null) return;
    setState(() => _outputDirPath = picked);
  }

  Future<void> _refreshPreview() async {
    if (_pickedFiles.isEmpty) {
      if (!mounted) return;
      setState(() => _previewBytes = null);
      return;
    }

    final first = _pickedFiles.first;
    final path = first.path;
    if (path == null) return;

    if (!mounted) return;
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

      target = _applyTransforms(target);
      final out = Uint8List.fromList(img.encodePng(target, level: 4));

      if (!mounted) return;
      setState(() => _previewBytes = out);
    } finally {
      if (mounted) {
        setState(() => _previewLoading = false);
      }
    }
  }

  Future<void> _runProcess() async {
    if (_pickedFiles.isEmpty || _running) return;

    final outputDir = await _resolveOutputDir();
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

  Future<Directory> _resolveOutputDir() {
    return resolveImageOutputDirectory(
      selectedPath: _outputDirPath,
      sourcePath: _pickedFiles.first.path!,
      defaultFolderName: 'offline_image_tools_output',
    );
  }

  Future<bool> _processSingleFile(PlatformFile file, Directory outputDir) async {
    final path = file.path;
    if (path == null) {
      _failedTasks.add(const _FailedTask(name: 'unknown', path: '', reason: '文件路径为空'));
      return false;
    }
    return _processFilePath(path, file.name, outputDir);
  }

  Future<bool> _processFilePath(String path, String displayName, Directory outputDir) async {
    try {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        _failedTasks.add(_FailedTask(name: displayName, path: path, reason: '无法解析图像'));
        return false;
      }

      var target = decoded;
      target = _applyTransforms(target);

      final base = p.basenameWithoutExtension(path);
      final ext = _extFor(_outputFormat);
      final outputPath = p.join(outputDir.path, '${base}_offline.$ext');

      Uint8List outBytes;
      switch (_outputFormat) {
        case ImageOutputFormat.jpg:
          outBytes = Uint8List.fromList(img.encodeJpg(target, quality: _quality.round()));
          break;
        case ImageOutputFormat.png:
          outBytes = Uint8List.fromList(img.encodePng(target, level: 6));
          break;
      }

      await File(outputPath).writeAsBytes(outBytes, flush: true);
      _outputBytesTotal += outBytes.length;
      return true;
    } catch (e) {
      _failedTasks.add(_FailedTask(name: displayName, path: path, reason: e.toString()));
      return false;
    }
  }

  String _extFor(ImageOutputFormat f) {
    switch (f) {
      case ImageOutputFormat.jpg:
        return 'jpg';
      case ImageOutputFormat.png:
        return 'png';
    }
  }

  img.BitmapFont _fontBySize(int size) {
    if (size <= 14) return img.arial14;
    if (size <= 24) return img.arial24;
    if (size <= 48) return img.arial48;
    return img.arial24;
  }

  img.Image _applyTransforms(img.Image source) {
    var target = source;
    if (_resizeEnabled) {
      final maxSide = target.width > target.height ? target.width : target.height;
      if (maxSide > _maxEdge) {
        final ratio = _maxEdge / maxSide;
        final newW = (target.width * ratio).round();
        final newH = (target.height * ratio).round();
        target = img.copyResize(target, width: newW, height: newH, interpolation: img.Interpolation.average);
      }
    }

    if (_grayscaleEnabled) {
      target = img.grayscale(target);
    }

    if (_watermarkEnabled && _watermarkController.text.trim().isNotEmpty) {
      final text = _watermarkController.text.trim();
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
    }
    return target;
  }

  

  @override
  Widget build(BuildContext context) {
    final savedBytes = _originalBytesTotal - _outputBytesTotal;
    final savedRatio = _originalBytesTotal > 0
        ? (savedBytes / _originalBytesTotal * 100).clamp(-999, 999).toStringAsFixed(1)
        : '0.0';

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
                          child: Text('• ${f.name}', overflow: TextOverflow.ellipsis),
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
                const Text('2. 处理参数', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
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
                      : (v) {
                          setState(() => _quality = v);
                          _refreshPreview();
                        },
                ),
                const SizedBox(height: 6),
                Checkbox(
                  checked: _resizeEnabled,
                  content: const Text('开启缩放（限制最长边）'),
                  onChanged: _running
                      ? null
                      : (v) {
                          setState(() => _resizeEnabled = v ?? false);
                          _refreshPreview();
                        },
                ),
                Checkbox(
                  checked: _grayscaleEnabled,
                  content: const Text('应用灰度滤镜'),
                  onChanged: _running
                      ? null
                      : (v) {
                          setState(() => _grayscaleEnabled = v ?? false);
                          _refreshPreview();
                        },
                ),
                Checkbox(
                  checked: _watermarkEnabled,
                  content: const Text('添加文字水印'),
                  onChanged: _running
                      ? null
                      : (v) {
                          setState(() => _watermarkEnabled = v ?? false);
                          _refreshPreview();
                        },
                ),
                if (_watermarkEnabled) ...[
                  const SizedBox(height: 8),
                  TextBox(
                    controller: _watermarkController,
                    placeholder: '输入水印文字',
                    onChanged: (_) => _refreshPreview(),
                  ),
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
                            _refreshPreview();
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
                            _refreshPreview();
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
                            _refreshPreview();
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
                        _outputDirPath == null ? '未设置（默认输出到源目录/offline_image_tools_output）' : _outputDirPath!,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          imageToolCard(context, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('3. 执行与结果', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
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
                const SizedBox(height: 12),
                InfoLabel(
                  label: '体积对比',
                  child: Text(
                    '原始：${formatImageByteSize(_originalBytesTotal)}  →  输出：${formatImageByteSize(_outputBytesTotal)}  （节省 ${formatImageByteSize(savedBytes > 0 ? savedBytes : 0)}，$savedRatio%）',
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
            imageToolCard(context, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('失败列表（${_failedTasks.length}）', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      itemCount: _failedTasks.length,
                      itemBuilder: (_, i) {
                        final f = _failedTasks[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('• ${f.name}  |  ${f.reason}', overflow: TextOverflow.ellipsis),
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
}
