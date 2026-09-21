import 'package:cloud_disk/workbench/application/ai_conversation_history.dart';
import 'package:cloud_disk/workbench/core/ai_conversation_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildAIConversationHistory', () {
    test('keeps only user and assistant messages in order', () {
      final messages = [
        _message('1', 'system', 'System note', 1),
        _message('2', 'user', 'Question', 2),
        _message('3', 'assistant', 'Answer', 3),
      ];

      final history = buildAIConversationHistory(messages);

      expect(history.map((turn) => turn.role), ['user', 'assistant']);
      expect(history.map((turn) => turn.content), ['Question', 'Answer']);
    });

    test('retry excludes matching trailing user message', () {
      final messages = [
        _message('1', 'user', 'First', 1),
        _message('2', 'assistant', 'Reply', 2),
        _message('3', 'user', '  Retry this  ', 3),
      ];

      final history = buildAIConversationHistory(
        messages,
        excludeTrailingUser: 'Retry this',
      );

      expect(history.map((turn) => turn.content), ['First', 'Reply']);
    });

    test('retry does not remove an older matching user message', () {
      final messages = [
        _message('1', 'user', 'Same', 1),
        _message('2', 'assistant', 'Reply', 2),
        _message('3', 'assistant', 'Latest assistant', 3),
      ];

      final history = buildAIConversationHistory(
        messages,
        excludeTrailingUser: 'Same',
      );

      expect(
        history.map((turn) => turn.content),
        ['Same', 'Reply', 'Latest assistant'],
      );
    });
  });
}

AIMessageModel _message(
  String id,
  String role,
  String content,
  int second,
) {
  return AIMessageModel(
    id: id,
    threadId: 'thread-1',
    role: role,
    content: content,
    contextSnapshotJson: '',
    createdAt: DateTime.utc(2026, 9, 21, 9, 0, second),
  );
}
