import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

// 轻页面（直接 import）
import '../menu/navigationPage.dart';
import '../pages/capacityInformation.dart';
import '../pages/comparison/comparison.dart' deferred as cmp;
import '../pages/deviceInformation.dart';
import '../pages/favorites.dart';
import '../pages/file.dart';
import '../pages/home.dart';
import '../pages/jsonformat/jsonformat.dart' deferred as jf;
import '../pages/login.dart';
import '../pages/myProfile.dart';
import '../pages/password.dart';
import '../pages/setting/setting.dart';

// 重页面（deferred import，按需加载）
import '../pages/photo.dart' deferred as photo;
import '../pages/recently_played.dart';
import '../pages/recyclePage.dart';
import '../pages/shareFolder/shareFolder.dart' deferred as share;
import '../pages/speedtestpage/speedtestpage.dart' deferred as speed;
import '../pages/subscribe.dart';
import '../pages/todo.dart';
import '../pages/game/game.dart' deferred as game;

/// 延迟加载占位组件
class DeferredWidget extends StatelessWidget {
  final Future<void> Function() loader;
  final Widget Function() builder;

  const DeferredWidget(
      {super.key, required this.loader, required this.builder});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: loader(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.done) {
          return builder();
        }
        return const ScaffoldPage(
          content: Center(child: ProgressRing()),
        );
      },
    );
  }
}

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    // 登录页
    GoRoute(
      name: 'login',
      path: '/login',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: LoginPage()),
    ),

    // 登录后主框架
    ShellRoute(
      builder: (context, state, child) => NavigationPage(child: child),
      routes: <RouteBase>[
        GoRoute(
          name: 'home',
          path: '/home',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomePage()),
        ),
        GoRoute(
          name: 'file',
          path: '/file',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: FilePage()),
        ),
        GoRoute(
          name: 'myProfile',
          path: '/myProfile',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MyProfilePage()),
        ),
        GoRoute(
          name: 'favorites',
          path: '/favorites',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: FavoritesPage()),
        ),
        GoRoute(
          name: 'recentlyPlayed',
          path: '/recentlyPlayed',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: RecentlyPlayedPage()),
        ),
        GoRoute(
          name: 'password',
          path: '/password',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PasswordPage()),
        ),
        GoRoute(
          name: 'setting',
          path: '/setting',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingPage()),
        ),
        GoRoute(
          name: 'subscribe',
          path: '/subscribe',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SubscribePage()),
        ),
        GoRoute(
          name: 'recycle',
          path: '/recycle',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: RecyclePage()),
        ),
        // GoRoute(
        //   name: 'transferList',
        //   path: '/transferList',
        //   pageBuilder: (context, state) =>
        //       const NoTransitionPage(child: TransferListPage()),
        // ),
        GoRoute(
          name: 'deviceInformation',
          path: '/deviceInformation',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DeviceInformation()),
        ),
        GoRoute(
          name: 'capacityInformation',
          path: '/capacityInformation',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CapacityInformation()),
        ),

        // ===== 延迟加载的“重页面” =====
        GoRoute(
          name: 'photo',
          path: '/photo',
          builder: (context, state) => DeferredWidget(
            loader: photo.loadLibrary,
            builder: () => photo.PhotoPage(),
          ),
        ),
        GoRoute(
          name: 'comparison',
          path: '/comparison',
          builder: (context, state) => DeferredWidget(
            loader: cmp.loadLibrary,
            builder: () => cmp.ComparisonPage(),
          ),
        ),
        GoRoute(
          name: 'jsonformat',
          path: '/jsonformat',
          builder: (context, state) => DeferredWidget(
            loader: jf.loadLibrary,
            builder: () => jf.JsonFormatPage(),
          ),
        ),
        GoRoute(
          name: 'speedtestpage',
          path: '/speedtestpage',
          builder: (context, state) => DeferredWidget(
            loader: speed.loadLibrary,
            builder: () => speed.SpeedTestPage(),
          ),
        ),
        GoRoute(
          name: 'game',
          path: '/game',
          builder: (context, state) => DeferredWidget(
            loader: game.loadLibrary,
            builder: () => game.GamePage(),
          ),
        ),
        GoRoute(
          name: 'shareFolder',
          path: '/shareFolder',
          builder: (context, state) => DeferredWidget(
            loader: share.loadLibrary,
            builder: () => share.ShareFolder(),
          ),
        ),

        // todo 保持轻量
        GoRoute(
          name: 'todo',
          path: '/todo',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: TodoPage()),
        ),
      ],
    ),
  ],
);
