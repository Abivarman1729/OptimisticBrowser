/// Describes the capabilities exposed by the active browser engine.
///
/// This object is intentionally immutable so the browser shell can safely
/// inspect engine capabilities without depending on platform-specific code.
class EngineCapabilities {
  const EngineCapabilities({
    required this.engineName,
    required this.engineVersion,
    required this.supportsJavaScript,
    required this.supportsDownloads,
    required this.supportsFileUpload,
    required this.supportsPrivateHistoryIsolation,
    required this.supportsPerProfileCookies,
    required this.supportsPerProfileCache,
    required this.supportsPerProfileLocalStorage,
    required this.supportsNetworkInterception,
    required this.supportsContentBlocking,
  });

  final String engineName;
  final String engineVersion;

  final bool supportsJavaScript;
  final bool supportsDownloads;
  final bool supportsFileUpload;

  final bool supportsPrivateHistoryIsolation;

  final bool supportsPerProfileCookies;
  final bool supportsPerProfileCache;
  final bool supportsPerProfileLocalStorage;

  final bool supportsNetworkInterception;
  final bool supportsContentBlocking;

  /// Whether the engine exposes the minimum storage isolation required for
  /// a production private profile.
  bool get productionPrivateProfileReady {
    return supportsPrivateHistoryIsolation &&
        supportsPerProfileCookies &&
        supportsPerProfileCache &&
        supportsPerProfileLocalStorage;
  }

  /// Whether the engine has the basic functionality expected from a browser.
  bool get basicBrowserReady {
    return supportsJavaScript && supportsDownloads && supportsFileUpload;
  }

  /// Whether the engine exposes all security/privacy capabilities expected
  /// by the Optimistic Browser architecture.
  bool get advancedSecurityReady {
    return supportsNetworkInterception &&
        supportsContentBlocking &&
        productionPrivateProfileReady;
  }

  /// Converts the capability state to a serializable map.
  Map<String, Object> toJson() {
    return <String, Object>{
      'engineName': engineName,
      'engineVersion': engineVersion,
      'supportsJavaScript': supportsJavaScript,
      'supportsDownloads': supportsDownloads,
      'supportsFileUpload': supportsFileUpload,
      'supportsPrivateHistoryIsolation': supportsPrivateHistoryIsolation,
      'supportsPerProfileCookies': supportsPerProfileCookies,
      'supportsPerProfileCache': supportsPerProfileCache,
      'supportsPerProfileLocalStorage': supportsPerProfileLocalStorage,
      'supportsNetworkInterception': supportsNetworkInterception,
      'supportsContentBlocking': supportsContentBlocking,
      'productionPrivateProfileReady': productionPrivateProfileReady,
      'basicBrowserReady': basicBrowserReady,
      'advancedSecurityReady': advancedSecurityReady,
    };
  }

  @override
  String toString() {
    return 'EngineCapabilities('
        'engineName: $engineName, '
        'engineVersion: $engineVersion, '
        'basicBrowserReady: $basicBrowserReady, '
        'productionPrivateProfileReady: '
        '$productionPrivateProfileReady, '
        'advancedSecurityReady: $advancedSecurityReady'
        ')';
  }
}
