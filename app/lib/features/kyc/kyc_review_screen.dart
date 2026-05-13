import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/features/auth/data/auth_providers.dart';
import 'package:mazad/features/kyc/data/kyc_state.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

class KycReviewScreen extends ConsumerStatefulWidget {
  const KycReviewScreen({super.key});

  @override
  ConsumerState<KycReviewScreen> createState() => _KycReviewScreenState();
}

class _KycReviewScreenState extends ConsumerState<KycReviewScreen> {
  final _name = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = ProviderScope.containerOf(context, listen: false)
        .read(kycDraftProvider);
    _name.text = d.businessName ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_name.text.trim().length < 2) {
      setState(() => _error = l10n.commonRequired);
      return;
    }
    ref.read(kycDraftProvider.notifier).setBusinessName(_name.text.trim());
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await submitKycTier2(ref.read(kycDraftProvider));
      ref.invalidate(myProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.kycReviewSubmitted)),
      );
      ref.read(kycDraftProvider.notifier).reset();
      context.go('/dashboard');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.kycReviewSubmitFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final d = ref.watch(kycDraftProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.kycReviewTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(MazadTokens.sp5),
          child: ListView(
            children: [
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: l10n.kycReviewBusinessNameLabel,
                  hintText: l10n.kycReviewBusinessNameHint,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(MazadTokens.radiusSm),
                  ),
                ),
              ),
              const SizedBox(height: MazadTokens.sp5),
              _SummaryRow(label: l10n.kycIntroStep1, value: _idDocBadge(l10n, d)),
              _SummaryRow(label: l10n.kycAddressCityLabel, value: d.city ?? '—'),
              _SummaryRow(
                  label: l10n.kycPayoutTitle.split('?').first,
                  value: _payoutLabel(l10n, d.payoutMethod)),
              if (_error != null) ...[
                const SizedBox(height: MazadTokens.sp3),
                Text(_error!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: MazadTokens.error)),
              ],
              const SizedBox(height: MazadTokens.sp5),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: MazadTokens.sp3),
                          Text(l10n.kycReviewSubmitting),
                        ],
                      )
                    : Text(l10n.kycReviewSubmit),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Surface only an opaque indicator — never render the path.
  String _idDocBadge(AppLocalizations l10n, KycDraft d) =>
      d.idDocStoragePath != null ? '✓' : '—';

  String _payoutLabel(AppLocalizations l10n, String? method) {
    switch (method) {
      case 'zaincash':
        return l10n.kycPayoutZainCash;
      case 'fastpay':
        return l10n.kycPayoutFastPay;
      case 'bank':
        return l10n.kycPayoutBank;
      case 'cod':
        return l10n.kycPayoutCod;
      default:
        return '—';
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        vertical: MazadTokens.sp2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: MazadTokens.onSurfaceMuted)),
          ),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
