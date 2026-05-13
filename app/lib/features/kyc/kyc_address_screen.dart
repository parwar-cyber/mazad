import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/features/kyc/data/kyc_state.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

class KycAddressScreen extends ConsumerStatefulWidget {
  const KycAddressScreen({super.key});

  @override
  ConsumerState<KycAddressScreen> createState() => _KycAddressScreenState();
}

class _KycAddressScreenState extends ConsumerState<KycAddressScreen> {
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _gov = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = ProviderScope.containerOf(context, listen: false)
        .read(kycDraftProvider);
    _line1.text = d.line1 ?? '';
    _line2.text = d.line2 ?? '';
    _city.text = d.city ?? '';
    _gov.text = d.governorate ?? '';
  }

  @override
  void dispose() {
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _gov.dispose();
    super.dispose();
  }

  void _continue() {
    final l10n = AppLocalizations.of(context);
    if (_line1.text.trim().isEmpty || _city.text.trim().isEmpty) {
      setState(() => _error = l10n.kycAddressMissing);
      return;
    }
    ref.read(kycDraftProvider.notifier).setAddress(
          line1: _line1.text.trim(),
          line2: _line2.text.trim(),
          city: _city.text.trim(),
          governorate: _gov.text.trim(),
        );
    context.push('/kyc/payout');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MazadTokens.radiusSm),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.kycAddressTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(MazadTokens.sp5),
          child: ListView(
            children: [
              Text(l10n.kycAddressSubtitle,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: MazadTokens.onSurfaceMuted)),
              const SizedBox(height: MazadTokens.sp5),
              TextField(
                controller: _line1,
                decoration: deco(l10n.kycAddressLine1Label),
              ),
              const SizedBox(height: MazadTokens.sp3),
              TextField(
                controller: _line2,
                decoration: deco(l10n.kycAddressLine2Label),
              ),
              const SizedBox(height: MazadTokens.sp3),
              TextField(
                controller: _city,
                decoration: deco(l10n.kycAddressCityLabel),
              ),
              const SizedBox(height: MazadTokens.sp3),
              TextField(
                controller: _gov,
                decoration: deco(l10n.kycAddressGovernorateLabel),
              ),
              if (_error != null) ...[
                const SizedBox(height: MazadTokens.sp3),
                Text(_error!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: MazadTokens.error)),
              ],
              const SizedBox(height: MazadTokens.sp5),
              FilledButton(
                onPressed: _continue,
                child: Text(l10n.kycAddressContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
