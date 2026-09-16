import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../menu/navigationPage.dart';
import '../pages/capacityInformation.dart';
import '../pages/comparison/comparison.dart' deferred as cmp;
import '../pages/deviceInformation.dart';
import '../pages/favorites.dart';
import '../pages/file.dart';
import '../pages/game/game.dart' deferred as game;
import '../pages/imagetools/collage_tool.dart' deferred as collagetool;
import '../pages/imagetools/crop_tool.dart' deferred as croptool;
import '../pages/imagetools/dedupe_tool.dart' deferred as dedupetool;
import '../pages/imagetools/filter_tool.dart' deferred as filtertool;
import '../pages/imagetools/imagetools.dart' deferred as imagetools;
import '../pages/imagetools/watermark_tool.dart' deferred as watermarktool;
import '../pages/jsonformat/jsonformat.dart' deferred as jf;
import '../pages/login.dart';
import '../pages/myProfile.dart';
import '../pages/password.dart';
import '../pages/photo.dart' deferred as photo;
import '../pages/ragknowledge/ragknowledge.dart' deferred as ragknowledge;
import '../pages/recently_played.dart';
import '../pages/recyclePage.dart';
import '../pages/setting/setting.dart';
import '../pages/shareFolder/shareFolder.dart' deferred as share;
import '../pages/speedtestpage/speedtestpage.dart' deferred as speed;
import '../pages/subscribe.dart';
import '../pages/todo.dart';
import '../workbench/presentation/workbench_decision_page.dart';
import '../workbench/presentation/workbench_developer_page.dart';
import '../workbench/presentation/workbench_home_page.dart';
import '../workbench/presentation/workbench_issue_page.dart';
import '../workbench/presentation/workbench_knowledge_page.dart';
import '../workbench/presentation/workbench_notes_editor_page.dart';
import '../workbench/presentation/workbench_phase2_pages.dart';
import '../workbench/presentation/workbench_resource_page.dart';
import '../workbench/presentation/workbench_task_list_page.dart';
import '../workbench/presentation/workbench_workspace_list_v2_page.dart';

class DeferredWidget extends StatelessWidget {
  const DeferredWidget({super.key, required this.loader, required this.builder});
  final Future<void> Function() loader;
  final Widget Function() builder;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: loader(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.done) return builder();
        return const ScaffoldPage(content: Center(child: ProgressRing()));
      },
    );
  }
}

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/home'),
    GoRoute(name: 'login', path: '/login', pageBuilder: (context, state) => const NoTransitionPage(child: LoginPage())),
    ShellRoute(
      builder: (context, state, child) => NavigationPage(child: child),
      routes: <RouteBase>[
        GoRoute(name: 'home', path: '/home', pageBuilder: (context, state) => const NoTransitionPage(child: WorkbenchHomePage())),
        GoRoute(name: 'workbenchWorkspace', path: '/workspace', pageBuilder: (context, state) => const NoTransitionPage(child: WorkbenchWorkspaceListPageV2())),
        GoRoute(name: 'workbenchKnowledge', path: '/knowledge', pageBuilder: (context, state) => const NoTransitionPage(child: WorkbenchKnowledgePage())),
        GoRoute(
          name: 'workbenchOverview', path: '/workspace/:workspaceId/overview',
          pageBuilder: (context, state) {
            final workspaceId = state.params['workspaceId']!;
            return NoTransitionPage(child: WorkbenchWorkspaceFrameV2(workspaceId: workspaceId, section: 'overview', child: WorkbenchOverviewPageV2(workspaceId: workspaceId)));
          },
        ),
        GoRoute(
          name: 'workbenchTasks', path: '/workspace/:workspaceId/tasks',
          pageBuilder: (context, state) {
            final workspaceId = state.params['workspaceId']!;
            return NoTransitionPage(child: WorkbenchWorkspaceFrameV2(workspaceId: workspaceId, section: 'tasks', child: WorkbenchTaskListPage(workspaceId: workspaceId)));
          },
        ),
        GoRoute(
          name: 'workbenchNotes', path: '/workspace/:workspaceId/notes',
          pageBuilder: (context, state) {
            final workspaceId = state.params['workspaceId']!;
            return NoTransitionPage(child: WorkbenchWorkspaceFrameV2(workspaceId: workspaceId, section: 'notes', child: WorkbenchNotesEditorPage(workspaceId: workspaceId)));
          },
        ),
        GoRoute(
          name: 'workbenchIssues', path: '/workspace/:workspaceId/issues',
          pageBuilder: (context, state) {
            final workspaceId = state.params['workspaceId']!;
            return NoTransitionPage(child: WorkbenchWorkspaceFrameV2(workspaceId: workspaceId, section: 'issues', child: WorkbenchIssuePage(workspaceId: workspaceId)));
          },
        ),
        GoRoute(
          name: 'workbenchResources', path: '/workspace/:workspaceId/resources',
          pageBuilder: (context, state) {
            final workspaceId = state.params['workspaceId']!;
            return NoTransitionPage(child: WorkbenchWorkspaceFrameV2(workspaceId: workspaceId, section: 'resources', child: WorkbenchResourcePage(workspaceId: workspaceId)));
          },
        ),
        GoRoute(
          name: 'workbenchDecisions', path: '/workspace/:workspaceId/decisions',
          pageBuilder: (context, state) {
            final workspaceId = state.params['workspaceId']!;
            return NoTransitionPage(child: WorkbenchWorkspaceFrameV2(workspaceId: workspaceId, section: 'decisions', child: WorkbenchDecisionPage(workspaceId: workspaceId)));
          },
        ),
        GoRoute(
          name: 'workbenchDeveloper', path: '/workspace/:workspaceId/developer',
          pageBuilder: (context, state) {
            final workspaceId = state.params['workspaceId']!;
            return NoTransitionPage(child: WorkbenchWorkspaceFrameV2(workspaceId: workspaceId, section: 'developer', child: WorkbenchDeveloperPage(workspaceId: workspaceId)));
          },
        ),
        GoRoute(name: 'file', path: '/file', pageBuilder: (context, state) => const NoTransitionPage(child: FilePage())),
        GoRoute(name: 'myProfile', path: '/myProfile', pageBuilder: (context, state) => const NoTransitionPage(child: MyProfilePage())),
        GoRoute(name: 'favorites', path: '/favorites', pageBuilder: (context, state) => const NoTransitionPage(child: FavoritesPage())),
        GoRoute(name: 'recentlyPlayed', path: '/recentlyPlayed', pageBuilder: (context, state) => const NoTransitionPage(child: RecentlyPlayedPage())),
        GoRoute(name: 'password', path: '/password', pageBuilder: (context, state) => const NoTransitionPage(child: PasswordPage())),
        GoRoute(name: 'setting', path: '/setting', pageBuilder: (context, state) => const NoTransitionPage(child: SettingPage())),
        GoRoute(name: 'subscribe', path: '/subscribe', pageBuilder: (context, state) => const NoTransitionPage(child: SubscribePage())),
        GoRoute(name: 'recycle', path: '/recycle', pageBuilder: (context, state) => const NoTransitionPage(child: RecyclePage())),
        GoRoute(name: 'deviceInformation', path: '/deviceInformation', pageBuilder: (context, state) => const NoTransitionPage(child: DeviceInformation())),
        GoRoute(name: 'capacityInformation', path: '/capacityInformation', pageBuilder: (context, state) => const NoTransitionPage(child: CapacityInformation())),
        GoRoute(name: 'photo', path: '/photo', builder: (context, state) => DeferredWidget(loader: photo.loadLibrary, builder: () => photo.PhotoPage())),
        GoRoute(name: 'comparison', path: '/comparison', builder: (context, state) => DeferredWidget(loader: cmp.loadLibrary, builder: () => cmp.ComparisonPage())),
        GoRoute(name: 'jsonformat', path: '/jsonformat', builder: (context, state) => DeferredWidget(loader: jf.loadLibrary, builder: () => jf.JsonFormatPage())),
        GoRoute(name: 'imageConvert', path: '/imagetools/convert', builder: (context, state) => DeferredWidget(loader: imagetools.loadLibrary, builder: () => imagetools.ImageToolsPage())),
        GoRoute(name: 'imageWatermark', path: '/imagetools/watermark', builder: (context, state) => DeferredWidget(loader: watermarktool.loadLibrary, builder: () => watermarktool.WatermarkToolPage())),
        GoRoute(name: 'imageCrop', path: '/imagetools/crop', builder: (context, state) => DeferredWidget(loader: croptool.loadLibrary, builder: () => croptool.CropToolPage())),
        GoRoute(name: 'imageFilter', path: '/imagetools/filter', builder: (context, state) => DeferredWidget(loader: filtertool.loadLibrary, builder: () => filtertool.FilterToolPage())),
        GoRoute(name: 'imageCollage', path: '/imagetools/collage', builder: (context, state) => DeferredWidget(loader: collagetool.loadLibrary, builder: () => collagetool.CollageToolPage())),
        GoRoute(name: 'imageDedupe', path: '/imagetools/dedupe', builder: (context, state) => DeferredWidget(loader: dedupetool.loadLibrary, builder: () => dedupetool.DedupeToolPage())),
        GoRoute(name: 'imagetools', path: '/imagetools', redirect: (context, state) => '/imagetools/convert'),
        GoRoute(name: 'speedtestpage', path: '/speedtestpage', builder: (context, state) => DeferredWidget(loader: speed.loadLibrary, builder: () => speed.SpeedTestPage())),
        GoRoute(name: 'ragknowledge', path: '/ragknowledge', builder: (context, state) => DeferredWidget(loader: ragknowledge.loadLibrary, builder: () => ragknowledge.RagKnowledgePage())),
        GoRoute(name: 'game', path: '/game', builder: (context, state) => DeferredWidget(loader: game.loadLibrary, builder: () => game.GamePage())),
        GoRoute(name: 'shareFolder', path: '/shareFolder', builder: (context, state) => DeferredWidget(loader: share.loadLibrary, builder: () => share.ShareFolder())),
        GoRoute(name: 'todo', path: '/todo', pageBuilder: (context, state) => const NoTransitionPage(child: TodoPage())),
      ],
    ),
  ],
);
