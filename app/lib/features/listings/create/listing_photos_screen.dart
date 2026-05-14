import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/features/listings/data/listing_draft.dart';
import 'package:mazad/features/listings/data/listing_repository.dart';
import 'package:mazad/l10n/generated/app_localizations.dart';

/// Step 2 — pick + upload photos.  Files are uploaded directly to the
/// listing-photos bucket under "<uid>/<listing_id>/" and the resulting
/// storage paths are stored on the draft via `update_listing_draft`.
class ListingPhotosScreen extends ConsumerStatefulWidget {
  const ListingPhotosScreen({super.key});

  @override
  ConsumerState<ListingPhotosScreen> createState() =>
      _ListingPhotosScreenState();
}

class _ListingPhotosScreenState extends ConsumerState<ListingPhotosScreen> {
  final _picker = ImagePicker();
  bool _busy = false;
  String? _error;

  static const int _minPhotos = 3;
  static const int _maxPhotos = 10;
  static const int _maxBytes = 4 * 1024 * 1024; // 4 MB per photo

  Future<void> _addPhotos(ImageSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final draft = ref.read(listingDraftProvider);
      final remaining = _maxPhotos - draft.localPhotos.length;
      if (remaining <= 0) {
        setState(() => _busy = false);
        return;
      }
      final picked = source == ImageSource.gallery
          ? await _picker.pickMultiImage(
              maxWidth: 2400, imageQuality: 85)
          : <XFile>[
              ...?await _picker
                  .pickImage(
                      source: ImageSource.camera,
                      maxWidth: 2400,
                      imageQuality: 85)
                  .then((v) => v == null ? null : [v])
            ];
      final files = picked
          .take(remaining)
          .map((x) => File(x.path))
          .where((f) => f.lengthSync() <= _maxBytes)
          .toList();
      if (files.isEmpty) {
        setState(() => _busy = false);
        return;
      }
      ref.read(listingDraftProvider.notifier).setLocalPhotos(
            [...draft.localPhotos, ...files],
          );
    } catch (_) {
      setState(() => _error = AppLocalizations.of(context).commonGenericError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _removePhoto(int index) {
    final draft = ref.read(listingDraftProvider);
    final list = List<File>.from(draft.localPhotos)..removeAt(index);
    ref.read(listingDraftProvider.notifier).setLocalPhotos(list);
  }

  Future<void> _upload() async {
    final l10n = AppLocalizations.of(context);
    final draft = ref.read(listingDraftProvider);
    if (draft.localPhotos.length < _minPhotos) {
      setState(() => _error = l10n.createListingPhotoMinError);
      return;
    }
    final listing = draft.serverListing;
    if (listing == null) {
      setState(() => _error = l10n.commonGenericError);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(listingRepositoryProvider);
      final paths = <String>[];
      for (var i = 0; i < draft.localPhotos.length; i++) {
        final p = await repo.uploadPhoto(
          sellerId: listing.sellerId,
          listingId: listing.id,
          file: draft.localPhotos[i],
          index: i,
        );
        paths.add(p);
      }
      ref.read(listingDraftProvider.notifier).setUploadedPaths(paths);
      // Persist paths to the draft row so analyze_item can read them.
      await repo.updateDraft(id: listing.id, imagePaths: paths);
      if (!mounted) return;
      context.push('/sell/ai');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.createListingPhotosFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final draft = ref.watch(listingDraftProvider);
    final hasEnough = draft.localPhotos.length >= _minPhotos;
    final atMax = draft.localPhotos.length >= _maxPhotos;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createListingPhotosTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(MazadTokens.sp5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.createListingPhotosSubtitle,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: MazadTokens.onSurfaceMuted),
              ),
              const SizedBox(height: MazadTokens.sp4),
              Text(
                l10n.createListingPhotosCount(draft.localPhotos.length),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: MazadTokens.onSurfaceMuted),
              ),
              const SizedBox(height: MazadTokens.sp3),
              Expanded(
                child: GridView.builder(
                  itemCount: draft.localPhotos.length + (atMax ? 0 : 1),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: MazadTokens.sp2,
                    mainAxisSpacing: MazadTokens.sp2,
                  ),
                  itemBuilder: (_, i) {
                    if (i == draft.localPhotos.length && !atMax) {
                      return _AddTile(
                        onCamera: _busy
                            ? null
                            : () => _addPhotos(ImageSource.camera),
                        onGallery: _busy
                            ? null
                            : () => _addPhotos(ImageSource.gallery),
                      );
                    }
                    return _PhotoTile(
                      file: draft.localPhotos[i],
                      onRemove: _busy ? null : () => _removePhoto(i),
                    );
                  },
                ),
              ),
              if (_error != null) ...[
                Text(_error!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: MazadTokens.error)),
                const SizedBox(height: MazadTokens.sp2),
              ],
              FilledButton(
                onPressed: _busy || !hasEnough ? null : _upload,
                child: _busy
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: MazadTokens.sp3),
                          Text(l10n.createListingPhotosUploading),
                        ],
                      )
                    : Text(l10n.createListingPhotosContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({this.onCamera, this.onGallery});
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: MazadTokens.surface,
        border: Border.all(color: MazadTokens.outline),
        borderRadius: BorderRadius.circular(MazadTokens.radiusMd),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onCamera,
            tooltip: l10n.createListingPhotoFromCamera,
            icon: const Icon(Icons.camera_alt_outlined,
                color: MazadTokens.primary),
          ),
          IconButton(
            onPressed: onGallery,
            tooltip: l10n.createListingPhotoFromGallery,
            icon: const Icon(Icons.photo_library_outlined,
                color: MazadTokens.primary),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.file, this.onRemove});
  final File file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(MazadTokens.radiusMd),
          child: Image.file(file, fit: BoxFit.cover),
        ),
        PositionedDirectional(
          top: 2,
          end: 2,
          child: IconButton.filledTonal(
            visualDensity: VisualDensity.compact,
            iconSize: 16,
            onPressed: onRemove,
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }
}
