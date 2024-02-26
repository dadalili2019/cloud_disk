import 'package:fluent_ui/fluent_ui.dart';

class PhotoPage extends StatefulWidget {
  const PhotoPage({super.key});

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  @override
  Widget build(BuildContext context) {
    return const ScaffoldPage(
      content: Center(
        child: Text("PhotoPage"),
      ),
    );
  }
}
