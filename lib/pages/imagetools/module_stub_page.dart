import 'package:fluent_ui/fluent_ui.dart';

class ImageModuleStubPage extends StatelessWidget {
  const ImageModuleStubPage({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(title: Text(title)),
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FluentTheme.of(context).resources.cardBackgroundFillColorDefault,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(description),
        ),
      ),
    );
  }
}
