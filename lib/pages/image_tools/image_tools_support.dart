import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

const supportedImageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'bmp'];

enum ImageOutputFormat { jpg, png }

enum ImageWatermarkPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
}

extension ImageOutputFormatX on ImageOutputFormat {
  String get extension => switch (this) {
        ImageOutputFormat.jpg => 'jpg',
        ImageOutputFormat.png => 'png',
      };

  Uint8List encode(
    img.Image image, {
    required int jpgQuality,
    int pngLevel = 6,
  }) {
    return switch (this) {
      ImageOutputFormat.jpg => Uint8List.fromList(
          img.encodeJpg(image, quality: jpgQuality),
        ),
      ImageOutputFormat.png => Uint8List.fromList(
          img.encodePng(image, level: pngLevel),
        ),
    };
  }
}

class ImageTextWatermarkOptions {
  const ImageTextWatermarkOptions({
    required this.text,
    required this.position,
    required this.opacity,
    required this.fontSize,
    required this.red,
    required this.green,
    required this.blue,
  });

  final String text;
  final ImageWatermarkPosition position;
  final double opacity;
  final int fontSize;
  final int red;
  final int green;
  final int blue;
}

class ImageBatchProgress<T> {
  const ImageBatchProgress({
    required this.item,
    required this.index,
    required this.total,
    required this.successCount,
  });

  final T item;
  final int index;
  final int total;
  final int successCount;

  double get fraction => total == 0 ? 0 : index / total;
}

class ImageBatchResult {
  const ImageBatchResult({
    required this.total,
    required this.processedCount,
    required this.successCount,
  });

  final int total;
  final int processedCount;
  final int successCount;

  int get failureCount => processedCount - successCount;
  bool get completed => processedCount == total;
}

Future<List<PlatformFile>?> pickImageFiles() async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: supportedImageExtensions,
  );
  if (result == null) return null;
  return result.files.where((file) => file.path != null).toList(growable: false);
}

Future<String?> pickImageOutputDirectory() async {
  final picked = await FilePicker.platform.getDirectoryPath(
    dialogTitle: '选择输出目录',
  );
  if (picked == null || picked.isEmpty) return null;
  return picked;
}

Future<Directory> resolveImageOutputDirectory({
  required String? selectedPath,
  required String sourcePath,
  required String defaultFolderName,
}) async {
  if (selectedPath != null && selectedPath.isNotEmpty) {
    final custom = Directory(selectedPath);
    if (!custom.existsSync()) {
      custom.createSync(recursive: true);
    }
    return custom;
  }

  final sourceDirectory = Directory(p.dirname(sourcePath));
  final output = Directory(p.join(sourceDirectory.path, defaultFolderName));
  if (!output.existsSync()) {
    output.createSync(recursive: true);
  }
  return output;
}

Future<img.Image?> readImageFile(String path) async {
  final bytes = await File(path).readAsBytes();
  return img.decodeImage(bytes);
}

img.Image resizeImageForPreview(
  img.Image image, {
  int maxEdge = 560,
}) {
  final maxSide = image.width > image.height ? image.width : image.height;
  if (maxSide <= maxEdge) return image;

  final ratio = maxEdge / maxSide;
  return img.copyResize(
    image,
    width: (image.width * ratio).round(),
    height: (image.height * ratio).round(),
    interpolation: img.Interpolation.average,
  );
}

Uint8List encodeImagePreviewPng(
  img.Image image, {
  int level = 4,
}) {
  return Uint8List.fromList(img.encodePng(image, level: level));
}

img.Image applyTextWatermark(
  img.Image target,
  ImageTextWatermarkOptions options,
) {
  final text = options.text.trim();
  if (text.isEmpty) return target;

  final padding = (target.width * 0.015).clamp(8.0, 24.0).round();
  final estimatedWidth = ((text.length * options.fontSize) * 0.6).round();
  final estimatedHeight = (options.fontSize * 1.2).round();

  var x = padding;
  var y = padding;

  switch (options.position) {
    case ImageWatermarkPosition.topLeft:
      break;
    case ImageWatermarkPosition.topRight:
      x = (target.width - estimatedWidth - padding)
          .clamp(0, target.width)
          .toInt();
      break;
    case ImageWatermarkPosition.bottomLeft:
      y = (target.height - estimatedHeight - padding)
          .clamp(0, target.height)
          .toInt();
      break;
    case ImageWatermarkPosition.bottomRight:
      x = (target.width - estimatedWidth - padding)
          .clamp(0, target.width)
          .toInt();
      y = (target.height - estimatedHeight - padding)
          .clamp(0, target.height)
          .toInt();
      break;
    case ImageWatermarkPosition.center:
      x = ((target.width - estimatedWidth) / 2)
          .round()
          .clamp(0, target.width)
          .toInt();
      y = ((target.height - estimatedHeight) / 2)
          .round()
          .clamp(0, target.height)
          .toInt();
      break;
  }

  final alpha = (options.opacity * 255).round().clamp(30, 255).toInt();
  final foreground = img.ColorRgba8(
    options.red,
    options.green,
    options.blue,
    alpha,
  );
  final brightness = (options.red + options.green + options.blue) / 3;
  final shadow = brightness < 128
      ? img.ColorRgba8(
          255,
          255,
          255,
          (alpha * 0.35).round().clamp(20, 180).toInt(),
        )
      : img.ColorRgba8(
          0,
          0,
          0,
          (alpha * 0.45).round().clamp(20, 200).toInt(),
        );

  final font = imageFontForSize(options.fontSize);
  img.drawString(
    target,
    text,
    font: font,
    x: (x + 1).clamp(0, target.width).toInt(),
    y: (y + 1).clamp(0, target.height).toInt(),
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
  return target;
}

img.BitmapFont imageFontForSize(int size) {
  if (size <= 14) return img.arial14;
  if (size <= 24) return img.arial24;
  if (size <= 48) return img.arial48;
  return img.arial24;
}

Future<ImageBatchResult> runImageBatch<T>({
  required List<T> items,
  required Future<bool> Function(T item) process,
  void Function(ImageBatchProgress<T> progress)? onProgress,
  bool Function()? shouldContinue,
}) async {
  var successCount = 0;
  var processedCount = 0;

  for (var i = 0; i < items.length; i++) {
    if (shouldContinue != null && !shouldContinue()) break;

    final item = items[i];
    final succeeded = await process(item);
    if (succeeded) successCount++;
    processedCount++;

    if (shouldContinue == null || shouldContinue()) {
      onProgress?.call(
        ImageBatchProgress(
          item: item,
          index: processedCount,
          total: items.length,
          successCount: successCount,
        ),
      );
    }
  }

  return ImageBatchResult(
    total: items.length,
    processedCount: processedCount,
    successCount: successCount,
  );
}

String formatImageByteSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  final gb = mb / 1024;
  return '${gb.toStringAsFixed(2)} GB';
}

Widget imageToolCard(
  BuildContext context, {
  required Widget child,
}) {
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
