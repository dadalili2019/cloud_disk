import '../core/ai_conversation_models.dart';
import 'ai_prompt_builder.dart';

List<AIConversationTurn> buildAIConversationHistory(
  List<AIMessageModel> messages, {
  String? excludeTrailingUser,
}) {
  final source = messages
      .where((item) => item.role == 'user' || item.role == 'assistant')
      .toList(growable: false);

  var end = source.length;
  if (excludeTrailingUser != null &&
      source.isNotEmpty &&
      source.last.role == 'user' &&
      source.last.content.trim() == excludeTrailingUser.trim()) {
    end--;
  }

  return source
      .take(end)
      .map(
        (item) => AIConversationTurn(
          role: item.role,
          content: item.content,
        ),
      )
      .toList(growable: false);
}
