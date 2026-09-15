import 'dart:convert';
import 'dart:io';

const _compiledBaseUrl = String.fromEnvironment('WORKBENCH_AI_BASE_URL');
const _compiledModel = String.fromEnvironment('WORKBENCH_AI_MODEL');
const _compiledApiKey = String.fromEnvironment('WORKBENCH_AI_API_KEY');
const _compiledChatPath = String.fromEnvironment('WORKBENCH_AI_CHAT_PATH');
const _compiledApiKeyHeader = String.fromEnvironment('WORKBENCH_AI_API_KEY_HEADER');
const _compiledApiKeyPrefix = String.fromEnvironment('WORKBENCH_AI_API_KEY_PREFIX');
const _compiledExtraHeaders = String.fromEnvironment('WORKBENCH_AI_EXTRA_HEADERS_JSON');
const _compiledTimeoutSeconds = String.fromEnvironment('WORKBENCH_AI_TIMEOUT_SECONDS');

class AIProviderConfig {
  const AIProviderConfig({
    required this.baseUrl,
    required this.model,
    this.apiKey = '',
    this.chatPath = '/v1/chat/completions',
    this.apiKeyHeader = 'Authorization',
    this.apiKeyPrefix = 'Bearer',
    this.extraHeaders = const {},
    this.timeoutSeconds = 90,
  });

  final String baseUrl;
  final String model;
  final String apiKey;
  final String chatPath;
  final String apiKeyHeader;
  final String apiKeyPrefix;
  final Map<String, String> extraHeaders;
  final int timeoutSeconds;

  bool get isConfigured => baseUrl.trim().isNotEmpty && model.trim().isNotEmpty;

  static AIProviderConfig fromEnvironment() {
    final baseUrl = _read('WORKBENCH_AI_BASE_URL', _compiledBaseUrl);
    final model = _read('WORKBENCH_AI_MODEL', _compiledModel);
    final apiKey = _read('WORKBENCH_AI_API_KEY', _compiledApiKey);
    final chatPath = _read('WORKBENCH_AI_CHAT_PATH', _compiledChatPath);
    final apiKeyHeader = _read(
      'WORKBENCH_AI_API_KEY_HEADER',
      _compiledApiKeyHeader,
    );
    final apiKeyPrefix = _read(
      'WORKBENCH_AI_API_KEY_PREFIX',
      _compiledApiKeyPrefix,
    );
    final extraHeadersRaw = _read(
      'WORKBENCH_AI_EXTRA_HEADERS_JSON',
      _compiledExtraHeaders,
    );
    final timeoutRaw = _read(
      'WORKBENCH_AI_TIMEOUT_SECONDS',
      _compiledTimeoutSeconds,
    );

    final resolvedHeader = apiKeyHeader.isEmpty ? 'Authorization' : apiKeyHeader;
    final resolvedPrefix = apiKeyPrefix.isNotEmpty
        ? apiKeyPrefix
        : resolvedHeader.toLowerCase() == 'authorization'
            ? 'Bearer'
            : '';

    return AIProviderConfig(
      baseUrl: baseUrl,
      model: model,
      apiKey: apiKey,
      chatPath: chatPath.isEmpty ? '/v1/chat/completions' : chatPath,
      apiKeyHeader: resolvedHeader,
      apiKeyPrefix: resolvedPrefix,
      extraHeaders: _parseHeaders(extraHeadersRaw),
      timeoutSeconds: _parseTimeout(timeoutRaw),
    );
  }

  static String _read(String name, String compiledValue) {
    final runtimeValue = Platform.environment[name]?.trim();
    if (runtimeValue != null && runtimeValue.isNotEmpty) return runtimeValue;
    return compiledValue.trim();
  }

  static Map<String, String> _parseHeaders(String raw) {
    if (raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      final result = <String, String>{};
      for (final entry in decoded.entries) {
        final key = entry.key.toString().trim();
        final value = entry.value?.toString().trim() ?? '';
        if (key.isNotEmpty && value.isNotEmpty) result[key] = value;
      }
      return result;
    } catch (_) {
      return const {};
    }
  }

  static int _parseTimeout(String raw) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null || parsed < 5 || parsed > 600) return 90;
    return parsed;
  }
}
