import '../application/ai_prompt_builder.dart';

abstract interface class AIProvider {
  String get name;

  Future<String> complete(AIPromptPackage prompt);
}
