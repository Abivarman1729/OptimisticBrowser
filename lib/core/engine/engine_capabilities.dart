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

  bool get productionPrivateProfileReady =>
      supportsPerProfileCookies &&
      supportsPerProfileCache &&
      supportsPerProfileLocalStorage;

  Map<String, Object> toJson() => {
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
      };
}
