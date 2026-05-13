import 'package:flutter/foundation.dart';

/// Global signal for "the backend rejected our version — show the blocking
/// force-update screen". Watched by the router; see `app_router.dart`.
class ForceUpdatePayload {
  const ForceUpdatePayload({
    this.minVersion,
    this.storeUrl,
    this.releaseNotes,
  });

  final String? minVersion;
  final String? storeUrl;
  final Map<String, dynamic>? releaseNotes;
}

class ForceUpdateNotifier extends ChangeNotifier {
  ForceUpdateNotifier._();
  static final instance = ForceUpdateNotifier._();

  ForceUpdatePayload? _payload;
  ForceUpdatePayload? get payload => _payload;
  bool get isActive => _payload != null;

  void trigger({
    String? minVersion,
    String? storeUrl,
    Map<String, dynamic>? releaseNotes,
  }) {
    _payload = ForceUpdatePayload(
      minVersion: minVersion,
      storeUrl: storeUrl,
      releaseNotes: releaseNotes,
    );
    notifyListeners();
  }
}
