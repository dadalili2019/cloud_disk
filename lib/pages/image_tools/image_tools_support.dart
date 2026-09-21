import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

const supportedImageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'bmp'];

enum ImageOutputFormat { jpg, png }

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
