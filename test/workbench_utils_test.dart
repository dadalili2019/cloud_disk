import 'package:cloud_disk/workbench/core/workbench_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Workbench file naming', () {
    test('slugifyWorkspace keeps readable Chinese and normalizes separators', () {
      expect(slugifyWorkspace('  我的 项目 / Demo  '), '我的-项目-demo');
    });

    test('normalizeMarkdownFileName removes invalid path characters', () {
      expect(
        normalizeMarkdownFileName(
          '需求/设计:V1?.md',
          fallbackTitle: 'fallback',
        ),
        '需求-设计-V1-.md',
      );
    });

    test('normalizeMarkdownFileName appends markdown extension', () {
      expect(
        normalizeMarkdownFileName('meeting-note', fallbackTitle: 'fallback'),
        'meeting-note.md',
      );
    });
  });

  test('newWorkbenchId returns UUID v4 shape', () {
    final id = newWorkbenchId();
    expect(
      id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });
}
