import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme_controller.dart';
import '../application/continue_service.dart';
import '../core/models.dart';
import '../workbench_runtime.dart';
import 'quick_capture_drawer.dart';
import 'resume_context_drawer.dart';
import 'workbench_ui.dart';


part 'workbench_home_focus.dart';
part 'workbench_home_panels.dart';
part 'workbench_home_support.dart';

class WorkbenchHomePage extends StatefulWidget {
  const WorkbenchHomePage({super.key});

  @override
  State<WorkbenchHomePage> createState() => _WorkbenchHomePageState();
}

class _WorkbenchHomePageState extends State<WorkbenchHomePage> {
  late Future<_HomeData> _data;
  bool _quickCaptureOpen = false;
  bool _resumeOpen = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _data = WorkbenchRuntime.instance.then((runtime) async {
      final results = await Future.wait<dynamic>([
        runtime.continueService.load(),
        runtime.workspaceService.listActive(),
      ]);
      return _HomeData(
        snapshot: results[0] as ContinueSnapshot,
        workspaces: results[1] as List<WorkspaceModel>,
      );
    });
  }

  void _reloadFromChild() {
    if (!mounted) return;
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<_HomeData>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _HomeLoading();
            }

            if (snapshot.hasError) {
              return _HomeError(
                onRetry: () => setState(_reload),
              );
            }

            final data = snapshot.data!;
            final primary = data.snapshot.primary;

            return WorkbenchPage(
              title: '首页',
              children: [
                if (data.workspaces.isEmpty)
                  WorkbenchEmptyState(
                    title: '开始你的第一个工作区',
                    description: '',
                    actionLabel: '创建工作区',
                    onAction: () => context.go('/workspace'),
                  )
                else if (primary == null)
                  WorkbenchEmptyState(
                    title: '当前没有正在进行的任务',
                    description: '',
                    actionLabel: '选择任务',
                    onAction: () => context.go('/workspace'),
                  )
                else
                  _CurrentFocusCard(
                    item: primary,
                    onOpenTask: () => context.go(
                      '/workspace/${primary.workspace.id}/tasks',
                    ),
                    onQuickCapture: () =>
                        setState(() => _quickCaptureOpen = true),
                    onContinue: () => setState(() => _resumeOpen = true),
                  ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 820;
                    final today = _TodayPanel(
                      primary: primary,
                      onOpenTime: () => context.go('/time'),
                    );
                    final activity = _RecentActivityPanel(
                      primary: primary,
                      onOpenWorkspace: primary == null
                          ? () => context.go('/workspace')
                          : () => context.go(
                                '/workspace/${primary.workspace.id}/overview',
                              ),
                    );

                    if (!twoColumns) {
                      return Column(
                        children: [
                          today,
                          const SizedBox(height: 14),
                          activity,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 11, child: today),
                        const SizedBox(width: 14),
                        Expanded(flex: 9, child: activity),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
        if (_quickCaptureOpen)
          Positioned.fill(
            child: _DrawerLayer(
              onDismiss: () => setState(() => _quickCaptureOpen = false),
              child: FutureBuilder<_HomeData>(
                future: _data,
                builder: (context, snapshot) => QuickCaptureDrawer(
                  defaultWorkspace: snapshot.data?.snapshot.primary?.workspace,
                  onClose: () =>
                      setState(() => _quickCaptureOpen = false),
                  onCaptured: _reloadFromChild,
                ),
              ),
            ),
          ),
        if (_resumeOpen)
          Positioned.fill(
            child: FutureBuilder<_HomeData>(
              future: _data,
              builder: (context, snapshot) {
                final primary = snapshot.data?.snapshot.primary;
                if (primary == null) return const SizedBox.shrink();
                return _DrawerLayer(
                  onDismiss: () => setState(() => _resumeOpen = false),
                  child: ResumeContextDrawer(
                    item: primary,
                    onClose: () => setState(() => _resumeOpen = false),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
