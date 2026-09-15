import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/ai_provider_config.dart';
import '../domain/ai_provider.dart';
import 'ai_prompt_builder.dart';

class OpenAICompatibleAIProvider implements AIProvider {
  OpenAICompatibleAIProvider({
    required this.config,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final AIProviderConfig config;
  final http.Client _client;

  @override
  String get name => 'OpenAI Compatible · ${config.model}';

  @override
  Future<String> complete(AIPromptPackage prompt) async {
    if (!config.isConfigured) {
      throw StateError('AI provider is not configured.');
    }

    final uri = _endpoint(config.baseUrl, config.chatPath);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...config.extraHeaders,
    };

    if (config.apiKey.trim().isNotEmpty) {
      final prefix = config.apiKeyPrefix.trim();
      headers[config.apiKeyHeader] = prefix.isEmpty
          ? config.apiKey.trim()
          : '$prefix ${config.apiKey.trim()}';
    }

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': [prompt.systemPrompt, prompt.contextBlock]
            .where((value) => value.trim().isNotEmpty)
            .join('\n\n'),
      },
      ...prompt.history
          .where((turn) => const {'user', 'assistant', 'system'}.contains(turn.role))
          .map((turn) => {'role': turn.role, 'content': turn.content}),
      {'role': 'user', 'content': prompt.userPrompt},
    ];

    final body = jsonEncode({
      'model': config.model,
      'messages': messages,
      'stream': false,
    });

    late http.Response response;
    try {
      response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(Duration(seconds: config.timeoutSeconds));
    } on TimeoutException {
      throw StateError(
        'AI request timed out after ${config.timeoutSeconds}s: $uri',
      );
    } catch (error) {
      throw StateError('AI request failed: $error');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'AI provider returned HTTP ${response.statusCode}: '
        '${_shortBody(response.body)}',
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw StateError('AI provider returned invalid JSON.');
    }

    final content = _extractContent(decoded);
    if (content.trim().isEmpty) {
      throw StateError('AI provider returned an empty response.');
    }
    return content.trim();
  }
}

Uri _endpoint(String baseUrl, String chatPath) {
  final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  final path = chatPath.trim().isEmpty
      ? '/v1/chat/completions'
      : chatPath.trim();
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  return Uri.parse('$base$normalizedPath');
}

String _extractContent(Object? decoded) {
  if (decoded is! Map) return '';
  final choices = decoded['choices'];
  if (choices is! List || choices.isEmpty) return '';
  final first = choices.first;
  if (first is! Map) return '';
  final message = first['message'];
  if (message is! Map) return '';
  final content = message['content'];

  if (content is String) return content;

  // Some OpenAI-compatible gateways return multimodal-style content arrays.
  if (content is List) {
    final buffer = StringBuffer();
    for (final item in content) {
      if (item is String) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.write(item);
      } else if (item is Map) {
        final text = item['text'];
        if (text is String && text.trim().isNotEmpty) {
          if (buffer.isNotEmpty) buffer.writeln();
          buffer.write(text);
        }
      }
    }
    return buffer.toString();
  }

  return '';
}

String _shortBody(String value) {
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= 500) return normalized;
  return '${normalized.substring(0, 500)}…';
}
