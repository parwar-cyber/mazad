import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazad/features/listings/data/category.dart';
import 'package:mazad/features/listings/data/listing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase calls. Pure repository — no widget code.
class ListingRepository {
  ListingRepository(this._client);
  final SupabaseClient _client;

  // ─── Categories ────────────────────────────────────────────────────────
  Future<List<ListingCategory>> fetchCategories() async {
    final rows = await _client
        .from('categories')
        .select('id, slug, name_translations')
        .order('slug');
    return rows
        .map<ListingCategory>(
            (e) => ListingCategory.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  // ─── Drafts / mutations ────────────────────────────────────────────────
  Future<Listing> createDraft(String type) async {
    final res = await _client.rpc('create_listing_draft', params: {
      'p_type': type,
    });
    // RPC returns a single row (composite type) as a Map.
    return _coerceRow(res);
  }

  Future<Listing> updateDraft({
    required String id,
    Map<String, String>? title,
    Map<String, String>? description,
    String? categoryId,
    String? condition,
    Map<String, dynamic>? specs,
    List<String>? imagePaths,
    int? startingPrice,
    int? buyNowPrice,
    int? reservePrice,
    Map<String, dynamic>? location,
  }) async {
    final params = <String, dynamic>{'p_id': id};
    if (title != null) params['p_title_translations'] = title;
    if (description != null) params['p_description_translations'] = description;
    if (categoryId != null) params['p_category_id'] = categoryId;
    if (condition != null) params['p_condition'] = condition;
    if (specs != null) params['p_specs'] = specs;
    if (imagePaths != null) params['p_images'] = imagePaths;
    if (startingPrice != null) params['p_starting_price'] = startingPrice;
    if (buyNowPrice != null) params['p_buy_now_price'] = buyNowPrice;
    if (reservePrice != null) params['p_reserve_price'] = reservePrice;
    if (location != null) params['p_location'] = location;
    final res = await _client.rpc('update_listing_draft', params: params);
    return _coerceRow(res);
  }

  Future<Listing> publish(String id) async {
    final res = await _client.rpc('publish_listing', params: {'p_id': id});
    return _coerceRow(res);
  }

  Future<void> cancel(String id) =>
      _client.rpc('cancel_listing', params: {'p_id': id});

  Future<void> bumpView(String id) =>
      _client.rpc('increment_listing_view', params: {'p_id': id});

  // ─── Photo upload ──────────────────────────────────────────────────────
  /// Uploads a local file to listing-photos under
  /// `<seller_uid>/<listing_id>/photo-<idx>.<ext>` and returns the storage
  /// path. The caller is responsible for storing that path on the draft
  /// via [updateDraft] (so the Phase 2 RPC re-validates the prefix).
  Future<String> uploadPhoto({
    required String sellerId,
    required String listingId,
    required File file,
    required int index,
  }) async {
    final ext = _extOf(file.path);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final objectName = '$sellerId/$listingId/photo-$index-$ts.$ext';
    await _client.storage.from('listing-photos').upload(
          objectName,
          file,
          fileOptions: FileOptions(
            upsert: false,
            contentType: _mimeFromExt(ext),
          ),
        );
    return objectName;
  }

  String publicUrlFor(String path) =>
      _client.storage.from('listing-photos').getPublicUrl(path);

  // ─── Read flows ────────────────────────────────────────────────────────
  Future<Listing?> fetchById(String id) async {
    final row = await _client
        .from('listings')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return Listing.fromJson(row);
  }

  Future<List<Listing>> myListings(String userId) async {
    final rows = await _client
        .from('listings')
        .select()
        .eq('seller_id', userId)
        .order('created_at', ascending: false);
    return rows
        .map<Listing>((e) => Listing.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<Listing>> search({
    String? query,
    String? categoryId,
    String? type,
    bool? hasBuyNow,
    int? minPrice,
    int? maxPrice,
    int limit = 24,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'p_query': (query == null || query.trim().isEmpty) ? null : query.trim(),
      'p_category_id': categoryId,
      'p_type': type,
      'p_has_buy_now': hasBuyNow,
      'p_min_price': minPrice,
      'p_max_price': maxPrice,
      'p_limit': limit,
      'p_offset': offset,
    };
    final res = await _client.rpc('search_listings', params: params);
    return _coerceList(res);
  }

  Future<List<Listing>> endingSoon({int limit = 12}) async {
    final res = await _client
        .rpc('home_feed_ending_soon', params: {'p_limit': limit});
    return _coerceList(res);
  }

  Future<List<Listing>> hot({int limit = 12}) async {
    final res =
        await _client.rpc('home_feed_hot', params: {'p_limit': limit});
    return _coerceList(res);
  }

  Future<List<Listing>> bazaar({int limit = 12}) async {
    final res =
        await _client.rpc('home_feed_bazaar', params: {'p_limit': limit});
    return _coerceList(res);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────
  Listing _coerceRow(Object? res) {
    if (res is Map) return Listing.fromJson(Map<String, dynamic>.from(res));
    if (res is List && res.isNotEmpty && res.first is Map) {
      return Listing.fromJson(Map<String, dynamic>.from(res.first as Map));
    }
    throw StateError('listing_rpc_unexpected_shape');
  }

  List<Listing> _coerceList(Object? res) {
    if (res is List) {
      return res
          .whereType<Map>()
          .map((m) => Listing.fromJson(Map<String, dynamic>.from(m)))
          .toList(growable: false);
    }
    return const <Listing>[];
  }

  String _extOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return 'jpg';
    final e = path.substring(dot + 1).toLowerCase();
    if (e == 'jpeg') return 'jpg';
    return e;
  }

  String _mimeFromExt(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}

final listingRepositoryProvider = Provider<ListingRepository>(
  (ref) => ListingRepository(Supabase.instance.client),
);
