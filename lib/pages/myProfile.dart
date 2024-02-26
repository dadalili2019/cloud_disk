import 'package:fluent_ui/fluent_ui.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  @override
  Widget build(BuildContext context) {
    return const ScaffoldPage(
      content: Center(
        child: Text("MyProfilePage"),
      ),
    );
  }
}
