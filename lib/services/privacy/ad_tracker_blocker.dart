class BlockRule {
  const BlockRule({
    required this.pattern,
    required this.category,
    this.enabled = true,
  });

  final String pattern;
  final String category;
  final bool enabled;

  bool matches(String url) =>
      enabled && url.toLowerCase().contains(pattern.toLowerCase());
}

class AdTrackerBlocker {
  AdTrackerBlocker({List<BlockRule>? rules})
      : _rules = List<BlockRule>.from(rules ?? defaultRules);

  final List<BlockRule> _rules;
  int blockedCount = 0;

  static const List<BlockRule> defaultRules = [
    BlockRule(pattern: 'doubleclick.net', category: 'ad'),
    BlockRule(pattern: 'googlesyndication.com', category: 'ad'),
    BlockRule(pattern: 'google-analytics.com', category: 'analytics'),
    BlockRule(pattern: 'connect.facebook.net', category: 'social'),
    BlockRule(pattern: 'facebook.com/tr', category: 'tracking'),
    BlockRule(pattern: 'hotjar.com', category: 'analytics'),
    BlockRule(pattern: 'segment.io', category: 'analytics'),
    BlockRule(pattern: 'amplitude.com', category: 'analytics'),
    BlockRule(pattern: 'scorecardresearch.com', category: 'tracking'),
    BlockRule(pattern: 'adservice.google.com', category: 'ad'),
    BlockRule(pattern: 'adsystem.com', category: 'ad'),
    BlockRule(pattern: 'tracking.', category: 'tracking'),
  ];

  bool shouldBlock(Uri uri) {
    final blocked = _rules.any((rule) => rule.matches(uri.toString()));
    if (blocked) blockedCount++;
    return blocked;
  }

  List<BlockRule> get rules => List.unmodifiable(_rules);

  void addRule(BlockRule rule) => _rules.add(rule);

  bool removeRule(String pattern) {
    final before = _rules.length;
    _rules.removeWhere((rule) => rule.pattern == pattern);
    return before != _rules.length;
  }

  void reset() {
    _rules
      ..clear()
      ..addAll(defaultRules);
    blockedCount = 0;
  }

  Map<String, Object?> report() => {
        'blockedCount': blockedCount,
        'ruleCount': _rules.length,
      };
}
