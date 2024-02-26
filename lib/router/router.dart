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

final router = GoRouter(
  initialLocation: "/file", //初始化的路由
  routes: [
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
          name: "settings",
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
  ],
);
