import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/utils/url_policy.dart';
import 'browser_engine.dart';
import 'engine_capabilities.dart';

/// V10 Flutter-side adapter.
///
/// Flutter owns UI, navigation state and the controller lifecycle.
/// Android-native code owns Chromium/WebView capabilities that Flutter's
/// public controller API does not expose (profiles, interception, blocking).
class WebViewBrowserEngine implements BrowserEngine {
  WebViewBrowserEngine(
    this.controller, {
    this.mode = EngineProfileMode.normal,
    this.profileId = 'default',
  });

  final WebViewController controller;

  @override
  final EngineProfileMode mode;

  @override
  final String profileId;

  @override
  bool initialized = false;

  @override
  final EngineCapabilities capabilities = const EngineCapabilities(
    engineName: 'Chromium Android System WebView',
    engineVersion: 'AndroidX WebKit multi-profile + webview_flutter 4.13.x',
    supportsJavaScript: true,
    supportsDownloads: true,
    supportsFileUpload: true,
    supportsPrivateHistoryIsolation: true,
    supportsPerProfileCookies: true,
    supportsPerProfileCache: true,
    supportsPerProfileLocalStorage: true,
    supportsNetworkInterception: true,
    supportsContentBlocking: true,
  );

  @override
  Future<void> initialize() async {
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setBackgroundColor(const Color(0x00000000));
    initialized = true;
  }

  @override
  Future<void> setUserAgent(String userAgent) async {
    await controller.setUserAgent(userAgent);
  }

  @override
  bool canNavigate(Uri uri) => UrlPolicy.isSafeNavigation(uri);

  @override
  Future<void> clearPrivateSession() async {
    // Storage clearing for a specific profile is performed by the native
    // Android profile service, not by the global Flutter WebView controller.
  }

  @override
  Future<void> clearBrowsingData() async {
    // Clearing browsing data is performed by the native Android service.
  }

  @override
  Future<void> createProfile({
    required EngineProfileMode mode,
    required String profileId,
  }) async {
    // Profile creation is handled by the native Android profile service.
  }

  @override
  Future<void> navigate(Uri uri) async {
    if (canNavigate(uri)) {
      await controller.loadRequest(uri);
    }
  }

  @override
  Future<void> setBlockedHosts(Iterable<String> hosts) async {
    // Content blocking is handled by the native Android service.
  }

  @override
  Future<void> dispose() async {}
}
