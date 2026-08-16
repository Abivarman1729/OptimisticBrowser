import 'package:webview_flutter/webview_flutter.dart';

enum PrivacyCapabilityStatus { enforced, bestEffort, platformRequired }

class PrivacySnapshot {
  const PrivacySnapshot({
    this.trackersBlocked = 0,
    this.httpsOnly = true,
    this.secureDns = false,
    this.thirdPartyCookiesBlocked = false,
    this.fingerprintProtection = false,
    this.webrtcProtection = false,
    this.privateStorageIsolation = PrivacyCapabilityStatus.platformRequired,
  });

  final int trackersBlocked;
  final bool httpsOnly;
  final bool secureDns;
  final bool thirdPartyCookiesBlocked;
  final bool fingerprintProtection;
  final bool webrtcProtection;
  final PrivacyCapabilityStatus privateStorageIsolation;
}

/// Privacy policy that is safe to use with the public webview_flutter API.
///
/// IMPORTANT: webview_flutter does not expose an isolated cookie/storage
/// profile. Clearing cookies, cache or local storage is global on the
/// platform WebView and can destroy normal browsing state. Therefore private
/// tabs in this engine are deliberately history/session/bookmark-private only.
/// No destructive global cleanup is performed when a private tab opens/closes.
///
/// Full browser-grade private storage isolation requires a native engine or
/// a WebView implementation that exposes independent profiles.
class PrivacyService {
  const PrivacyService();

  PrivacySnapshot snapshot({int trackersBlocked = 0}) =>
      PrivacySnapshot(trackersBlocked: trackersBlocked);

  Future<void> preparePrivateSession(WebViewController controller) async {
    // No-op by design. Public webview_flutter has no per-profile storage API.
    // Keeping this method makes the native-profile migration boundary explicit.
  }

  Future<void> endPrivateSession(WebViewController controller) async {
    // No-op by design. Never clear global cookies/cache/local-storage here.
  }

  bool get hasTrueProfileIsolation => false;

  String get privateModeDescription =>
      'Private tab: excludes history, bookmarks and persisted session state. '
      'Cookie/cache/local-storage isolation requires a native profile engine.';
}
