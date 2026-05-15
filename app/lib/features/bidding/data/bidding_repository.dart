import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazad/features/bidding/data/bid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around place_bid + bid-feed reads.  All mutations go through
/// the `place_bid` RPC — direct INSERT on `bids` is denied by RLS.
class BiddingRepository {
  BiddingRepository(this._client);
  final SupabaseClient _client;

  /// Places a bid via the security-definer RPC.  Returns the inserted row.
  /// Server validates KYC tier, self-bid, rate-limit, increment, and
  /// applies Smart Close + proxy escalation atomically.  See
  /// architecture.md §6.1.
  Future<Bid> placeBid({
    required String listingId,
    required int amount,
    int? maxAmount,
    String source = 'app',
  }) async {
    final res = await _client.rpc('place_bid', params: {
      'p_listing_id': listingId,
      'p_amount': amount,
      'p_max_amount': maxAmount,
      'p_source': source,
    });
    if (res is Map) return Bid.fromJson(Map<String, dynamic>.from(res));
    if (res is List && res.isNotEmpty && res.first is Map) {
      return Bid.fromJson(Map<String, dynamic>.from(res.first as Map));
    }
    throw StateError('place_bid_unexpected_shape');
  }

  /// Fetches the most recent bids on a listing from the pseudonymized
  /// `listing_bid_feed` view.  Limited to the last [limit] rows ordered
  /// most-recent-first.
  Future<List<Bid>> fetchBidFeed(String listingId, {int limit = 25}) async {
    final rows = await _client
        .from('listing_bid_feed')
        .select()
        .eq('listing_id', listingId)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows
        .map<Bid>((r) => Bid.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList(growable: false);
  }
}

final biddingRepositoryProvider = Provider<BiddingRepository>(
  (ref) => BiddingRepository(Supabase.instance.client),
);

/// Normalized error code parsed from Supabase Postgres exceptions.  The RPC
/// raises with `raise exception '<code>'`; postgrest surfaces the message
/// on `PostgrestException.message`.  We strip the surrounding noise so the
/// UI can switch on the bare code.
String parseBidError(Object e) {
  final raw = e is PostgrestException ? e.message : e.toString();
  for (final code in const [
    'unauthenticated',
    'invalid_source',
    'invalid_amount',
    'max_amount_below_amount',
    'rate_limited',
    'listing_not_found',
    'listing_not_active',
    'listing_not_biddable',
    'listing_closed',
    'self_bid_forbidden',
    'profile_not_found',
    'kyc_tier_1_required',
    'bid_exceeds_tier_ceiling',
    'max_amount_exceeds_tier_ceiling',
    'seller_not_reviewed',
    'bid_too_low',
  ]) {
    if (raw.contains(code)) return code;
  }
  return 'unknown';
}
