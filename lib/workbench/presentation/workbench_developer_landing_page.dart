import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../application/continue_service.dart';
import '../workbench_runtime.dart';
import 'workbench_ui.dart';

class WorkbenchDeveloperLandingPage extends StatefulWidget {
  const WorkbenchDeveloperLandingPage({super.key});

  @override
  State<WorkbenchDeveloperLandingPage> createState() =>
      _WorkbenchDeveloperLandingPageState();
}

class _WorkbenchDeveloperLandingPageState
    extends State<WorkbenchDeveloperLandingPage> {
  late Future<ContinueSnapshot> _snapshot;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _snapshot = WorkbenchRuntime.instance.then(
      (runtime) => runtime.continueService.load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ContinueSnapshot>(
      future: _snapshot,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const WorkbenchPage(
            title: '开发者',
            children: [
              WorkbenchCard(
                child: SizedBox(
                  height: 160,
                  child: Center(child: ProgressRing()),
                ),
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          return WorkbenchPage(
            title: '开发者',
            children: [
              WorkbenchEmptyState(
                title: '开发上下文暂时无法加载',
                description: '可以稍后重试。',
                actionLabel: '重试',
                onAction: () => setState(_reload),
              ),
            ],
          );
        }

        final primary = snapshot.data?.primary;
        if (primary == null) {
          return WorkbenchPage(
            title: '开发者',
            children: [
              WorkbenchEmptyState(
                title: '暂无当前工作区',
                description: '先选择当前任务，再进入对应工作区的开发资源。',
                actionLabel: '打开工作区',
                onAction: () => context.go('/workspace'),
              ),
            ],
          );
        }

        return WorkbenchPage(
          title: '开发者',
          children: [
            WorkbenchCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(FluentIcons.link, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          primary.workspace.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          primary.context.task.title,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () => context.go(
                      '/workspace/${primary.workspace.id}/developer',
                    ),
                    child: const Text('打开开发资源'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}