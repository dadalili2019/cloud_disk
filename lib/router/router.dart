import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import '../pages/navigationPage.dart';
import '../pages/file.dart';
import '../pages/myProfile.dart';
import '../pages/favorites.dart';
import '../pages/recently_played.dart';
import '../pages/password.dart';
import '../pages/settings.dart';
import '../pages/subscribe.dart';
import '../pages/recyclePage.dart';
import '../pages/photo.dart';
import '../pages/transferList.dart';
import '../pages/deviceInformation.dart';
import '../pages/capacityInformation.dart';
import '../pages/login.dart';

final router = GoRouter(
  initialLocation: "/login", //初始化的路由
  routes: [
    GoRoute(
      name: "login",
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return NavigationPage(child: child);
      },
      routes: <RouteBase>[
        GoRoute(
          name: "file",
          path: '/file',
          builder: (context, state) => const FilePage(),
        ),
        GoRoute(
          name: "photo",
          path: '/photo',
          builder: (context, state) => const PhotoPage(),
        ),
        GoRoute(
          name: "password",
          path: '/password', //位置，如同url
          builder: (context, state) {
            return const PasswordPage();
          },
        ),
        GoRoute(
          name: "subscribe",
          path: '/subscribe', //位置，如同url
          builder: (context, state) {
            return const SubscribePage();
          },
        ),
        GoRoute(
          name: "recentlyPlayed",
          path: '/recentlyPlayed',
          builder: (context, state) => const RecentlyPlayedPage(),
        ),
        GoRoute(
          name: "favorites",
          path: '/favorites',
          builder: (context, state) => const FavoritesPage(),
        ),
        GoRoute(
          name: "myProfile",
          path: '/myProfile',
          builder: (context, state) => const MyProfilePage(),
        ),
        GoRoute(
          name: "recycle",
          path: '/recycle',
          builder: (context, state) {
            return const RecyclePage();
          },
        ),
        GoRoute(
          name: "transferList",
          path: '/transferList',
          builder: (context, state) => const TransferListPage(),
        ),
        GoRoute(
          name: "settings",
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          //硬件信息
          name: "deviceInformation",
          path: '/deviceInformation',
          builder: (context, state) => const DeviceInformation(),
        ),
        GoRoute(
          //容量信息
          name: "capacityInformation",
          path: '/capacityInformation',
          builder: (context, state) => const CapacityInformation(),
        ),
      ],
    ),
  ],
);
