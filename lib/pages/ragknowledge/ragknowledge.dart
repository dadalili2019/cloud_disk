import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:http/http.dart' as http;

class RagKnowledgePage extends StatefulWidget {
  const RagKnowledgePage({super.key});

  @override
  State<RagKnowledgePage> createState() => _RagKnowledgePageState();
}

class _RagKnowledgePageState extends State<RagKnowledgePage> {
  final TextEditingController _questionController = TextEditingController();

  bool _loading = false;
  String? _answer;
  String? _status;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(
        title: Text('E9知识库'),
      ),
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== 输入区 =====
            TextBox(
              controller: _questionController,
              placeholder: '请输入你的问题，例如：Spring Boot 如何配置数据源',
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            // ===== 操作按钮 =====
            Row(
              children: [
                FilledButton(
                  child: _loading ? const ProgressRing() : const Text('发送'),
                  onPressed: _loading ? null : _onAsk,
                ),
                const SizedBox(width: 12),
                Button(
                  child: const Text('清空'),
                  onPressed: () {
                    _questionController.clear();
                    setState(() {
                      _answer = null;
                      _status = null;
                      _errorMessage = null;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            // ===== 结果区 =====
            Expanded(
              child: _buildResultArea(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    if (_loading) {
      return const Center(child: ProgressRing());
    }

    if (_status == null) {
      return const Center(
        child: Text(
          '等待提问',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    if (_status == 'ERROR') {
      return InfoBar(
        title: const Text('错误'),
        content: Text(_errorMessage ?? '未知错误'),
        severity: InfoBarSeverity.error,
      );
    }

    if (_status == 'NO_ANSWER') {
      return Center(
        child: Card(
          padding: const EdgeInsets.all(20),
          backgroundColor: Colors.yellow.lightest,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                FluentIcons.info,
                size: 20,
                color: Colors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '未命中知识库资料',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _answer ?? '当前知识库中未找到可支撑该问题的资料。',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '你可以尝试更具体的问题，或等待知识库补充后再试。',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // SUCCESS
// SUCCESS
    return Card(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(8),
      child: SingleChildScrollView(
        child: SelectableText(
          _answer ?? '',
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Future<void> _onAsk() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _loading = true;
      _status = null;
      _answer = null;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse(
        'http://localhost:8080/BasicRagKnowledgeService/api/knowledge/ask',
      );

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'question': question,
          'debug': true,
          'returnSources': true,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      final Map<String, dynamic> json =
          jsonDecode(utf8.decode(response.bodyBytes));

      setState(() {
        _loading = false;
        _status = json['status'] as String?;
        _answer = json['answer'] as String?;
        _errorMessage = json['errorMessage'] as String?;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _status = 'ERROR';
        _errorMessage = e.toString();
      });
    }
  }
}
