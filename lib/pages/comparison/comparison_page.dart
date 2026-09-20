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
      content: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                onPressed: _compareText,
                child: const Text('对比'),
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
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


