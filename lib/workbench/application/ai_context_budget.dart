import '../core/ai_context_models.dart';

class AIContextBudget {
  const AIContextBudget({
    this.maxCharacters = 18000,
    this.maxItems = 24,
  });

  final int maxCharacters;
  final int maxItems;

  AIContextModel apply(AIContextModel context) {
    if (maxCharacters <= 0 || maxItems <= 0) {
      return AIContextModel(
        scope: context.scope,
        generatedAt: context.generatedAt,
        anchor: context.anchor,
        workspace: context.workspace,
        items: const [],
        excludedRefs: [
          ...context.excludedRefs,
          ...context.items.map((item) => item.ref),
        ],
      );
    }

    final accepted = <AIContextItem>[];
    final excluded = <AIContextRef>[...context.excludedRefs];
    var characters = 0;

    for (final item in context.items) {
      if (accepted.length >= maxItems) {
        excluded.add(item.ref);
        continue;
      }

      final nextSize = characters + item.characterCount;
      final isCritical = item.priority == 0;

      // P0 context remains deterministic and is retained even when a single
      // critical item is larger than the nominal character budget.
      if (!isCritical && nextSize > maxCharacters) {
        excluded.add(item.ref);
        continue;
      }

      accepted.add(item);
      characters = nextSize;
    }

    return AIContextModel(
      scope: context.scope,
      generatedAt: context.generatedAt,
      anchor: context.anchor,
      workspace: context.workspace,
      items: accepted,
      excludedRefs: excluded,
    );
  }
}
