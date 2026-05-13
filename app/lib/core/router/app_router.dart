import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazad/features/home/home_screen.dart';
import 'package:mazad/features/system/force_update_notifier.dart';
import 'package:mazad/features/system/force_update_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: ForceUpdateNotifier.instance,
    redirect: (context, state) {
      if (ForceUpdateNotifier.instance.isActive &&
          state.matchedLocation != '/force-update') {
        return '/force-update';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/force-update',
        builder: (_, __) {
          final p = ForceUpdateNotifier.instance.payload;
          return ForceUpdateScreen(
            storeUrl: p?.storeUrl,
            releaseNotes: p?.releaseNotes,
          );
        },
      ),
    ],
  );
});
