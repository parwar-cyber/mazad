import 'package:flutter/foundation.dart';

/// Mirror of a row in the `bids` table.  See
/// `supabase/migrations/20260512000001_initial_schema.sql` and the Phase 3
/// migration `20260514100001_phase3_bidding_engine.sql`.
///
/// Money fields are integers (IQD).  Never `double` (money-handling skill).
@immutable
class Bid {
  const Bid({
    required this.id,
    required this.listingId,
    required this.bidderId,
    required this.amount,
    required this.createdAt,
    this.maxAmount,
    this.isProxy = false,
    this.source = 'app',
    this.status = 'valid',
    this.bidderPseudonym,
    this.bidderCity,
  });

  final String id;
  final String listingId;
  final String bidderId;
  final int amount;
  final int? maxAmount;
  final bool isProxy;
  final String source;
  final String status;
  final DateTime createdAt;
  final String? bidderPseudonym;
  final String? bidderCity;

  factory Bid.fromJson(Map<String, dynamic> json) => Bid(
        id: (json['id'] ?? json['bid_id']) as String,
        listingId: json['listing_id'] as String,
        bidderId: (json['bidder_id'] ?? '') as String,
        amount: _asInt(json['amount']) ?? 0,
        maxAmount: _asInt(json['max_amount']),
        isProxy: (json['is_proxy'] ?? false) as bool,
        source: (json['source'] ?? 'app') as String,
        status: (json['status'] ?? 'valid') as String,
        createdAt: _asDate(json['created_at']) ?? DateTime.now(),
        bidderPseudonym: json['bidder_pseudonym'] as String?,
        bidderCity: json['bidder_city'] as String?,
      );
}

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

DateTime? _asDate(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
