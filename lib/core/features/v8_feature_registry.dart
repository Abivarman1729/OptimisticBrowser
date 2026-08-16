class V8Feature {
  const V8Feature({
    required this.id,
    required this.name,
    required this.description,
    this.enabled = true,
  });

  final String id;
  final String name;
  final String description;
  final bool enabled;
}

class V8FeatureRegistry {
  static const List<V8Feature> all = [
    V8Feature(id: 'flutter_verify', name: 'Flutter compile verification', description: 'Analyze, test and release-build gates.'),
    V8Feature(id: 'native_engine', name: 'Native browser engine bridge', description: 'Engine abstraction with native profile lifecycle.'),
    V8Feature(id: 'true_incognito', name: 'Private profiles', description: 'Private profile lifecycle isolated from normal session state.'),
    V8Feature(id: 'storage_partition', name: 'Storage partitioning', description: 'Cookie/cache/local-storage partition model.'),
    V8Feature(id: 'downloads', name: 'Download manager', description: 'Streaming downloads with progress and lifecycle.'),
    V8Feature(id: 'uploads', name: 'File upload', description: 'Native file chooser bridge.'),
    V8Feature(id: 'permissions', name: 'Permission manager', description: 'Camera, microphone, location and browser permission policy.'),
    V8Feature(id: 'blocking', name: 'Ad/tracker blocking', description: 'Request-level blocking rules and telemetry.'),
    V8Feature(id: 'certificates', name: 'HTTPS and certificate security', description: 'Secure navigation and certificate validation primitives.'),
    V8Feature(id: 'ai_streaming', name: 'AI streaming', description: 'Incremental SSE/line-oriented AI response handling.'),
    V8Feature(id: 'ai_history', name: 'Persistent AI conversations', description: 'Local conversation storage.'),
    V8Feature(id: 'autocomplete', name: 'Search autocomplete', description: 'Recent-query and smart suggestions.'),
    V8Feature(id: 'reader', name: 'Reader mode', description: 'Readable article extraction.'),
    V8Feature(id: 'translation', name: 'Page translation', description: 'Translation service abstraction.'),
    V8Feature(id: 'pip', name: 'Picture-in-picture', description: 'Native PIP platform bridge.'),
    V8Feature(id: 'tab_groups', name: 'Advanced tab groups', description: 'Named, colored and isolated tab collections.'),
    V8Feature(id: 'recovery', name: 'Crash/error recovery', description: 'Heartbeat and unclean-shutdown detection.'),
    V8Feature(id: 'release', name: 'Production release checks', description: 'Release gate validation.'),
  ];

  static V8Feature? find(String id) {
    for (final feature in all) {
      if (feature.id == id) return feature;
    }
    return null;
  }
}
