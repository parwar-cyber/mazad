import 'package:flutter/foundation.dart';

/// Mirrors the response shape of the `analyze_item` Edge Function.
/// Every locale string is guaranteed non-empty by the server validator.
@immutable
class AiListingSuggestion {
  const AiListingSuggestion({
    required this.categorySlug,
    required this.title,
    required this.description,
    required this.condition,
    required this.suggestedSpecs,
    required this.suggestedStartingPriceIqd,
    required this.redFlags,
  });

  final String categorySlug;
  final Map<String, String> title; // en/ar/ku/tr
  final Map<String, String> description; // en/ar/ku/tr
  final String condition; // new|like_new|good|fair|for_parts
  final Map<String, dynamic> suggestedSpecs;
  final int suggestedStartingPriceIqd; // IQD as int — money-handling skill
  final List<String> redFlags;

  factory AiListingSuggestion.fromJson(Map<String, dynamic> json) {
    final t = _stringMap(json['title']);
    final d = _stringMap(json['description']);
    final priceRaw = json['suggested_starting_price_iqd'];
    final price = switch (priceRaw) {
      int i => i,
      num n => n.toInt(),
      String s => int.tryParse(s) ?? 0,
      _ => 0,
    };
    final specs = json['suggested_specs'];
    return AiListingSuggestion(
      categorySlug: (json['category_slug'] ?? '') as String,
      title: t,
      description: d,
      condition: (json['condition'] ?? 'good') as String,
      suggestedSpecs: specs is Map
          ? Map<String, dynamic>.from(specs)
          : const <String, dynamic>{},
      suggestedStartingPriceIqd: price,
      redFlags: (json['red_flags'] is List)
          ? (json['red_flags'] as List).whereType<String>().toList()
          : const <String>[],
    );
  }

  static Map<String, String> _stringMap(Object? v) {
    if (v is! Map) return const {};
    final out = <String, String>{};
    for (final loc in const ['en', 'ar', 'ku', 'tr']) {
      final x = v[loc];
      if (x is String) out[loc] = x;
    }
    return out;
  }
}
