import 'dart:io';

import 'package:cloud_disk/workbench/application/ai_prompt_builder.dart';
import 'package:cloud_disk/workbench/application/openai_compatible_ai_provider.dart';
import 'package:cloud_disk/workbench/core/ai_provider_config.dart';

Future<void> main(List<String> args) async {
  final strictOk = args.contains('--strict-ok');
  final config = AIProviderConfig.fromEnvironment();

  stdout.writeln('Personal Workbench AI real-environment verification');
  stdout.writeln('--------------------------------------------------');

  if (!config.isConfigured) {
    _fail(
      'Provider is not configured. Set WORKBENCH_AI_BASE_URL and '
      'WORKBENCH_AI_MODEL before running this command.',
    );
    return;
  }

  stdout.writeln('Base URL: ${config.baseUrl}');
  stdout.writeln('Chat path: ${config.chatPath}');
  stdout.writeln('Model: ${config.model}');
  stdout.writeln('Timeout: ${config.timeoutSeconds}s');
  stdout.writeln('API key header: ${config.apiKeyHeader}');
  stdout.writeln(
    'Credential configured: ${config.apiKey.trim().isNotEmpty ? 'yes' : 'no'}',
  );
  stdout.writeln(
    'Extra header names: '
    '${config.extraHeaders.isEmpty ? '(none)' : config.extraHeaders.keys.join(', ')}',
  );
  stdout.writeln('No credential values are printed by this verifier.');
  stdout.writeln();

  final provider = OpenAICompatibleAIProvider(config: config);
  final stopwatch = Stopwatch()..start();

  try {
    final response = await provider.complete(
      const AIPromptPackage(
        systemPrompt:
            'You are a connectivity verifier. Do not include explanations.',
        contextBlock: '',
        history: [],
        userPrompt: 'Reply with OK only.',
      ),
    );
    stopwatch.stop();

    final normalized = response.trim();
    if (normalized.isEmpty) {
      _fail('Provider returned an empty response.');
      return;
    }

    if (strictOk && normalized.toUpperCase() != 'OK') {
      _fail(
        'Provider was reachable, but strict response validation failed. '
        'Expected "OK", received "${_preview(normalized)}".',
      );
      return;
    }

    stdout.writeln('RESULT: PASS');
    stdout.writeln('Latency: ${stopwatch.elapsedMilliseconds} ms');
    stdout.writeln('Response: ${_preview(normalized)}');
  } catch (error) {
    stopwatch.stop();
    _fail(
      'Provider request failed after ${stopwatch.elapsedMilliseconds} ms: '
      '${_safeError(error)}',
    );
  }
}

void _fail(String message) {
  stderr.writeln('RESULT: FAIL');
  stderr.writeln(message);
  exitCode = 1;
}

String _preview(String value) {
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= 160) return normalized;
  return '${normalized.substring(0, 160)}…';
}

String _safeError(Object error) {
  final value = error.toString();
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= 500) return normalized;
  return '${normalized.substring(0, 500)}…';
}
