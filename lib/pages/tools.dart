///  @author caoqian
/// @since 2024-04-25 13:51
/// @Description: 小工具合集

import 'package:fluent_ui/fluent_ui.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  @override
  Widget build(BuildContext context) {
    return const ScaffoldPage(
      content: Center(
        child: Text("tools"),
      ),
    );
  }
}
