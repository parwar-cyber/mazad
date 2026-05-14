import 'package:flutter/foundation.dart';

@immutable
class ListingCategory {
  const ListingCategory({
    required this.id,
    required this.slug,
    required this.nameTranslations,
  });

  final String id;
  final String slug;
  final Map<String, dynamic> nameTranslations;

  String localizedName(String lang) {
    final v = nameTranslations[lang];
    if (v is String && v.isNotEmpty) return v;
    for (final f in const ['en', 'ar', 'ku', 'tr']) {
      final fv = nameTranslations[f];
      if (fv is String && fv.isNotEmpty) return fv;
    }
    return slug;
  }

  factory ListingCategory.fromJson(Map<String, dynamic> json) =>
      ListingCategory(
        id: json['id'] as String,
        slug: json['slug'] as String,
        nameTranslations: json['name_translations'] is Map
            ? Map<String, dynamic>.from(json['name_translations'] as Map)
            : <String, dynamic>{},
      );
}
