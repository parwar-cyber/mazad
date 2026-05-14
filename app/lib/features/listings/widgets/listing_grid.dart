import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/features/listings/data/listing.dart';
import 'package:mazad/features/listings/widgets/listing_card.dart';

/// Responsive listing grid.  Columns scale with viewport width — 2 on
/// phones, 3 on tablet, 4 on wide web.
class ListingGrid extends StatelessWidget {
  const ListingGrid({super.key, required this.listings, this.shrinkWrap = false});

  final List<Listing> listings;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cols = w >= 1100 ? 4 : (w >= 760 ? 3 : 2);
        return GridView.builder(
          padding: const EdgeInsetsDirectional.all(MazadTokens.sp4),
          physics: shrinkWrap
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          shrinkWrap: shrinkWrap,
          itemCount: listings.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: MazadTokens.sp3,
            mainAxisSpacing: MazadTokens.sp3,
            childAspectRatio: 0.74,
          ),
          itemBuilder: (_, i) {
            final l = listings[i];
            return ListingCard(
              listing: l,
              onTap: () => context.push('/listings/${l.id}'),
            );
          },
        );
      },
    );
  }
}
