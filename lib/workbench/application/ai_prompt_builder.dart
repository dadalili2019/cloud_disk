import '../core/ai_context_models.dart';

class AIConversationTurn {
  const AIConversationTurn({required this.role, required this.content});

  final String role;
  final String content;
}

class AIPromptPackage {
  const AIPromptPackage({
    required this.systemPrompt,
    required this.contextBlock,
    required this.history,
    required this.userPrompt,
  });

  final String systemPrompt;
  final String contextBlock;
  final List<AIConversationTurn> history;
  final String userPrompt;
}

class AIPromptBuilder {
  const AIPromptBuilder({
    this.maxHistoryMessages = 20,
    this.maxHistoryCharacters = 12000,
  });

  /// Roughly the latest 10 user/assistant rounds.
  final int maxHistoryMessages;

  /// Character budget keeps long pasted replies from growing the prompt forever.
  final int maxHistoryCharacters;

  AIPromptPackage build({
    required AIContextModel context,
    required String userMessage,
    List<AIConversationTurn> history = const [],
  }) {
    final message = userMessage.trim();
    if (message.isEmpty) {
      throw ArgumentError.value(userMessage, 'userMessage', 'User message is required.');
    }

    return AIPromptPackage(
      systemPrompt: _systemPrompt(context.scope),
      contextBlock: _contextBlock(context),
      history: _budgetHistory(history),
      userPrompt: message,
    );
  }

  List<AIConversationTurn> _budgetHistory(List<AIConversationTurn> history) {
    if (history.isEmpty || maxHistoryMessages <= 0 || maxHistoryCharacters <= 0) {
      return const [];
    }

    final selected = <AIConversationTurn>[];
    var characters = 0;

    for (var index = history.length - 1; index >= 0; index--) {
      if (selected.length >= maxHistoryMessages) break;

      final turn = history[index];
      final content = turn.content.trim();
      if (content.isEmpty) continue;

      final remaining = maxHistoryCharacters - characters;
      if (remaining <= 0) break;

      if (content.length <= remaining) {
        selected.add(AIConversationTurn(role: turn.role, content: content));
        characters += content.length;
        continue;
      }

      // Keep the most recent part of an oversized turn instead of dropping all
      // recent context just because one message is very large.
      selected.add(
        AIConversationTurn(
          role: turn.role,
          content: '…${content.substring(content.length - remaining)}',
        ),
      );
      characters += remaining;
      break;
    }

    return selected.reversed.toList(growable: false);
  }

  String _systemPrompt(AIContextScope scope) {
    return '''
You are the Personal Workbench assistant.
Use the supplied work context as evidence for the current answer.
Do not invent project facts that are not present in the context or conversation.
If the context is insufficient, say what information is missing.
Do not claim to have executed actions, changed files, updated tasks, or modified local data unless an explicit tool/action layer confirms it.
Prefer concise, actionable answers that preserve the user's current work state.
Current context scope: ${scope.name}.
'''.trim();
  }

  String _contextBlock(AIContextModel context) {
    final buffer = StringBuffer();
    buffer.writeln('WORKBENCH CONTEXT');
    buffer.writeln('Scope: ${context.scope.name}');
    if (context.workspace != null) {
      buffer.writeln('Workspace: ${context.workspace!.name}');
    }
    if (context.anchor != null) {
      buffer.writeln(
        'Anchor: ${context.anchor!.entityType} / ${context.anchor!.title}',
      );
    }

    for (final item in context.items) {
      buffer.writeln();
      buffer.writeln(
        '[P${item.priority}] ${item.ref.entityType.toUpperCase()} — ${item.ref.title}',
      );
      buffer.writeln('Reason: ${item.reason}');
      if (item.content.trim().isNotEmpty) {
        buffer.writeln(item.content.trim());
      }
    }

    return buffer.toString().trim();
  }
}
