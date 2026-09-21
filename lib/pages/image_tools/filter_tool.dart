import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'image_tools_support.dart';

class FilterToolPage extends StatefulWidget {
  const FilterToolPage({super.key});

  @override
  State<FilterToolPage> createState() => _FilterToolPageState();
}


class _FilterToolPageState extends State<FilterToolPage> {
  final List<PlatformFile> _pickedFiles = [];

  ImageOutputFormat _outputFormat = ImageOutputFormat.jpg;
  double _quality = 88;
  double _brightness = 0;
  double _contrast = 1.0;
  bool _grayscale = false;
  bool _sharpen = false;

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
      defaultFolderName: 'offline_filter_output',
    );
  }

  img.Image _apply(img.Image src) {
    var out = src;
    if (_brightness.abs() > 0.001) {
      out = img.adjustColor(out, brightness: _brightness);
    }
    if ((_contrast - 1.0).abs() > 0.001) {
      out = img.adjustColor(out, contrast: _contrast);
    }
    if (_grayscale) out = img.grayscale(out);
    if (_sharpen) out = img.convolution(out, filter: [0, -1, 0, -1, 5, -1, 0, -1, 0]);
    return out;
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
      final decoded = await readImageFile(path);
      if (decoded == null) return;

      final target = resizeImageForPreview(_apply(decoded));
      final preview = encodeImagePreviewPng(target);

      if (!mounted) return;
      setState(() => _previewBytes = preview);
    } finally {
      if (mounted) {
        setState(() => _previewLoading = false);
      }
    }
  }

  Future<void> _runProcess() async {
    if (_pickedFiles.isEmpty || _running) return;
    final outDir = await _resolveOutputDir();
    setState(() {
      _running = true;
      _progress = 0;
      _outputDirPath = outDir.path;
    });

    var success = 0;
    for (var i = 0; i < _pickedFiles.length; i++) {
      final f = _pickedFiles[i];
      final ok = await _processOne(f, outDir);
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
      _status = '处理完成：成功 $success/${_pickedFiles.length}';
    });
  }

  Future<bool> _processOne(PlatformFile f, Directory outDir) async {
    try {
      if (f.path == null) return false;
      final bytes = await File(f.path!).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return false;
      final out = _apply(decoded);
      final outPath = p.join(
        outDir.path,
        '${p.basenameWithoutExtension(f.path!)}_filter.${_outputFormat.extension}',
      );
      final outBytes = _outputFormat.encode(
        out,
        jpgQuality: _quality.round(),
      );
      await File(outPath).writeAsBytes(outBytes, flush: true);
      return true;
    } catch (_) {
      return false;
    }
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
                      : (_previewBytes == null ? const Text('暂无预览') : Image.memory(_previewBytes!, fit: BoxFit.contain)),
                )
              ]
            ]),
          ),
          imageToolCard(context, 
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('2. 参数', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('亮度'),
              Slider(value: _brightness, min: -1, max: 1, divisions: 20, label: _brightness.toStringAsFixed(2), onChanged: _running ? null : (v) { setState(() => _brightness = v); _refreshPreview(); }),
              const Text('对比度'),
              Slider(value: _contrast, min: 0.4, max: 2.0, divisions: 16, label: _contrast.toStringAsFixed(2), onChanged: _running ? null : (v) { setState(() => _contrast = v); _refreshPreview(); }),
              Checkbox(checked: _grayscale, content: const Text('灰度'), onChanged: _running ? null : (v) { setState(() => _grayscale = v ?? false); _refreshPreview(); }),
              Checkbox(checked: _sharpen, content: const Text('锐化'), onChanged: _running ? null : (v) { setState(() => _sharpen = v ?? false); _refreshPreview(); }),
            ]),
          ),
          imageToolCard(context, 
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('3. 导出', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: [
                const Text('格式：'),
                const SizedBox(width: 8),
                ComboBox<ImageOutputFormat>(
                  value: _outputFormat,
                  items: const [
                    ComboBoxItem(value: ImageOutputFormat.jpg, child: Text('JPG')),
                    ComboBoxItem(value: ImageOutputFormat.png, child: Text('PNG')),
                  ],
                  onChanged: _running ? null : (v) => setState(() => _outputFormat = v!),
                ),
              ]),
              const Text('质量（JPG生效）'),
              Slider(value: _quality, min: 40, max: 100, divisions: 12, label: _quality.round().toString(), onChanged: _running ? null : (v) => setState(() => _quality = v)),
              Row(children: [
                FilledButton(onPressed: _running ? null : _pickOutputDir, child: const Text('选择输出目录')),
                const SizedBox(width: 10),
                Expanded(child: Text(_outputDirPath ?? '未设置（默认输出到源目录/offline_filter_output）', overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 10),
              FilledButton(onPressed: (_pickedFiles.isEmpty || _running) ? null : _runProcess, child: Text(_running ? '处理中...' : '开始处理')),
              const SizedBox(height: 10),
              ProgressBar(value: _running ? _progress : (_progress == 0 ? null : _progress)),
              const SizedBox(height: 8),
              Text(_status),
            ]),
          ),
        ],
      ),
    );
  }
}
