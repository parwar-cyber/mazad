import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazad/core/network/supabase_client.dart';
import 'package:mazad/features/auth/data/auth_providers.dart';
import 'package:mazad/features/auth/otp_verify_screen.dart';
import 'package:mazad/features/auth/phone_signup_screen.dart';
import 'package:mazad/features/auth/profile_setup_screen.dart';
import 'package:mazad/features/dashboard/my_mazad_screen.dart';
import 'package:mazad/features/home/home_screen.dart';
import 'package:mazad/features/kyc/kyc_address_screen.dart';
import 'package:mazad/features/kyc/kyc_id_upload_screen.dart';
import 'package:mazad/features/kyc/kyc_intro_screen.dart';
import 'package:mazad/features/kyc/kyc_payout_screen.dart';
import 'package:mazad/features/kyc/kyc_review_screen.dart';
import 'package:mazad/features/listings/browse/browse_screen.dart';
import 'package:mazad/features/listings/create/listing_ai_screen.dart';
import 'package:mazad/features/listings/create/listing_photos_screen.dart';
import 'package:mazad/features/listings/create/listing_review_screen.dart';
import 'package:mazad/features/listings/create/listing_type_screen.dart';
import 'package:mazad/features/listings/detail/listing_detail_screen.dart';
import 'package:mazad/features/system/force_update_notifier.dart';
import 'package:mazad/features/system/force_update_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Routes that don't require an authenticated session.
const _publicRoutes = {'/', '/auth', '/auth/otp', '/force-update', '/browse'};

/// Path prefixes (in addition to [_publicRoutes]) that are public.
bool _isPublic(String loc) {
  if (_publicRoutes.contains(loc)) return true;
  if (loc.startsWith('/browse')) return true;
  if (loc.startsWith('/listings/')) return true;
  return false;
}

/// Routes that require a complete profile (display_name set).
const _profileGatedRoutes = {'/dashboard', '/kyc', '/sell'};

final appRouterProvider = Provider<GoRouter>((ref) {
  // Re-evaluate redirects whenever auth state changes.  Riverpod's
  // listenable streams plug into GoRouter via this tiny bridge.
  final authNotifier = _AuthRouterRefresh(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: Listenable.merge(
      [ForceUpdateNotifier.instance, authNotifier],
    ),
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Force-update takes precedence over everything else.
      if (ForceUpdateNotifier.instance.isActive &&
          loc != '/force-update') {
        return '/force-update';
      }

      // Skip auth gating when Supabase isn't wired (Phase 0 boot path).
      if (!MazadSupabase.isConfigured) return null;

      final user = Supabase.instance.client.auth.currentUser;
      final isAuthRoute = loc == '/auth' || loc == '/auth/otp';

      // Signed-out users can only see public routes.
      if (user == null) {
        return _isPublic(loc) ? null : '/';
      }

      // Signed-in users hitting the auth screens get bounced to dashboard.
      if (isAuthRoute) return '/dashboard';

      // Profile completion check.  We read the cached future synchronously
      // — if it isn't ready yet, no redirect (the dashboard handles the
      // loading state).
      final profileAsync = ref.read(myProfileProvider);
      final profile = profileAsync.value;
      if (profile != null &&
          !profile.hasCompletedSetup &&
          loc != '/profile-setup' &&
          _profileGatedRoutes.any((p) => loc.startsWith(p))) {
        return '/profile-setup';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/auth',
        builder: (_, __) => const PhoneSignupScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (_, state) =>
            OtpVerifyScreen(phone: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (_, __) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const MyMazadScreen(),
      ),
      GoRoute(
        path: '/kyc',
        builder: (_, __) => const KycIntroScreen(),
        routes: [
          GoRoute(path: 'id', builder: (_, __) => const KycIdUploadScreen()),
          GoRoute(
              path: 'address', builder: (_, __) => const KycAddressScreen()),
          GoRoute(
              path: 'payout', builder: (_, __) => const KycPayoutScreen()),
          GoRoute(
              path: 'review', builder: (_, __) => const KycReviewScreen()),
        ],
      ),
      GoRoute(
        path: '/browse',
        builder: (_, state) {
          final params = state.uri.queryParameters;
          return BrowseScreen(
            initialCategoryId: params['category'],
            initialType: params['type'],
          );
        },
      ),
      GoRoute(
        path: '/listings/:id',
        builder: (_, state) =>
            ListingDetailScreen(id: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/sell',
        builder: (_, __) => const ListingTypeScreen(),
        routes: [
          GoRoute(
            path: 'photos',
            builder: (_, __) => const ListingPhotosScreen(),
          ),
          GoRoute(
            path: 'ai',
            builder: (_, __) => const ListingAiScreen(),
          ),
          GoRoute(
            path: 'review',
            builder: (_, __) => const ListingReviewScreen(),
          ),
        ],
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

/// Bridges Riverpod auth-state changes into a [Listenable] for GoRouter.
/// Notifies on every emission of [authStateProvider] (sign-in, sign-out,
/// session refresh) so route guards re-run.
class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(Ref ref) {
    _sub = ref.listen<AsyncValue<AuthState?>>(
      authStateProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }

  late final ProviderSubscription _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
