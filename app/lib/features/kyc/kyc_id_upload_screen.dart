import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/features/kyc/data/kyc_state.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KycIdUploadScreen extends ConsumerStatefulWidget {
  const KycIdUploadScreen({super.key});

  @override
  ConsumerState<KycIdUploadScreen> createState() => _KycIdUploadScreenState();
}

class _KycIdUploadScreenState extends ConsumerState<KycIdUploadScreen> {
  bool _busy = false;
  String? _error;
  final _picker = ImagePicker();

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        imageQuality: 85,
      );
      if (picked == null) {
        setState(() => _busy = false);
        return;
      }
      ref
          .read(kycDraftProvider.notifier)
          .setIdDoc(File(picked.path));
    } catch (_) {
      setState(() => _error = AppLocalizations.of(context).commonGenericError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continue() async {
    final l10n = AppLocalizations.of(context);
    final draft = ref.read(kycDraftProvider);
    if (draft.idDocFile == null) {
      setState(() => _error = l10n.kycIdMissing);
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _error = l10n.commonGenericError);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Path-prefix MUST start with the user's UUID to satisfy storage RLS
      // and the path-prefix check in submit_kyc_tier2.
      final ext = _extensionOf(draft.idDocFile!.path);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final objectName = '${user.id}/id-$ts.$ext';

      await Supabase.instance.client.storage.from('kyc-docs').upload(
            objectName,
            draft.idDocFile!,
            fileOptions: const FileOptions(upsert: false),
          );
      ref.read(kycDraftProvider.notifier).setIdDocStoragePath(objectName);
      if (!mounted) return;
      context.push('/kyc/address');
    } catch (_) {
      setState(() => _error = l10n.kycIdUploadFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final draft = ref.watch(kycDraftProvider);
    final hasFile = draft.idDocFile != null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.kycIdTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(MazadTokens.sp5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.kycIdSubtitle,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: MazadTokens.onSurfaceMuted)),
              const SizedBox(height: MazadTokens.sp5),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: MazadTokens.surface,
                    border: Border.all(color: MazadTokens.outline),
                    borderRadius:
                        BorderRadius.circular(MazadTokens.radiusMd),
                  ),
                  alignment: Alignment.center,
                  child: hasFile
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(
                              MazadTokens.radiusMd),
                          child: Image.file(
                            draft.idDocFile!,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Icon(
                          Icons.badge_outlined,
                          size: 80,
                          color: MazadTokens.onSurfaceMuted,
                        ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: MazadTokens.sp3),
                Text(_error!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: MazadTokens.error)),
              ],
              const SizedBox(height: MazadTokens.sp4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _busy ? null : () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(l10n.kycIdPickFromCamera),
                    ),
                  ),
                  const SizedBox(width: MazadTokens.sp3),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _busy ? null : () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(l10n.kycIdPickFromGallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MazadTokens.sp4),
              FilledButton(
                onPressed: _busy || !hasFile ? null : _continue,
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
                          Text(l10n.kycIdUploading),
                        ],
                      )
                    : Text(l10n.kycIdContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return 'jpg';
    return path.substring(dot + 1).toLowerCase();
  }
}
