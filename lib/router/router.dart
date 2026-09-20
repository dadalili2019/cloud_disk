import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../app/navigation_page.dart';
import '../pages/comparison/comparison_page.dart' deferred as comparison;
import '../pages/game/game_page.dart' deferred as game;
import '../pages/image_tools/collage_tool.dart' deferred as collage_tool;
import '../pages/image_tools/crop_tool.dart' deferred as crop_tool;
import '../pages/image_tools/dedupe_tool.dart' deferred as dedupe_tool;
import '../pages/image_tools/filter_tool.dart' deferred as filter_tool;
import '../pages/image_tools/image_convert_page.dart' deferred as image_convert;
import '../pages/image_tools/watermark_tool.dart' deferred as watermark_tool;
import '../pages/json_format/json_format_page.dart' deferred as json_format;
import '../pages/login_page.dart';
import '../pages/rag_knowledge/rag_knowledge_page.dart' deferred as rag_knowledge;
import '../pages/settings/settings_page.dart';
import '../pages/speed_test/speed_test_page.dart' deferred as speed_test;
import '../workbench/presentation/workbench_decision_page.dart';
import '../workbench/presentation/workbench_developer_landing_page.dart';
import '../workbench/presentation/workbench_developer_page.dart';
import '../workbench/presentation/workbench_home_page.dart';
import '../workbench/presentation/workbench_issue_page.dart';
import '../workbench/presentation/workbench_knowledge_page.dart';
import '../workbench/presentation/workbench_notes_editor_page.dart';
import '../workbench/presentation/workbench_workspace_overview_page.dart';
import '../workbench/presentation/workbench_resource_page.dart';
import '../workbench/presentation/workbench_task_list_page.dart';
import '../workbench/presentation/workbench_time_page.dart';
import '../workbench/presentation/workbench_tools_page.dart';
import '../workbench/presentation/workbench_workspace_list_page.dart';

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/', redirect: (_, __) => '/home'),
    GoRoute(
      name: 'login',
      path: '/login',
      pageBuilder: (_, __) => const NoTransitionPage(child: LoginPage()),
    ),
    ShellRoute(
      builder: (_, __, child) => NavigationPage(child: child),
      routes: [
        ..._workbenchRoutes,
        GoRoute(
          name: 'setting',
          path: '/setting',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: SettingPage()),
        ),
        ..._toolRoutes,
      ],
    ),
  ],
);

final List<RouteBase> _workbenchRoutes = [
  GoRoute(
    name: 'home',
    path: '/home',
    pageBuilder: (_, __) =>
        const NoTransitionPage(child: WorkbenchHomePage()),
  ),
  GoRoute(
    name: 'workbenchWorkspace',
    path: '/workspace',
    pageBuilder: (_, __) =>
        const NoTransitionPage(child: WorkbenchWorkspaceListPage()),
  ),
  GoRoute(
    name: 'workbenchKnowledge',
    path: '/knowledge',
    pageBuilder: (_, __) =>
        const NoTransitionPage(child: WorkbenchKnowledgePage()),
  ),
  GoRoute(
    name: 'workbenchTime',
    path: '/time',
    pageBuilder: (_, __) =>
        const NoTransitionPage(child: WorkbenchTimePage()),
  ),
  GoRoute(
    name: 'workbenchDeveloperLanding',
    path: '/developer',
    pageBuilder: (_, __) =>
        const NoTransitionPage(child: WorkbenchDeveloperLandingPage()),
  ),
  GoRoute(
    name: 'workbenchTools',
    path: '/tools',
    pageBuilder: (_, __) =>
        const NoTransitionPage(child: WorkbenchToolsPage()),
  ),
  GoRoute(
    name: 'workbenchOverview',
    path: '/workspace/:workspaceId/overview',
    pageBuilder: (_, state) {
      final workspaceId = state.params['workspaceId']!;
      return NoTransitionPage(
        child: WorkbenchWorkspaceFrame(
          workspaceId: workspaceId,
          section: 'overview',
          child: WorkbenchOverviewPage(workspaceId: workspaceId),
        ),
      );
    },
  ),
  GoRoute(
    name: 'workbenchTasks',
    path: '/workspace/:workspaceId/tasks',
    pageBuilder: (_, state) {
      final workspaceId = state.params['workspaceId']!;
      return NoTransitionPage(
        child: WorkbenchWorkspaceFrame(
          workspaceId: workspaceId,
          section: 'tasks',
          child: WorkbenchTaskListPage(workspaceId: workspaceId),
        ),
      );
    },
  ),
  GoRoute(
    name: 'workbenchNotes',
    path: '/workspace/:workspaceId/notes',
    pageBuilder: (_, state) {
      final workspaceId = state.params['workspaceId']!;
      return NoTransitionPage(
        child: WorkbenchWorkspaceFrame(
          workspaceId: workspaceId,
          section: 'notes',
          child: WorkbenchNotesEditorPage(workspaceId: workspaceId),
        ),
      );
    },
  ),
  GoRoute(
    name: 'workbenchIssues',
    path: '/workspace/:workspaceId/issues',
    pageBuilder: (_, state) {
      final workspaceId = state.params['workspaceId']!;
      return NoTransitionPage(
        child: WorkbenchWorkspaceFrame(
          workspaceId: workspaceId,
          section: 'issues',
          child: WorkbenchIssuePage(workspaceId: workspaceId),
        ),
      );
    },
  ),
  GoRoute(
    name: 'workbenchResources',
    path: '/workspace/:workspaceId/resources',
    pageBuilder: (_, state) {
      final workspaceId = state.params['workspaceId']!;
      return NoTransitionPage(
        child: WorkbenchWorkspaceFrame(
          workspaceId: workspaceId,
          section: 'resources',
          child: WorkbenchResourcePage(workspaceId: workspaceId),
        ),
      );
    },
  ),
  GoRoute(
    name: 'workbenchDecisions',
    path: '/workspace/:workspaceId/decisions',
    pageBuilder: (_, state) {
      final workspaceId = state.params['workspaceId']!;
      return NoTransitionPage(
        child: WorkbenchWorkspaceFrame(
          workspaceId: workspaceId,
          section: 'decisions',
          child: WorkbenchDecisionPage(workspaceId: workspaceId),
        ),
      );
    },
  ),
  GoRoute(
    name: 'workbenchDeveloper',
    path: '/workspace/:workspaceId/developer',
    pageBuilder: (_, state) {
      final workspaceId = state.params['workspaceId']!;
      return NoTransitionPage(
        child: WorkbenchWorkspaceFrame(
          workspaceId: workspaceId,
          section: 'developer',
          child: WorkbenchDeveloperPage(workspaceId: workspaceId),
        ),
      );
    },
  ),
];

final List<RouteBase> _toolRoutes = [
  GoRoute(
    name: 'comparison',
    path: '/comparison',
    builder: (_, __) => _DeferredPage(
      loader: comparison.loadLibrary,
      builder: () => comparison.ComparisonPage(),
    ),
  ),
  GoRoute(
    name: 'jsonformat',
    path: '/jsonformat',
    builder: (_, __) => _DeferredPage(
      loader: json_format.loadLibrary,
      builder: () => json_format.JsonFormatPage(),
    ),
  ),
  GoRoute(
    name: 'imageConvert',
    path: '/imagetools/convert',
    builder: (_, __) => _DeferredPage(
      loader: image_convert.loadLibrary,
      builder: () => image_convert.ImageToolsPage(),
    ),
  ),
  GoRoute(
    name: 'imageWatermark',
    path: '/imagetools/watermark',
    builder: (_, __) => _DeferredPage(
      loader: watermark_tool.loadLibrary,
      builder: () => watermark_tool.WatermarkToolPage(),
    ),
  ),
  GoRoute(
    name: 'imageCrop',
    path: '/imagetools/crop',
    builder: (_, __) => _DeferredPage(
      loader: crop_tool.loadLibrary,
      builder: () => crop_tool.CropToolPage(),
    ),
  ),
  GoRoute(
    name: 'imageFilter',
    path: '/imagetools/filter',
    builder: (_, __) => _DeferredPage(
      loader: filter_tool.loadLibrary,
      builder: () => filter_tool.FilterToolPage(),
    ),
  ),
  GoRoute(
    name: 'imageCollage',
    path: '/imagetools/collage',
    builder: (_, __) => _DeferredPage(
      loader: collage_tool.loadLibrary,
      builder: () => collage_tool.CollageToolPage(),
    ),
  ),
  GoRoute(
    name: 'imageDedupe',
    path: '/imagetools/dedupe',
    builder: (_, __) => _DeferredPage(
      loader: dedupe_tool.loadLibrary,
      builder: () => dedupe_tool.DedupeToolPage(),
    ),
  ),
  GoRoute(
    name: 'imagetools',
    path: '/imagetools',
    redirect: (_, __) => '/imagetools/convert',
  ),
  GoRoute(
    name: 'speedtestpage',
    path: '/speedtestpage',
    builder: (_, __) => _DeferredPage(
      loader: speed_test.loadLibrary,
      builder: () => speed_test.SpeedTestPage(),
    ),
  ),
  GoRoute(
    name: 'ragknowledge',
    path: '/ragknowledge',
    builder: (_, __) => _DeferredPage(
      loader: rag_knowledge.loadLibrary,
      builder: () => rag_knowledge.RagKnowledgePage(),
    ),
  ),
  GoRoute(
    name: 'game',
    path: '/game',
    builder: (_, __) => _DeferredPage(
      loader: game.loadLibrary,
      builder: () => game.GamePage(),
    ),
  ),
];

class _DeferredPage extends StatelessWidget {
  const _DeferredPage({
    required this.loader,
    required this.builder,
  });

  final Future<void> Function() loader;
  final Widget Function() builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: loader(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return builder();
        }
        return const ScaffoldPage(
          content: Center(child: ProgressRing()),
        );
      },
    );
  }
}
