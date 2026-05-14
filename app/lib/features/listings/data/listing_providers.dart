import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazad/core/network/supabase_client.dart';
import 'package:mazad/features/auth/data/auth_providers.dart';
import 'package:mazad/features/listings/data/ai_suggestion.dart';
import 'package:mazad/features/listings/data/category.dart';
import 'package:mazad/features/listings/data/listing.dart';
import 'package:mazad/features/listings/data/listing_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cached category list.  Categories are seeded in `supabase/seed.sql` and
/// only change via the admin console — once-per-session fetch is plenty.
final categoriesProvider = FutureProvider<List<ListingCategory>>((ref) async {
  if (!MazadSupabase.isConfigured) return const <ListingCategory>[];
  return ref.read(listingRepositoryProvider).fetchCategories();
});

final categoryBySlugProvider =
    Provider.family<ListingCategory?, String>((ref, slug) {
  final cats = ref.watch(categoriesProvider).value ?? const <ListingCategory>[];
  for (final c in cats) {
    if (c.slug == slug) return c;
  }
  return null;
});

final categoryByIdProvider =
    Provider.family<ListingCategory?, String>((ref, id) {
  final cats = ref.watch(categoriesProvider).value ?? const <ListingCategory>[];
  for (final c in cats) {
    if (c.id == id) return c;
  }
  return null;
});

/// Calls the analyze_item Edge Function via supabase-flutter.  The version
/// header is already attached at SupabaseClient init (see ADR-0004 +
/// `core/network/supabase_client.dart`).
final analyzeItemProvider =
    FutureProvider.family<AiListingSuggestion, String>((ref, listingId) async {
  final res = await Supabase.instance.client.functions.invoke(
    'analyze_item',
    body: {'listing_id': listingId},
  );
  if (res.status != 200) {
    final data = res.data;
    String reason = 'analyze_failed';
    if (data is Map && data['error'] is String) {
      reason = data['error'] as String;
    }
    throw AnalyzeItemException(reason, status: res.status);
  }
  final data = res.data;
  if (data is! Map) throw AnalyzeItemException('invalid_response');
  return AiListingSuggestion.fromJson(Map<String, dynamic>.from(data));
});

class AnalyzeItemException implements Exception {
  AnalyzeItemException(this.reason, {this.status});
  final String reason;
  final int? status;
  @override
  String toString() => 'AnalyzeItemException($reason, status=$status)';
}

// ─── Home feed providers ─────────────────────────────────────────────────
final endingSoonProvider = FutureProvider<List<Listing>>((ref) async {
  if (!MazadSupabase.isConfigured) return const <Listing>[];
  return ref.read(listingRepositoryProvider).endingSoon();
});

final hotListingsProvider = FutureProvider<List<Listing>>((ref) async {
  if (!MazadSupabase.isConfigured) return const <Listing>[];
  return ref.read(listingRepositoryProvider).hot();
});

final bazaarListingsProvider = FutureProvider<List<Listing>>((ref) async {
  if (!MazadSupabase.isConfigured) return const <Listing>[];
  return ref.read(listingRepositoryProvider).bazaar();
});

/// Caller's own listings (drafts + active + sold).  Watches auth state so a
/// sign-out invalidates the list.
final myListingsProvider = FutureProvider<List<Listing>>((ref) async {
  if (!MazadSupabase.isConfigured) return const <Listing>[];
  final user = ref.watch(currentUserProvider);
  if (user == null) return const <Listing>[];
  return ref.read(listingRepositoryProvider).myListings(user.id);
});

/// Listing detail by id, with view-count bump as a side effect.
final listingByIdProvider =
    FutureProvider.family<Listing?, String>((ref, id) async {
  if (!MazadSupabase.isConfigured) return null;
  final repo = ref.read(listingRepositoryProvider);
  // Fire-and-forget bump.  Don't await — should never block detail load.
  // ignore: unawaited_futures
  repo.bumpView(id);
  return repo.fetchById(id);
});
