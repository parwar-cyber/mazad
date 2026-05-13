import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/features/auth/data/auth_service.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key, required this.phone});
  final String phone; // E.164

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _errorKey;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context);
    final code = _controller.text.trim();
    if (code.length != 6) {
      setState(() => _errorKey = l10n.authOtpInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _errorKey = null;
    });
    try {
      final session = await ref
          .read(authServiceProvider)
          .verifyOtp(e164Phone: widget.phone, code: code);
      if (session != null && mounted) {
        // Profile-setup gating happens in the router redirect. Pop to root
        // and let the redirect logic land us on the right screen.
        context.go('/');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorKey = _localize(e.kind, l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _errorKey = null;
    });
    try {
      await ref.read(authServiceProvider).sendOtp(widget.phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.authOtpResend)),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorKey = _localize(e.kind, l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authOtpTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(MazadTokens.sp5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.authOtpSubtitle(widget.phone),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: MazadTokens.onSurfaceMuted,
                ),
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: MazadTokens.sp6),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                maxLength: 6,
                style: theme.textTheme.headlineMedium?.copyWith(
                  letterSpacing: 8,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: l10n.authOtpLabel,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(MazadTokens.radiusSm),
                  ),
                  errorText: _errorKey,
                  counterText: '',
                ),
              ),
              const SizedBox(height: MazadTokens.sp5),
              FilledButton(
                onPressed: _busy ? null : _verify,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.authOtpVerify),
              ),
              const SizedBox(height: MazadTokens.sp3),
              TextButton(
                onPressed: _busy ? null : _resend,
                child: Text(l10n.authOtpResend),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _localize(AuthErrorKind kind, AppLocalizations l10n) {
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
