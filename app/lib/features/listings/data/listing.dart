import 'package:flutter/foundation.dart';

/// Listing row mirror. Keep in lockstep with
/// `supabase/migrations/20260512000001_initial_schema.sql` and the Phase 2
/// migration `20260514000002_phase2_listing_rpcs.sql`.
///
/// Money fields are `int` (IQD). Never `double` (money-handling skill).
@immutable
class Listing {
  const Listing({
    required this.id,
    required this.sellerId,
    required this.type,
    required this.titleTranslations,
    required this.descriptionTranslations,
    required this.status,
    required this.startingPrice,
    required this.images,
    required this.specs,
    this.categoryId,
    this.condition,
    this.buyNowPrice,
    this.reservePrice,
    this.currentHigh,
    this.currentCloseAt,
    this.publishedAt,
    this.videoVerified = false,
    this.bidCount = 0,
    this.viewCount = 0,
    this.watchCount = 0,
  });

  final String id;
  final String sellerId;
  final String type; // 'auction' | 'fixed' | 'bazaar'
  final String status; // 'draft' | 'pending_review' | 'active' | ...
  final Map<String, dynamic> titleTranslations;
  final Map<String, dynamic> descriptionTranslations;
  final String? categoryId;
  final String? condition; // 'new' | 'like_new' | 'good' | 'fair' | 'for_parts'
  final List<String> images; // storage paths
  final Map<String, dynamic> specs;
  final int startingPrice; // IQD
  final int? buyNowPrice; // IQD
  final int? reservePrice; // IQD
  final int? currentHigh; // IQD
  final DateTime? currentCloseAt;
  final DateTime? publishedAt;
  final bool videoVerified;
  final int bidCount;
  final int viewCount;
  final int watchCount;

  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
        id: json['id'] as String,
        sellerId: json['seller_id'] as String,
        type: json['type'] as String,
        status: (json['status'] ?? 'draft') as String,
        titleTranslations: _asMap(json['title_translations']),
        descriptionTranslations: _asMap(json['description_translations']),
        categoryId: json['category_id'] as String?,
        condition: json['condition'] as String?,
        images: _asStringList(json['images']),
        specs: _asMap(json['specs']),
        startingPrice: _asInt(json['starting_price']) ?? 0,
        buyNowPrice: _asInt(json['buy_now_price']),
        reservePrice: _asInt(json['reserve_price']),
        currentHigh: _asInt(json['current_high']),
        currentCloseAt: _asDate(json['current_close_at']),
        publishedAt: _asDate(json['published_at']),
        videoVerified: (json['video_verified'] ?? false) as bool,
        bidCount: _asInt(json['bid_count']) ?? 0,
        viewCount: _asInt(json['view_count']) ?? 0,
        watchCount: _asInt(json['watch_count']) ?? 0,
      );

  bool get isPublishable =>
      status == 'draft' &&
      images.isNotEmpty &&
      categoryId != null &&
      condition != null &&
      _hasAllLocales(titleTranslations) &&
      _hasAllLocales(descriptionTranslations) &&
      (type == 'fixed'
          ? (buyNowPrice != null && buyNowPrice! > 0)
          : (startingPrice > 0));

  /// Display price (IQD as int). Buy-now price for fixed, current high or
  /// starting price for auction/bazaar. Always integer — formatters wrap
  /// this through `formatIQD`.
  int get displayPrice {
    if (type == 'fixed') return buyNowPrice ?? 0;
    return currentHigh ?? startingPrice;
  }
}

bool _hasAllLocales(Map<String, dynamic> m) {
  for (final loc in const ['en', 'ar', 'ku', 'tr']) {
    final v = m[loc];
    if (v is! String || v.trim().isEmpty) return false;
  }
  return true;
}

Map<String, dynamic> _asMap(Object? v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return <String, dynamic>{};
}

List<String> _asStringList(Object? v) {
  if (v is List) {
    return v.whereType<String>().toList(growable: false);
  }
  return const <String>[];
}

/// Coerces Supabase numeric returns. Bigint columns may arrive as `int`
/// or as `String` (postgrest sends as string when > 2^53 to preserve
/// precision in JS clients — we still want `int` in Dart).
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
