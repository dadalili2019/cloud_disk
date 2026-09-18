import 'package:fluent_ui/fluent_ui.dart';

import '../application/continue_service.dart';
import '../workbench_runtime.dart';
import 'focus_today_card.dart';
import 'workbench_ui.dart';

class WorkbenchTimePage extends StatefulWidget {
  const WorkbenchTimePage({super.key});

  @override
  State<WorkbenchTimePage> createState() => _WorkbenchTimePageState();
}

class _WorkbenchTimePageState extends State<WorkbenchTimePage> {
  late Future<ContinueSnapshot> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = WorkbenchRuntime.instance.then(
      (runtime) => runtime.continueService.load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ContinueSnapshot>(
      future: _snapshot,
      builder: (context, snapshot) {
        final primary =
            snapshot.connectionState == ConnectionState.done && !snapshot.hasError
                ? snapshot.data?.primary
                : null;
        return WorkbenchPage(
          title: '时间',
          children: [
            if (snapshot.connectionState != ConnectionState.done)
              const WorkbenchCard(
                child: SizedBox(
                  height: 160,
                  child: Center(child: ProgressRing()),
                ),
              )
            else if (snapshot.hasError)
              WorkbenchEmptyState(
                title: '时间信息暂时无法加载',
                description: '',
                actionLabel: '重试',
                onAction: () => setState(() {
                  _snapshot = WorkbenchRuntime.instance.then(
                    (runtime) => runtime.continueService.load(),
                  );
                }),
              )
            else
              FocusTodayCard(primary: primary),
          ],
        );
      },
    );
  }
}
