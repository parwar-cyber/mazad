import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/features/listings/data/listing.dart';
import 'package:mazad/features/listings/widgets/listing_card.dart';

/// Horizontal-scrolling section row used on the home feed.
class HorizontalListingRow extends StatelessWidget {
  const HorizontalListingRow({
    super.key,
    required this.title,
    required this.listings,
    this.seeAllRoute,
    this.seeAllLabel,
  });

  final String title;
  final List<Listing> listings;
  final String? seeAllRoute;
  final String? seeAllLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: MazadTokens.sp5,
            vertical: MazadTokens.sp3,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(title, style: theme.textTheme.headlineSmall),
              ),
              if (seeAllRoute != null && seeAllLabel != null)
                TextButton(
                  onPressed: () => context.push(seeAllRoute!),
                  child: Text(seeAllLabel!),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 280,
          child: listings.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: MazadTokens.sp5,
                  ),
                  itemCount: listings.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: MazadTokens.sp3),
                  itemBuilder: (_, i) {
                    final l = listings[i];
                    return SizedBox(
                      width: 200,
                      child: ListingCard(
                        listing: l,
                        onTap: () => context.push('/listings/${l.id}'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 32,
        color: MazadTokens.onSurfaceMuted,
      ),
    );
  }
}
