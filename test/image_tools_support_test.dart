import 'dart:io';

import 'package:cloud_disk/pages/image_tools/image_tools_support.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

void main() {
  group('Image Tools support', () {
    test('formats byte sizes consistently', () {
      expect(formatImageByteSize(512), '512 B');
      expect(formatImageByteSize(1536), '1.5 KB');
      expect(formatImageByteSize(2 * 1024 * 1024), '2.0 MB');
    });

    test('output format exposes extension and encodes image', () {
      final source = img.Image(width: 2, height: 2);

      expect(ImageOutputFormat.jpg.extension, 'jpg');
      expect(ImageOutputFormat.png.extension, 'png');
      expect(
        ImageOutputFormat.jpg.encode(source, jpgQuality: 80),
        isNotEmpty,
      );
      expect(
        ImageOutputFormat.png.encode(source, jpgQuality: 80),
        isNotEmpty,
      );
    });

    test('resolves default output directory next to source file', () async {
      final temp = await Directory.systemTemp.createTemp(
        'personal_workbench_image_tools_',
      );
      try {
        final source = File(p.join(temp.path, 'photo.png'));
        await source.writeAsBytes(const [1, 2, 3]);

        final output = await resolveImageOutputDirectory(
          selectedPath: null,
          sourcePath: source.path,
          defaultFolderName: 'offline_test_output',
        );

        expect(output.path, p.join(temp.path, 'offline_test_output'));
        expect(await output.exists(), isTrue);
      } finally {
        await temp.delete(recursive: true);
      }
    });

    test('uses selected output directory when configured', () async {
      final temp = await Directory.systemTemp.createTemp(
        'personal_workbench_image_tools_custom_',
      );
      try {
        final source = File(p.join(temp.path, 'photo.png'));
        await source.writeAsBytes(const [1]);
        final selected = p.join(temp.path, 'custom', 'nested');

        final output = await resolveImageOutputDirectory(
          selectedPath: selected,
          sourcePath: source.path,
          defaultFolderName: 'ignored',
        );

        expect(output.path, selected);
        expect(await output.exists(), isTrue);
      } finally {
        await temp.delete(recursive: true);
      }
    });

    test('resizes large preview while keeping aspect ratio', () {
      final source = img.Image(width: 1120, height: 560);

      final resized = resizeImageForPreview(source);

      expect(resized.width, 560);
      expect(resized.height, 280);
    });

    test('keeps small preview dimensions unchanged', () {
      final source = img.Image(width: 320, height: 240);

      final resized = resizeImageForPreview(source);

      expect(resized.width, 320);
      expect(resized.height, 240);
    });

    test('encodes preview as PNG bytes', () {
      final source = img.Image(width: 4, height: 4);

      final bytes = encodeImagePreviewPng(source);

      expect(bytes, isNotEmpty);
      expect(bytes.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
    });

    test('text watermark leaves image unchanged when text is empty', () {
      final source = img.Image(width: 120, height: 80);

      final result = applyTextWatermark(
        source,
        const ImageTextWatermarkOptions(
          text: '   ',
          position: ImageWatermarkPosition.bottomRight,
          opacity: 0.8,
          fontSize: 24,
          red: 20,
          green: 20,
          blue: 20,
        ),
      );

      expect(identical(result, source), isTrue);
    });

    test('text watermark draws content for configured text', () {
      final source = img.Image(width: 240, height: 120);
      img.fill(source, color: img.ColorRgb8(255, 255, 255));
      final before = img.encodePng(source);

      final result = applyTextWatermark(
        source,
        const ImageTextWatermarkOptions(
          text: 'demo',
          position: ImageWatermarkPosition.center,
          opacity: 0.8,
          fontSize: 24,
          red: 20,
          green: 20,
          blue: 20,
        ),
      );
      final after = img.encodePng(result);

      expect(after, isNot(equals(before)));
    });

    test('batch runner reports progress and success count', () async {
      final progress = <ImageBatchProgress<int>>[];

      final result = await runImageBatch<int>(
        items: const [1, 2, 3],
        process: (item) async => item != 2,
        onProgress: progress.add,
      );

      expect(result.total, 3);
      expect(result.processedCount, 3);
      expect(result.successCount, 2);
      expect(result.failureCount, 1);
      expect(result.completed, isTrue);
      expect(progress.map((item) => item.index), [1, 2, 3]);
      expect(progress.last.fraction, 1);
    });

    test('batch runner can stop before processing remaining items', () async {
      var keepRunning = true;
      final processed = <int>[];

      final result = await runImageBatch<int>(
        items: const [1, 2, 3],
        process: (item) async {
          processed.add(item);
          if (item == 1) keepRunning = false;
          return true;
        },
        shouldContinue: () => keepRunning,
      );

      expect(processed, [1]);
      expect(result.processedCount, 1);
      expect(result.successCount, 1);
      expect(result.completed, isFalse);
    });
  });
}
