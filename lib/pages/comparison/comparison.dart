///  @author caoqian
/// @since 2025-08-06 22:14
/// @Description: 文字比对

import 'package:fluent_ui/fluent_ui.dart';

class ComparisonPage extends StatefulWidget {
  const ComparisonPage({super.key});

  @override
  State<ComparisonPage> createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> {
  final TextEditingController _controllerA = TextEditingController();
  final TextEditingController _controllerB = TextEditingController();
  List<TextSpan> _diffSpans = [];
  bool? _isSame; // null: 未比较；true: 相同；false: 不同

  void _compareText() {
    final textA = _controllerA.text;
    final textB = _controllerB.text;

    List<TextSpan> spans = [];
    bool same = textA == textB;

    if (same) {
      _isSame = true;
      _diffSpans = [];
    } else {
      _isSame = false;
      for (int i = 0; i < textB.length; i++) {
        String charB = textB[i];
        String? charA = i < textA.length ? textA[i] : null;

        if (charA != charB) {
          spans.add(TextSpan(
            text: charB,
            style: TextStyle(
              backgroundColor: Colors.red,
              color: Colors.white,
            ),
          ));
        } else {
          spans.add(TextSpan(text: charB));
        }
      }
      _diffSpans = spans;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('文字比对')),
      content: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("请输入要比对的两段文本（左 vs 右）："),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextBox(
                    maxLines: 5,
                    placeholder: '文本 A',
                    controller: _controllerA,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextBox(
                    maxLines: 5,
                    placeholder: '文本 B',
                    controller: _controllerB,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: FilledButton(
                child: const Text('对比'),
                onPressed: _compareText,
              ),
            ),
            const SizedBox(height: 20),
            if (_isSame != null)
              _isSame!
                  ? Text(
                '内容一致 ✅',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("比对结果（B中显示的差异）："),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        children: _diffSpans,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}


