import 'package:fluent_ui/fluent_ui.dart';

class CapacityInformation extends StatefulWidget {
  const CapacityInformation({super.key});

  @override
  State<CapacityInformation> createState() => _CapacityInformationState();
}

class _CapacityInformationState extends State<CapacityInformation> {
  @override
  Widget build(BuildContext context) {
    return const ScaffoldPage(
      content: Center(
        child: Text("CapacityInformation"),
      ),
    );
  }
}
