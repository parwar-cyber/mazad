import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazad/core/network/supabase_client.dart';
import 'package:mazad/features/bidding/data/bid.dart';
import 'package:mazad/features/bidding/data/bidding_repository.dart';
import 'package:mazad/features/listings/data/listing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Realtime stream of the pseudonymized bid feed for a listing.  Combines
/// an initial fetch (so the UI shows the latest 25 bids on first render)
/// with a realtime subscription on `bids` filtered by `listing_id`.  The
/// bid feed view itself isn't a table — realtime only works on tables —
/// so we subscribe to the underlying `bids` table and join pseudonyms on
/// the client when the inserted row arrives.
final bidFeedProvider =
    StreamProvider.family<List<Bid>, String>((ref, listingId) {
  if (!MazadSupabase.isConfigured) {
    return Stream<List<Bid>>.value(const []);
  }
  final repo = ref.watch(biddingRepositoryProvider);
  final client = Supabase.instance.client;
  final controller = StreamController<List<Bid>>();
  var feed = <Bid>[];

  Future<void> seed() async {
    feed = await repo.fetchBidFeed(listingId);
    if (!controller.isClosed) controller.add(List<Bid>.unmodifiable(feed));
  }

  // We can't filter `from('bids')` in `.stream()` by anything other than
  // primary key; instead, subscribe to a custom channel listening to
  // INSERT events on `public.bids` with a server-side filter.
  final channel = client
      .channel('public:bids:listing=$listingId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'bids',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'listing_id',
          value: listingId,
        ),
        callback: (payload) async {
          final newRow = payload.newRecord;
          // The realtime row is the raw `bids` table — no pseudonym.  Re-
          // fetch the feed slice so we get the joined pseudonym from the
          // view.  Cheap (25 rows) and keeps the UI consistent.
          try {
            feed = await repo.fetchBidFeed(listingId);
            if (!controller.isClosed) {
              controller.add(List<Bid>.unmodifiable(feed));
            }
          } catch (_) {
            // On a transient error, optimistically prepend the raw row.
            final bid = Bid.fromJson(Map<String, dynamic>.from(newRow));
            feed = [bid, ...feed].take(25).toList(growable: false);
            if (!controller.isClosed) {
              controller.add(List<Bid>.unmodifiable(feed));
            }
          }
        },
      )
      .subscribe();

  // Kick off the initial fetch.
  // ignore: unawaited_futures
  seed();

  ref.onDispose(() {
    // ignore: unawaited_futures
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

/// Realtime listing-row stream for the detail screen.  Listens for UPDATE
/// events on the specific listing id so current_high, current_high_bidder
/// and current_close_at re-render the moment another bidder lands a bid.
final listingRealtimeProvider =
    StreamProvider.family<Listing?, String>((ref, listingId) {
  if (!MazadSupabase.isConfigured) {
    return Stream<Listing?>.value(null);
  }
  final client = Supabase.instance.client;
  final controller = StreamController<Listing?>();

  Future<void> seed() async {
    final row = await client
        .from('listings')
        .select()
        .eq('id', listingId)
        .maybeSingle();
    if (controller.isClosed) return;
    controller.add(
        row == null ? null : Listing.fromJson(Map<String, dynamic>.from(row)));
  }

  final channel = client
      .channel('public:listings:id=$listingId')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'listings',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: listingId,
        ),
        callback: (payload) {
          final newRow = payload.newRecord;
          if (!controller.isClosed) {
            controller.add(Listing.fromJson(Map<String, dynamic>.from(newRow)));
          }
        },
      )
      .subscribe();

  // ignore: unawaited_futures
  seed();

  ref.onDispose(() {
    // ignore: unawaited_futures
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});
