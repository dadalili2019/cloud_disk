import 'package:fluent_ui/fluent_ui.dart';

class SubscribePage extends StatefulWidget {
  const SubscribePage({super.key});

  @override
  State<SubscribePage> createState() => _SubscribePageState();
}

class _SubscribePageState extends State<SubscribePage> {
  @override
  Widget build(BuildContext context) {
    return const ScaffoldPage(
      content: Center(
        child: Text("SubscribePage"),
      ),
    );
  }
}
