import 'package:fluent_ui/fluent_ui.dart';

class RecyclePage extends StatefulWidget {
  const RecyclePage({super.key});

  @override
  State<RecyclePage> createState() => _RecyclePageState();
}

class _RecyclePageState extends State<RecyclePage> {
  @override
  Widget build(BuildContext context) {
    return const ScaffoldPage(
      content: Center(
        child: Text("RecyclePage"),
      ),
    );
  }
}
