import 'dart:async';
import 'dart:convert';

import 'package:cloud_disk/workbench/application/ai_prompt_builder.dart';
import 'package:cloud_disk/workbench/application/openai_compatible_ai_provider.dart';
import 'package:cloud_disk/workbench/core/ai_provider_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('OpenAICompatibleAIProvider', () {
    test('rejects unconfigured provider before network request', () async {
      var called = false;
      final provider = OpenAICompatibleAIProvider(
        config: _config(baseUrl: '', model: ''),
        client: MockClient((request) async {
          called = true;
          return http.Response('{}', 200);
        }),
      );

      await expectLater(
        provider.complete(_prompt()),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'AI provider is not configured.',
          ),
        ),
      );
      expect(called, isFalse);
    });

    test('builds endpoint headers and filtered messages correctly', () async {
      late http.Request captured;
      final provider = OpenAICompatibleAIProvider(
        config: _config(
          baseUrl: 'https://example.test/api/',
          model: 'model-x',
          apiKey: 'secret',
          chatPath: 'chat/completions',
          extraHeaders: const {'X-Trace': 'trace-1'},
        ),
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': '  OK  '},
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final result = await provider.complete(
        const AIPromptPackage(
          systemPrompt: 'System',
          contextBlock: 'Context',
          history: [
            AIConversationTurn(role: 'user', content: 'Earlier question'),
            AIConversationTurn(role: 'tool', content: 'Ignored tool message'),
            AIConversationTurn(role: 'assistant', content: 'Earlier answer'),
          ],
          userPrompt: 'Current question',
        ),
      );

      expect(result, 'OK');
      expect(captured.url.toString(), 'https://example.test/api/chat/completions');
      expect(captured.headers['Authorization'], 'Bearer secret');
      expect(captured.headers['X-Trace'], 'trace-1');
      expect(captured.headers['Content-Type'], contains('application/json'));

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['model'], 'model-x');
      expect(body['stream'], isFalse);
      final messages = (body['messages'] as List)
          .cast<Map<String, dynamic>>();
      expect(messages, hasLength(4));
      expect(messages[0], {
        'role': 'system',
        'content': 'System\n\nContext',
      });
      expect(messages[1]['role'], 'user');
      expect(messages[2]['role'], 'assistant');
      expect(messages[3], {
        'role': 'user',
        'content': 'Current question',
      });
    });

    test('converts timeout into readable StateError', () async {
      final provider = OpenAICompatibleAIProvider(
        config: _config(timeoutSeconds: 1),
        client: _NeverClient(),
      );

      await expectLater(
        provider.complete(_prompt()),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('AI request timed out after 1s'),
          ),
        ),
      );
    });

    test('wraps network errors without exposing them as raw exceptions', () async {
      final provider = OpenAICompatibleAIProvider(
        config: _config(),
        client: MockClient((request) async {
          throw Exception('network down');
        }),
      );

      await expectLater(
        provider.complete(_prompt()),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('AI request failed: Exception: network down'),
          ),
        ),
      );
    });

    test('reports HTTP errors and limits provider body in error message', () async {
      final body = 'x' * 800;
      final provider = OpenAICompatibleAIProvider(
        config: _config(),
        client: MockClient((request) async => http.Response(body, 503)),
      );

      await expectLater(
        provider.complete(_prompt()),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('HTTP 503'),
              isNot(contains('x' * 600)),
            ),
          ),
        ),
      );
    });

    test('rejects invalid JSON', () async {
      final provider = OpenAICompatibleAIProvider(
        config: _config(),
        client: MockClient(
          (request) async => http.Response('not-json', 200),
        ),
      );

      await expectLater(
        provider.complete(_prompt()),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'AI provider returned invalid JSON.',
          ),
        ),
      );
    });

    test('rejects structurally valid but empty response', () async {
      final provider = OpenAICompatibleAIProvider(
        config: _config(),
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': '   '},
                },
              ],
            }),
            200,
          ),
        ),
      );

      await expectLater(
        provider.complete(_prompt()),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'AI provider returned an empty response.',
          ),
        ),
      );
    });

    test('supports multimodal-style content arrays', () async {
      final provider = OpenAICompatibleAIProvider(
        config: _config(),
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content': [
                      {'type': 'text', 'text': 'first'},
                      'second',
                      {'type': 'text', 'text': 'third'},
                    ],
                  },
                },
              ],
            }),
            200,
          ),
        ),
      );

      expect(
        await provider.complete(_prompt()),
        'first\nsecond\nthird',
      );
    });

    test('returns long response without provider-side truncation', () async {
      final content = 'long-response-' * 2000;
      final provider = OpenAICompatibleAIProvider(
        config: _config(),
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': content},
                },
              ],
            }),
            200,
          ),
        ),
      );

      final result = await provider.complete(_prompt());
      expect(result, content);
      expect(result.length, content.length);
    });
  });
}

AIProviderConfig _config({
  String baseUrl = 'https://example.test',
  String model = 'model-x',
  String apiKey = '',
  String chatPath = '/v1/chat/completions',
  Map<String, String> extraHeaders = const {},
  int timeoutSeconds = 90,
}) {
  return AIProviderConfig(
    baseUrl: baseUrl,
    model: model,
    apiKey: apiKey,
    chatPath: chatPath,
    extraHeaders: extraHeaders,
    timeoutSeconds: timeoutSeconds,
  );
}

AIPromptPackage _prompt() {
  return const AIPromptPackage(
    systemPrompt: 'System',
    contextBlock: '',
    history: [],
    userPrompt: 'Hello',
  );
}

class _NeverClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return Completer<http.StreamedResponse>().future;
  }
}
