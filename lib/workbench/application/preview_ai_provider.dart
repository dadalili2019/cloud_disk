import '../domain/ai_provider.dart';
import 'ai_prompt_builder.dart';

class PreviewAIProvider implements AIProvider {
  const PreviewAIProvider();

  @override
  String get name => 'Preview Provider';

  @override
  Future<String> complete(AIPromptPackage prompt) async {
    final contextLines = prompt.contextBlock
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .length;
    return '''
这是 Phase 5 的 Preview Provider 回复。

已完成本地链路验证：
- 已接收用户问题
- 已接收 Workbench Context
- 已经过 PromptBuilder
- 当前 Context 约 $contextLines 行
- 尚未调用真实模型

你的问题：${prompt.userPrompt}
'''.trim();
  }
}
