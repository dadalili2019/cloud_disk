import 'package:cloud_disk/theme/theme_controller.dart';
import 'package:cloud_disk/workbench/presentation/workbench_ui.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WorkbenchCard renders child content', (tester) async {
    await tester.pumpWidget(_testApp(
      const WorkbenchCard(child: Text('Card content')),
    ));

    expect(find.text('Card content'), findsOneWidget);
  });

  testWidgets('WorkbenchTag renders selected label', (tester) async {
    await tester.pumpWidget(_testApp(
      const Center(
        child: WorkbenchTag(
          label: 'Pinned',
          selected: true,
        ),
      ),
    ));

    expect(find.text('Pinned'), findsOneWidget);
  });

  testWidgets('WorkbenchEmptyState exposes action', (tester) async {
    var pressed = false;

    await tester.pumpWidget(_testApp(
      WorkbenchEmptyState(
        title: 'No notes',
        description: 'Create the first note.',
        actionLabel: 'Create',
        onAction: () => pressed = true,
      ),
    ));

    expect(find.text('No notes'), findsOneWidget);
    expect(find.text('Create the first note.'), findsOneWidget);

    await tester.tap(find.text('Create'));
    await tester.pump();

    expect(pressed, isTrue);
  });

  testWidgets('WorkbenchSectionPage renders action and body', (tester) async {
    await tester.pumpWidget(_testApp(
      const WorkbenchSectionPage(
        title: 'Notes',
        actions: [
          Button(
            onPressed: null,
            child: Text('New note'),
          ),
        ],
        child: Center(child: Text('Notes body')),
      ),
    ));

    expect(find.text('New note'), findsOneWidget);
    expect(find.text('Notes body'), findsOneWidget);
  });
}

Widget _testApp(Widget child) {
  final controller = ThemeController();
  return ThemeScope(
    controller: controller,
    child: FluentApp(
      theme: controller.buildTheme(Brightness.light),
      home: SizedBox(
        width: 1024,
        height: 768,
        child: child,
      ),
    ),
  );
}
