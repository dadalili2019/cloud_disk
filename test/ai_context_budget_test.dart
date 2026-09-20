import 'package:cloud_disk/workbench/application/ai_context_budget.dart';
import 'package:cloud_disk/workbench/core/ai_context_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AIContextRef ref(String id) => AIContextRef(
        entityType: 'task',
        entityId: id,
        title: 'Task $id',
      );

  AIContextItem item({
    required String id,
    required int priority,
    required String content,
  }) {
    return AIContextItem(
      ref: ref(id),
      priority: priority,
      reason: 'test',
      content: content,
    );
  }

  AIContextModel context(
    List<AIContextItem> items, {
    List<AIContextRef> excluded = const [],
  }) {
    return AIContextModel(
      scope: AIContextScope.workspace,
      generatedAt: DateTime.utc(2026, 9, 20),
      items: items,
      excludedRefs: excluded,
    );
  }

  group('AIContextBudget', () {
    test('keeps priority zero item even when it exceeds character budget', () {
      final critical = item(
        id: 'critical',
        priority: 0,
        content: '1234567890',
      );
      final normal = item(
        id: 'normal',
        priority: 1,
        content: 'abc',
      );

      final result = const AIContextBudget(
        maxCharacters: 5,
        maxItems: 10,
      ).apply(context([critical, normal]));

      expect(result.items.map((item) => item.ref.entityId), ['critical']);
      expect(result.excludedRefs.map((ref) => ref.entityId), ['normal']);
      expect(result.totalCharacters, 10);
    });

    test('excludes non-critical items that exceed character budget', () {
      final first = item(id: 'first', priority: 1, content: '1234');
      final second = item(id: 'second', priority: 2, content: '5678');

      final result = const AIContextBudget(
        maxCharacters: 6,
        maxItems: 10,
      ).apply(context([first, second]));

      expect(result.items.map((item) => item.ref.entityId), ['first']);
      expect(result.excludedRefs.map((ref) => ref.entityId), ['second']);
      expect(result.totalCharacters, 4);
    });

    test('respects maxItems and records excluded refs', () {
      final items = [
        item(id: '1', priority: 0, content: 'a'),
        item(id: '2', priority: 1, content: 'b'),
        item(id: '3', priority: 2, content: 'c'),
      ];

      final result = const AIContextBudget(
        maxCharacters: 100,
        maxItems: 2,
      ).apply(context(items));

      expect(result.items.map((item) => item.ref.entityId), ['1', '2']);
      expect(result.excludedRefs.map((ref) => ref.entityId), ['3']);
    });

    test('zero budget excludes every item and preserves previous exclusions', () {
      final previous = ref('previous');
      final first = item(id: '1', priority: 0, content: 'a');
      final second = item(id: '2', priority: 1, content: 'b');

      final result = const AIContextBudget(
        maxCharacters: 0,
        maxItems: 10,
      ).apply(context([first, second], excluded: [previous]));

      expect(result.items, isEmpty);
      expect(
        result.excludedRefs.map((ref) => ref.entityId),
        ['previous', '1', '2'],
      );
    });
  });
}
