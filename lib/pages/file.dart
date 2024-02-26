import 'package:fluent_ui/fluent_ui.dart';

class FilePage extends StatefulWidget {
  const FilePage({super.key});

  @override
  State<FilePage> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: Center(child: Text("文件")),
    );
  }
}
