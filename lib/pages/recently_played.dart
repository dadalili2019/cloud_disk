import 'package:fluent_ui/fluent_ui.dart';

class RecentlyPlayedPage extends StatefulWidget {
  const RecentlyPlayedPage({super.key});

  @override
  State<RecentlyPlayedPage> createState() => _RecentlyPlayedPageState();
}

class _RecentlyPlayedPageState extends State<RecentlyPlayedPage> {
  @override
  Widget build(BuildContext context) {
    return const ScaffoldPage(
      content: Center(
        child: Text("RecentlyPlayedPage"),
      ),
    );
  }
}
