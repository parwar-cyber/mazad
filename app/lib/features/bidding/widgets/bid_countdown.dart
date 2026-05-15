import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/core/design/typography.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

/// Live countdown for a listing.  Distinguishes Discovery (48h post-publish)
/// from Smart Close (12h-from-last-bid) phases so the buyer knows whether
/// each new bid resets the clock.  Tabular numerics — no horizontal jitter.
class BidCountdown extends StatefulWidget {
  const BidCountdown({
    super.key,
    required this.currentCloseAt,
    required this.discoveryEndsAt,
    required this.hardCloseAt,
  });

  final DateTime currentCloseAt;
  final DateTime? discoveryEndsAt;
  final DateTime? hardCloseAt;

  @override
  State<BidCountdown> createState() => _BidCountdownState();
}

class _BidCountdownState extends State<BidCountdown> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(BidCountdown old) {
    super.didUpdateWidget(old);
    if (old.currentCloseAt != widget.currentCloseAt) _tick();
  }

  void _tick() {
    final now = DateTime.now();
    final r = widget.currentCloseAt.difference(now);
    if (mounted) setState(() => _remaining = r.isNegative ? Duration.zero : r);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final inDiscovery =
        widget.discoveryEndsAt != null && now.isBefore(widget.discoveryEndsAt!);
    final closed = _remaining == Duration.zero;

    final label = closed
        ? l10n.biddingCountdownClosed
        : inDiscovery
            ? l10n.biddingCountdownDiscoveryLabel
            : l10n.biddingCountdownSmartCloseLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium
              ?.copyWith(color: MazadTokens.onSurfaceMuted),
        ),
        const SizedBox(height: MazadTokens.sp1),
        Text(
          closed ? '—' : _format(_remaining),
          style: tabularNumeric(theme.textTheme.headlineMedium!).copyWith(
            color: closed ? MazadTokens.error : MazadTokens.onSurface,
          ),
        ),
      ],
    );
  }

  String _format(Duration d) {
    final h = NumberFormat('00').format(d.inHours);
    final m = NumberFormat('00').format(d.inMinutes.remainder(60));
    final s = NumberFormat('00').format(d.inSeconds.remainder(60));
    final days = d.inDays;
    if (days > 0) {
      final hr = d.inHours.remainder(24);
      // Localization for "d days h hours" stays simple — no plural rules
      // in the timer surface for now; the Phase 5 notifications layer is
      // where we'll need full ICU plural.
      return '${days}d ${NumberFormat('00').format(hr)}:$m:$s';
    }
    return '$h:$m:$s';
  }
}
