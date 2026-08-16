import 'package:flutter_test/flutter_test.dart';

import 'package:optimistic_browser/core/engine/engine_capabilities.dart';

void main() {
  test('platform WebView capability contract is honest', () {
    const capabilities = EngineCapabilities(
      engineName: 'Platform WebView',
      engineVersion: 'webview_flutter 4.13.x',
      supportsJavaScript: true,
      supportsDownloads: true,
      supportsFileUpload: true,
      supportsPrivateHistoryIsolation: true,
      supportsPerProfileCookies: false,
      supportsPerProfileCache: false,
      supportsPerProfileLocalStorage: false,
      supportsNetworkInterception: false,
      supportsContentBlocking: false,
    );

    expect(capabilities.supportsJavaScript, isTrue);
    expect(capabilities.supportsPrivateHistoryIsolation, isTrue);
    expect(capabilities.productionPrivateProfileReady, isFalse);
  });
}
