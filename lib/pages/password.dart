import 'package:fluent_ui/fluent_ui.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: Center(
        child: Text("我是一个order页面"),
      ),
    );
  }
}
