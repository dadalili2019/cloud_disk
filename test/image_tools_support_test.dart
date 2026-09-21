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
  });
}
