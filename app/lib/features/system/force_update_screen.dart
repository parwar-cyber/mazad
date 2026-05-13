import 'package:flutter/material.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/core/design/typography.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Blocking force-update screen. Cannot be dismissed.
/// Triggered by [VersionInterceptor] on a 426 response.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({
    super.key,
    this.storeUrl,
    this.releaseNotes,
  });

  final String? storeUrl;
  final Map<String, dynamic>? releaseNotes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    final notes = _localizedNotes(lang);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: MazadTokens.sp5,
              vertical: MazadTokens.sp6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                _UpdateGlyph(),
                const SizedBox(height: MazadTokens.sp5),
                Text(
                  l10n.updateRequiredTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: MazadTokens.sp3),
                Text(
                  l10n.updateRequiredBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: MazadTokens.onSurfaceMuted,
                  ),
                ),
                if (notes != null) ...[
                  const SizedBox(height: MazadTokens.sp5),
                  _ReleaseNotesCard(notes: notes),
                ],
                const Spacer(),
                FilledButton(
                  onPressed: storeUrl == null
                      ? null
                      : () => launchUrl(
                            Uri.parse(storeUrl!),
                            mode: LaunchMode.externalApplication,
                          ),
                  child: Text(
                    l10n.updateNow,
                    style: tabularNumeric(
                      theme.textTheme.labelLarge ?? const TextStyle(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _localizedNotes(String lang) {
    if (releaseNotes == null) return null;
    final fromLocale = releaseNotes![lang];
    if (fromLocale is String && fromLocale.isNotEmpty) return fromLocale;
    for (final fallback in const ['en', 'ar', 'ku', 'tr']) {
      final v = releaseNotes![fallback];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }
}

class _UpdateGlyph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: MazadTokens.primary.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: MazadTokens.primary, width: 2),
        ),
        child: const Icon(
          Icons.system_update_alt_rounded,
          size: 40,
          color: MazadTokens.primary,
        ),
      ),
    );
  }
}

class _ReleaseNotesCard extends StatelessWidget {
  const _ReleaseNotesCard({required this.notes});
  final String notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.all(MazadTokens.sp4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(MazadTokens.radiusMd),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Text(
        notes,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
