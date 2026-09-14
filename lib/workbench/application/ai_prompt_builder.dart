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
  const AIPromptBuilder();

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
      history: history,
      userPrompt: message,
    );
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
