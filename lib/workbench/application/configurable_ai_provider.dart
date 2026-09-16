import '../core/ai_provider_config.dart';
import '../core/workbench_settings.dart';
import '../domain/ai_provider.dart';
import 'ai_prompt_builder.dart';
import 'openai_compatible_ai_provider.dart';
import 'preview_ai_provider.dart';
import 'workbench_settings_service.dart';

class ConfigurableAIProvider implements AIProvider {
  ConfigurableAIProvider({
    required this.settings,
    required this.environmentConfig,
  });

  final WorkbenchSettingsService settings;
  final AIProviderConfig environmentConfig;

  @override
  String get name {
    final ai = settings.current.ai;
    return switch (ai.mode) {
      AIProviderMode.environment => environmentConfig.isConfigured
          ? 'Environment · ${environmentConfig.model}'
          : 'Preview',
      AIProviderMode.preview => 'Preview',
      AIProviderMode.deepseek =>
        'DeepSeek · ${ai.model.trim().isEmpty ? 'unconfigured' : ai.model.trim()}',
      AIProviderMode.openAICompatible =>
        'OpenAI Compatible · ${ai.model.trim().isEmpty ? 'unconfigured' : ai.model.trim()}',
    };
  }

  @override
  Future<String> complete(AIPromptPackage prompt) async {
    final provider = _resolveProvider();
    return provider.complete(prompt);
  }

  Future<String> testConnection() async {
    final provider = _resolveProvider();
    if (provider is PreviewAIProvider) {
      return 'Preview Provider 可用；未发起外部网络请求。';
    }
    final response = await provider.complete(
      const AIPromptPackage(
        systemPrompt: 'You are a connectivity test.',
        contextBlock: '',
        history: [],
        userPrompt: 'Reply with OK only.',
      ),
    );
    return response.trim();
  }

  AIProvider _resolveProvider() {
    final ai = settings.current.ai;
    switch (ai.mode) {
      case AIProviderMode.preview:
        return const PreviewAIProvider();
      case AIProviderMode.environment:
        if (!environmentConfig.isConfigured) return const PreviewAIProvider();
        return OpenAICompatibleAIProvider(config: environmentConfig);
      case AIProviderMode.deepseek:
      case AIProviderMode.openAICompatible:
        final config = _configFromSettings(ai);
        if (!config.isConfigured) {
          throw StateError('请先配置 Base URL 和 Model。');
        }
        return OpenAICompatibleAIProvider(config: config);
    }
  }

  AIProviderConfig _configFromSettings(AISettings ai) {
    final isDeepSeek = ai.mode == AIProviderMode.deepseek;
    final baseUrl = ai.baseUrl.trim().isEmpty && isDeepSeek
        ? 'https://api.deepseek.com'
        : ai.baseUrl.trim();
    final chatPath = ai.chatPath.trim().isEmpty
        ? (isDeepSeek ? '/chat/completions' : '/v1/chat/completions')
        : ai.chatPath.trim();
    final sessionKey = settings.sessionAIKey.trim();
    final fallbackKey = environmentConfig.apiKey.trim();

    return AIProviderConfig(
      baseUrl: baseUrl,
      model: ai.model.trim(),
      apiKey: sessionKey.isNotEmpty ? sessionKey : fallbackKey,
      chatPath: chatPath,
      apiKeyHeader: environmentConfig.apiKeyHeader,
      apiKeyPrefix: environmentConfig.apiKeyPrefix,
      extraHeaders: environmentConfig.extraHeaders,
      timeoutSeconds: ai.timeoutSeconds,
    );
  }
}
