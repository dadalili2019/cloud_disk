import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

import '../../theme/theme_controller.dart';

class AssistantMarkdown extends StatelessWidget {
  const AssistantMarkdown({
    super.key,
    required this.data,
  });

  final String data;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final blocks = _parseBlocks(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < blocks.length; index++) ...[
          _buildBlock(context, theme, blocks[index]),
          if (index != blocks.length - 1) const SizedBox(height: 9),
        ],
      ],
    );
  }

  Widget _buildBlock(
    BuildContext context,
    FluentThemeData theme,
    _MarkdownBlock block,
  ) {
    switch (block.type) {
      case _BlockType.heading:
        final size = switch (block.level) {
          1 => 16.0,
          2 => 14.5,
          3 => 13.0,
          _ => 12.0,
        };
        return SelectableText.rich(
          TextSpan(
            children: _inlineSpans(
              context,
              block.text,
              theme,
              baseStyle: TextStyle(
                fontSize: size,
                height: 1.38,
                fontWeight: FontWeight.w600,
                color: theme.typography.body?.color,
              ),
            ),
          ),
        );
      case _BlockType.unorderedList:
      case _BlockType.orderedList:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < block.items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        block.type == _BlockType.orderedList
                            ? '${i + 1}.'
                            : '•',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.5,
                          color: theme.typography.body?.color?.withOpacity(0.62),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SelectableText.rich(
                        TextSpan(
                          children: _inlineSpans(
                            context,
                            block.items[i],
                            theme,
                            baseStyle: TextStyle(
                              fontSize: 11.5,
                              height: 1.5,
                              color: theme.typography.body?.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      case _BlockType.code:
        return _CodeBlock(
          code: block.text,
          language: block.language,
        );
      case _BlockType.paragraph:
        return SelectableText.rich(
          TextSpan(
            children: _inlineSpans(
              context,
              block.text,
              theme,
              baseStyle: TextStyle(
                fontSize: 11.5,
                height: 1.55,
                color: theme.typography.body?.color,
              ),
            ),
          ),
        );
    }
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({
    required this.code,
    required this.language,
  });

  final String code;
  final String language;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final palette = ThemeScope.of(context).palette;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 7, 7, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    language.isEmpty ? '代码' : language,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: theme.typography.body?.color?.withOpacity(0.52),
                    ),
                  ),
                ),
                Button(
                  onPressed: () => Clipboard.setData(ClipboardData(text: code)),
                  child: const Text('复制'),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: palette.cardBorder.withOpacity(0.86),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(11),
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 10.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<InlineSpan> _inlineSpans(
  BuildContext context,
  String value,
  FluentThemeData theme, {
  required TextStyle baseStyle,
}) {
  final palette = ThemeScope.of(context).palette;
  final spans = <InlineSpan>[];
  final pattern = RegExp(r'(`[^`]+`|\*\*[^*]+\*\*)');
  var offset = 0;

  for (final match in pattern.allMatches(value)) {
    if (match.start > offset) {
      spans.add(TextSpan(
        text: value.substring(offset, match.start),
        style: baseStyle,
      ));
    }

    final token = match.group(0)!;
    if (token.startsWith('`')) {
      spans.add(TextSpan(
        text: token.substring(1, token.length - 1),
        style: baseStyle.copyWith(
          fontFamily: 'Consolas',
          fontSize: (baseStyle.fontSize ?? 11.5) - 0.5,
          backgroundColor: palette.surfaceMuted,
        ),
      ));
    } else {
      spans.add(TextSpan(
        text: token.substring(2, token.length - 2),
        style: baseStyle.copyWith(fontWeight: FontWeight.w600),
      ));
    }
    offset = match.end;
  }

  if (offset < value.length) {
    spans.add(TextSpan(text: value.substring(offset), style: baseStyle));
  }

  if (spans.isEmpty) {
    spans.add(TextSpan(text: value, style: baseStyle));
  }
  return spans;
}

List<_MarkdownBlock> _parseBlocks(String value) {
  final lines = value.replaceAll('\r\n', '\n').split('\n');
  final blocks = <_MarkdownBlock>[];
  var index = 0;

  while (index < lines.length) {
    final line = lines[index];
    if (line.trim().isEmpty) {
      index++;
      continue;
    }

    if (line.trimLeft().startsWith('```')) {
      final marker = line.trimLeft();
      final language = marker.length > 3 ? marker.substring(3).trim() : '';
      final buffer = StringBuffer();
      index++;
      while (index < lines.length && !lines[index].trimLeft().startsWith('```')) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.write(lines[index]);
        index++;
      }
      if (index < lines.length) index++;
      blocks.add(_MarkdownBlock.code(buffer.toString(), language));
      continue;
    }

    final heading = RegExp(r'^(#{1,4})\s+(.+)$').firstMatch(line.trimLeft());
    if (heading != null) {
      blocks.add(_MarkdownBlock.heading(
        heading.group(2)!.trim(),
        heading.group(1)!.length,
      ));
      index++;
      continue;
    }

    if (RegExp(r'^[-*]\s+').hasMatch(line.trimLeft())) {
      final items = <String>[];
      while (index < lines.length &&
          RegExp(r'^[-*]\s+').hasMatch(lines[index].trimLeft())) {
        items.add(lines[index].trimLeft().replaceFirst(RegExp(r'^[-*]\s+'), ''));
        index++;
      }
      blocks.add(_MarkdownBlock.list(items, ordered: false));
      continue;
    }

    if (RegExp(r'^\d+\.\s+').hasMatch(line.trimLeft())) {
      final items = <String>[];
      while (index < lines.length &&
          RegExp(r'^\d+\.\s+').hasMatch(lines[index].trimLeft())) {
        items.add(
          lines[index].trimLeft().replaceFirst(RegExp(r'^\d+\.\s+'), ''),
        );
        index++;
      }
      blocks.add(_MarkdownBlock.list(items, ordered: true));
      continue;
    }

    final paragraph = <String>[line.trim()];
    index++;
    while (index < lines.length) {
      final next = lines[index];
      final trimmed = next.trimLeft();
      if (next.trim().isEmpty ||
          trimmed.startsWith('```') ||
          RegExp(r'^(#{1,4})\s+').hasMatch(trimmed) ||
          RegExp(r'^[-*]\s+').hasMatch(trimmed) ||
          RegExp(r'^\d+\.\s+').hasMatch(trimmed)) {
        break;
      }
      paragraph.add(next.trim());
      index++;
    }
    blocks.add(_MarkdownBlock.paragraph(paragraph.join(' ')));
  }

  return blocks;
}

enum _BlockType {
  paragraph,
  heading,
  unorderedList,
  orderedList,
  code,
}

class _MarkdownBlock {
  const _MarkdownBlock._({
    required this.type,
    this.text = '',
    this.level = 0,
    this.items = const [],
    this.language = '',
  });

  factory _MarkdownBlock.paragraph(String text) =>
      _MarkdownBlock._(type: _BlockType.paragraph, text: text);

  factory _MarkdownBlock.heading(String text, int level) =>
      _MarkdownBlock._(type: _BlockType.heading, text: text, level: level);

  factory _MarkdownBlock.list(List<String> items, {required bool ordered}) =>
      _MarkdownBlock._(
        type: ordered ? _BlockType.orderedList : _BlockType.unorderedList,
        items: items,
      );

  factory _MarkdownBlock.code(String text, String language) =>
      _MarkdownBlock._(
        type: _BlockType.code,
        text: text,
        language: language,
      );

  final _BlockType type;
  final String text;
  final int level;
  final List<String> items;
  final String language;
}
