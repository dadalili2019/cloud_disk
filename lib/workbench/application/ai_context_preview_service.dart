import '../core/ai_context_models.dart';
import 'ai_context_budget.dart';
import 'ai_context_builder.dart';

class AIContextPreviewService {
  const AIContextPreviewService({
    required this.builder,
    required this.budget,
  });

  final AIContextBuilder builder;
  final AIContextBudget budget;

  Future<AIContextPreviewModel> preview(AIContextRequest request) async {
    final raw = await builder.build(request);
    final applied = budget.apply(raw);

    return AIContextPreviewModel(
      scope: applied.scope,
      anchor: applied.anchor,
      workspace: applied.workspace,
      included: applied.items
          .map(
            (item) => AIContextPreviewItem(
              ref: item.ref,
              priority: item.priority,
              reason: item.reason,
              characterCount: item.characterCount,
              preview: _previewText(item.content),
            ),
          )
          .toList(growable: false),
      excluded: applied.excludedRefs,
      totalCharacters: applied.totalCharacters,
    );
  }
}

String _previewText(String value) {
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= 180) return normalized;
  return '${normalized.substring(0, 180)}…';
}
