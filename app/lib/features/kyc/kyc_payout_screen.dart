import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/features/kyc/data/kyc_state.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

class KycPayoutScreen extends ConsumerStatefulWidget {
  const KycPayoutScreen({super.key});

  @override
  ConsumerState<KycPayoutScreen> createState() => _KycPayoutScreenState();
}

class _KycPayoutScreenState extends ConsumerState<KycPayoutScreen> {
  String _method = 'zaincash';
  final _account = TextEditingController();

  @override
  void initState() {
    super.initState();
    final d = ProviderScope.containerOf(context, listen: false)
        .read(kycDraftProvider);
    _method = d.payoutMethod ?? 'zaincash';
    _account.text = d.payoutAccount ?? '';
  }

  @override
  void dispose() {
    _account.dispose();
    super.dispose();
  }

  void _continue() {
    ref.read(kycDraftProvider.notifier).setPayout(
          method: _method,
          account: _account.text.trim(),
        );
    context.push('/kyc/review');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final options = <_PayoutOption>[
      _PayoutOption('zaincash', l10n.kycPayoutZainCash),
      _PayoutOption('fastpay', l10n.kycPayoutFastPay),
      _PayoutOption('bank', l10n.kycPayoutBank),
      _PayoutOption('cod', l10n.kycPayoutCod),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.kycPayoutTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(MazadTokens.sp5),
          child: ListView(
            children: [
              Text(l10n.kycPayoutSubtitle,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: MazadTokens.onSurfaceMuted)),
              const SizedBox(height: MazadTokens.sp4),
              ...options.map((o) => RadioListTile<String>(
                    value: o.value,
                    groupValue: _method,
                    onChanged: (v) {
                      if (v != null) setState(() => _method = v);
                    },
                    title: Text(o.label),
                    activeColor: MazadTokens.primary,
                  )),
              const SizedBox(height: MazadTokens.sp3),
              if (_method != 'cod')
                TextField(
                  controller: _account,
                  keyboardType: _method == 'bank'
                      ? TextInputType.text
                      : TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: l10n.kycPayoutAccountLabel,
                    hintText: l10n.kycPayoutAccountHint,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(MazadTokens.radiusSm),
                    ),
                  ),
                ),
              const SizedBox(height: MazadTokens.sp5),
              FilledButton(
                onPressed: _continue,
                child: Text(l10n.kycPayoutContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayoutOption {
  const _PayoutOption(this.value, this.label);
  final String value;
  final String label;
}
