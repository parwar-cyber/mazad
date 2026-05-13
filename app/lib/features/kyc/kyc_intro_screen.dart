import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/features/kyc/data/kyc_state.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KycIntroScreen extends ConsumerWidget {
  const KycIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.kycIntroTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(MazadTokens.sp5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.kycIntroSubtitle,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: MazadTokens.onSurfaceMuted),
              ),
              const SizedBox(height: MazadTokens.sp6),
              _StepRow(index: 1, label: l10n.kycIntroStep1),
              const SizedBox(height: MazadTokens.sp3),
              _StepRow(index: 2, label: l10n.kycIntroStep2),
              const SizedBox(height: MazadTokens.sp3),
              _StepRow(index: 3, label: l10n.kycIntroStep3),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  // Reset any prior draft and record analytics intent.
                  ref.read(kycDraftProvider.notifier).reset();
                  // Best-effort intent log; don't block on failures.
                  unawaited(_logIntent());
                  if (context.mounted) context.push('/kyc/id');
                },
                child: Text(l10n.kycIntroBegin),
              ),
              const SizedBox(height: MazadTokens.sp3),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(l10n.kycIntroCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _logIntent() async {
  try {
    await Supabase.instance.client.rpc('request_seller_upgrade');
  } catch (_) {/* analytics-only; ignore */}
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.index, required this.label});
  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MazadTokens.primary.withValues(alpha: 0.12),
            border: Border.all(color: MazadTokens.primary, width: 1),
          ),
          child: Text('$index',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: MazadTokens.primary)),
        ),
        const SizedBox(width: MazadTokens.sp4),
        Expanded(
          child: Text(label, style: theme.textTheme.bodyLarge),
        ),
      ],
    );
  }
}
