import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/features/auth/data/auth_service.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

class PhoneSignupScreen extends ConsumerStatefulWidget {
  const PhoneSignupScreen({super.key});

  @override
  ConsumerState<PhoneSignupScreen> createState() => _PhoneSignupScreenState();
}

class _PhoneSignupScreenState extends ConsumerState<PhoneSignupScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _errorKey;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final raw = _controller.text;
    final normalized = normalizeIraqiPhone(raw);
    if (normalized == null) {
      setState(() => _errorKey = l10n.authPhoneInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _errorKey = null;
    });
    try {
      await ref.read(authServiceProvider).sendOtp(normalized);
      if (!mounted) return;
      context.push('/auth/otp', extra: normalized);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorKey = _localizeAuthError(e.kind, l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authPhoneTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(MazadTokens.sp5),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.authPhoneSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: MazadTokens.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: MazadTokens.sp6),
                TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  inputFormatters: [
                    // Phone input is system-level, not display: ASCII digits +
                    // a few separators. Pinned regardless of locale.
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[\d\+\-\(\)\s]'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.authPhoneLabel,
                    hintText: l10n.authPhoneHint,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(MazadTokens.radiusSm),
                    ),
                    errorText: _errorKey,
                  ),
                ),
                const SizedBox(height: MazadTokens.sp5),
                FilledButton(
                  onPressed: _busy ? null : _send,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.authPhoneSend),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _localizeAuthError(AuthErrorKind kind, AppLocalizations l10n) {
  switch (kind) {
    case AuthErrorKind.invalidPhone:
      return l10n.authPhoneInvalid;
    case AuthErrorKind.rateLimited:
      return l10n.authOtpRateLimited;
    case AuthErrorKind.invalidCode:
      return l10n.authOtpInvalid;
    case AuthErrorKind.expiredCode:
      return l10n.authOtpExpired;
    case AuthErrorKind.network:
    case AuthErrorKind.unknown:
      return l10n.commonGenericError;
  }
}
