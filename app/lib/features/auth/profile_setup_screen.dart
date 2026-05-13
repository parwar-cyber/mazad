import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/core/i18n/locale_provider.dart';
import 'package:mazad/features/auth/data/auth_providers.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  late String _locale;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Default to the locale the app is already showing.
    _locale = ProviderScope.containerOf(context, listen: false)
        .read(localeProvider)
        .languageCode;
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_name.text.trim().isEmpty) {
      setState(() => _error = l10n.commonRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.rpc('update_profile', params: {
        'p_display_name': _name.text.trim(),
        'p_locale': _locale,
        'p_city': _city.text.trim(),
      });
      // Sync the in-memory locale provider so the UI flips immediately if
      // the user picked a different language during setup.
      ref.read(localeProvider.notifier).state = Locale(_locale);
      ref.invalidate(myProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileSaved)),
      );
      context.go('/dashboard');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.commonGenericError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileSetupTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(MazadTokens.sp5),
          child: ListView(
            children: [
              Text(
                l10n.profileSetupSubtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: MazadTokens.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: MazadTokens.sp5),
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: l10n.profileDisplayNameLabel,
                  hintText: l10n.profileDisplayNameHint,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(MazadTokens.radiusSm),
                  ),
                  errorText: _error,
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: MazadTokens.sp4),
              DropdownButtonFormField<String>(
                value: _locale,
                decoration: InputDecoration(
                  labelText: l10n.profileLocaleLabel,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(MazadTokens.radiusSm),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'ar', child: Text('العربية')),
                  DropdownMenuItem(value: 'ku', child: Text('کوردی')),
                  DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _locale = v);
                },
              ),
              const SizedBox(height: MazadTokens.sp4),
              TextField(
                controller: _city,
                decoration: InputDecoration(
                  labelText: l10n.profileCityLabel,
                  hintText: l10n.profileCityHint,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(MazadTokens.radiusSm),
                  ),
                ),
              ),
              const SizedBox(height: MazadTokens.sp6),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.profileSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
