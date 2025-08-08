///  @author caoqian
/// @since 2025-08-06 22:45
/// @Description: json格式化
///
import 'dart:convert';

import 'package:clipboard/clipboard.dart'; // 用于复制内容（添加到 pubspec.yaml）
import 'package:fluent_ui/fluent_ui.dart';

class JsonFormatPage extends StatefulWidget {
  const JsonFormatPage({super.key});

  @override
  State<JsonFormatPage> createState() => _JsonFormatPageState();
}

class _JsonFormatPageState extends State<JsonFormatPage> {
  final TextEditingController _inputController = TextEditingController();
  String _formattedJson = '';
  String? _error;
  bool _validated = false;

  void _formatJson() {
    final raw = _inputController.text;
    try {
      final decoded = jsonDecode(raw);
      const encoder = JsonEncoder.withIndent('  ');
      setState(() {
        _formattedJson = encoder.convert(decoded);
        _error = null;
        _validated = true;
      });
    } catch (e) {
      setState(() {
        _formattedJson = '';
        _error = '❌ JSON格式错误: ${e.toString()}';
        _validated = false;
      });
    }
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _formattedJson = '';
      _error = null;
      _validated = false;
    });
  }

  void _copyResult() {
    if (_formattedJson.isNotEmpty) {
      FlutterClipboard.copy(_formattedJson);

      displayInfoBar(
        context,
        builder: (context, close) {
          return InfoBar(
            title: const Text('复制成功'),
            content: const Text('✅ 已复制格式化结果'),
            severity: InfoBarSeverity.success,
            isLong: true,
            onClose: close,
          );
        },
      );
    }
  }

  void _compressJson() {
    final input = _inputController.text;
    setState(() {
      _error = null;
      _validated = false;
      _formattedJson = '';
    });

    try {
      final decoded = json.decode(input);
      final compressed = json.encode(decoded); // 👈 encode 自动去掉空格和换行
      setState(() {
        _formattedJson = compressed;
        _validated = true;
      });
    } catch (e) {
      setState(() {
        _error = '❌ JSON 解析错误：${e.toString()}';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('JSON 格式化校验')),
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('请输入 JSON 内容（左侧输入，右侧显示格式化结果）：'),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧输入框
                  Expanded(
                    child: TextBox(
                      controller: _inputController,
                      minLines: 20,
                      maxLines: null,
                      expands: false,
                      placeholder: '{ "name": "张三", "age": 18 }',
                      style: const TextStyle(fontFamily: 'Consolas'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 右侧格式化输出
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SelectableText(
                        _formattedJson.isEmpty ? '格式化结果会显示在这里' : _formattedJson,
                        style: const TextStyle(fontFamily: 'Consolas'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 操作按钮区
              Row(
                children: [
                  FilledButton(
                    onPressed: _formatJson,
                    child: const Text('格式化校验'),
                  ),
                  const SizedBox(width: 10),
                  Button(
                    onPressed: _copyResult,
                    child: const Text('复制结果'),
                  ),
                  const SizedBox(width: 10),
                  Button(
                    onPressed: _clearAll,
                    child: const Text('清空'),
                  ),
                  const SizedBox(width: 10),
                  Button(
                    onPressed: _compressJson,
                    child: const Text('压缩为一行'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 状态提示区
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red),
                )
              else if (_validated)
                Text(
                  '✅ 正确的 JSON',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
