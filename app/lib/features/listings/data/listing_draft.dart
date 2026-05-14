import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazad/features/listings/data/ai_suggestion.dart';
import 'package:mazad/features/listings/data/listing.dart';
import 'package:mazad/features/listings/data/listing_repository.dart';

/// In-memory state shared across the multi-step listing-creation flow.
/// Cleared on completion or when the user backs out of the entry screen.
@immutable
class ListingDraft {
  const ListingDraft({
    this.type = 'fixed',
    this.serverListing,
    this.localPhotos = const <File>[],
    this.uploadedPaths = const <String>[],
    this.suggestion,
    this.titleEn = '',
    this.titleAr = '',
    this.titleKu = '',
    this.titleTr = '',
    this.descEn = '',
    this.descAr = '',
    this.descKu = '',
    this.descTr = '',
    this.categoryId,
    this.condition,
    this.startingPriceIqd = 0,
    this.buyNowPriceIqd,
    this.reservePriceIqd,
  });

  final String type; // 'auction' | 'fixed' | 'bazaar'
  final Listing? serverListing; // hydrated after create_listing_draft
  final List<File> localPhotos; // local files chosen but not yet uploaded
  final List<String> uploadedPaths; // storage object names returned by upload
  final AiListingSuggestion? suggestion;

  final String titleEn;
  final String titleAr;
  final String titleKu;
  final String titleTr;

  final String descEn;
  final String descAr;
  final String descKu;
  final String descTr;

  final String? categoryId;
  final String? condition;

  final int startingPriceIqd;
  final int? buyNowPriceIqd;
  final int? reservePriceIqd;

  Map<String, String> get titleMap => {
        if (titleEn.trim().isNotEmpty) 'en': titleEn.trim(),
        if (titleAr.trim().isNotEmpty) 'ar': titleAr.trim(),
        if (titleKu.trim().isNotEmpty) 'ku': titleKu.trim(),
        if (titleTr.trim().isNotEmpty) 'tr': titleTr.trim(),
      };

  Map<String, String> get descriptionMap => {
        if (descEn.trim().isNotEmpty) 'en': descEn.trim(),
        if (descAr.trim().isNotEmpty) 'ar': descAr.trim(),
        if (descKu.trim().isNotEmpty) 'ku': descKu.trim(),
        if (descTr.trim().isNotEmpty) 'tr': descTr.trim(),
      };

  bool get allLocalesFilled =>
      titleMap.length == 4 && descriptionMap.length == 4;

  ListingDraft copyWith({
    String? type,
    Listing? serverListing,
    List<File>? localPhotos,
    List<String>? uploadedPaths,
    AiListingSuggestion? suggestion,
    String? titleEn,
    String? titleAr,
    String? titleKu,
    String? titleTr,
    String? descEn,
    String? descAr,
    String? descKu,
    String? descTr,
    String? categoryId,
    String? condition,
    int? startingPriceIqd,
    int? buyNowPriceIqd,
    int? reservePriceIqd,
    bool clearReserve = false,
    bool clearBuyNow = false,
  }) =>
      ListingDraft(
        type: type ?? this.type,
        serverListing: serverListing ?? this.serverListing,
        localPhotos: localPhotos ?? this.localPhotos,
        uploadedPaths: uploadedPaths ?? this.uploadedPaths,
        suggestion: suggestion ?? this.suggestion,
        titleEn: titleEn ?? this.titleEn,
        titleAr: titleAr ?? this.titleAr,
        titleKu: titleKu ?? this.titleKu,
        titleTr: titleTr ?? this.titleTr,
        descEn: descEn ?? this.descEn,
        descAr: descAr ?? this.descAr,
        descKu: descKu ?? this.descKu,
        descTr: descTr ?? this.descTr,
        categoryId: categoryId ?? this.categoryId,
        condition: condition ?? this.condition,
        startingPriceIqd: startingPriceIqd ?? this.startingPriceIqd,
        buyNowPriceIqd:
            clearBuyNow ? null : (buyNowPriceIqd ?? this.buyNowPriceIqd),
        reservePriceIqd:
            clearReserve ? null : (reservePriceIqd ?? this.reservePriceIqd),
      );
}

class ListingDraftNotifier extends StateNotifier<ListingDraft> {
  ListingDraftNotifier() : super(const ListingDraft());

  void setType(String t) {
    // Bazaar listings cap at 10,000 IQD — surfaced again on the price step,
    // but if a previously-set price is above 10k we drop it on type switch.
    state = state.copyWith(
      type: t,
      startingPriceIqd:
          (t == 'bazaar' && state.startingPriceIqd > 10000) ? 0 : null,
    );
  }

  void setServerListing(Listing l) => state = state.copyWith(serverListing: l);

  void setLocalPhotos(List<File> files) =>
      state = state.copyWith(localPhotos: files);

  void setUploadedPaths(List<String> paths) =>
      state = state.copyWith(uploadedPaths: paths);

  /// Applies an AI suggestion in full. The user can still edit individual
  /// fields afterward via the review screen.
  void applySuggestion(AiListingSuggestion s, {String? categoryId}) {
    state = state.copyWith(
      suggestion: s,
      titleEn: s.title['en'] ?? state.titleEn,
      titleAr: s.title['ar'] ?? state.titleAr,
      titleKu: s.title['ku'] ?? state.titleKu,
      titleTr: s.title['tr'] ?? state.titleTr,
      descEn: s.description['en'] ?? state.descEn,
      descAr: s.description['ar'] ?? state.descAr,
      descKu: s.description['ku'] ?? state.descKu,
      descTr: s.description['tr'] ?? state.descTr,
      condition: s.condition,
      categoryId: categoryId ?? state.categoryId,
      // For auctions/bazaars, suggested price becomes starting; for fixed,
      // we route it to buy-now so the fixed-flow doesn't show 0.
      startingPriceIqd: state.type == 'fixed'
          ? state.startingPriceIqd
          : s.suggestedStartingPriceIqd,
      buyNowPriceIqd: state.type == 'fixed'
          ? s.suggestedStartingPriceIqd
          : state.buyNowPriceIqd,
    );
  }

  void setTitle(String locale, String value) {
    switch (locale) {
      case 'en':
        state = state.copyWith(titleEn: value);
        break;
      case 'ar':
        state = state.copyWith(titleAr: value);
        break;
      case 'ku':
        state = state.copyWith(titleKu: value);
        break;
      case 'tr':
        state = state.copyWith(titleTr: value);
        break;
    }
  }

  void setDescription(String locale, String value) {
    switch (locale) {
      case 'en':
        state = state.copyWith(descEn: value);
        break;
      case 'ar':
        state = state.copyWith(descAr: value);
        break;
      case 'ku':
        state = state.copyWith(descKu: value);
        break;
      case 'tr':
        state = state.copyWith(descTr: value);
        break;
    }
  }

  void setCategory(String? id) => state = state.copyWith(categoryId: id);
  void setCondition(String c) => state = state.copyWith(condition: c);

  void setStartingPrice(int v) => state = state.copyWith(startingPriceIqd: v);
  void setBuyNowPrice(int? v) =>
      state = v == null
          ? state.copyWith(clearBuyNow: true)
          : state.copyWith(buyNowPriceIqd: v);
  void setReservePrice(int? v) =>
      state = v == null
          ? state.copyWith(clearReserve: true)
          : state.copyWith(reservePriceIqd: v);

  void reset() => state = const ListingDraft();
}

final listingDraftProvider =
    StateNotifierProvider<ListingDraftNotifier, ListingDraft>((ref) {
  return ListingDraftNotifier();
});

/// Persists the draft state to the server via `update_listing_draft`.
/// Idempotent — sends every field the form has currently set.
Future<Listing> persistDraft({
  required ListingRepository repo,
  required ListingDraft draft,
}) async {
  final id = draft.serverListing?.id;
  if (id == null) {
    throw StateError('draft_not_yet_created_on_server');
  }
  return repo.updateDraft(
    id: id,
    title: draft.titleMap,
    description: draft.descriptionMap,
    categoryId: draft.categoryId,
    condition: draft.condition,
    imagePaths: draft.uploadedPaths,
    startingPrice: draft.type == 'fixed' ? null : draft.startingPriceIqd,
    buyNowPrice: draft.type == 'fixed' ? draft.buyNowPriceIqd : null,
    reservePrice: draft.type == 'auction' ? draft.reservePriceIqd : null,
  );
}
