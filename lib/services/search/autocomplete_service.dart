import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class Suggestion {
  const Suggestion({
    required this.text,
    required this.source,
    this.score = 0,
  });

  final String text;
  final String source;
  final double score;
}

class SearchAutocompleteService {
  static const _key = 'optimistic.search.recent';
  Timer? _debounce;

  Future<List<Suggestion>> suggest(String query) async {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) return const <Suggestion>[];

    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList(_key) ?? const <String>[];
    final matches = recent
        .where((item) => item.toLowerCase().contains(value))
        .take(8)
        .map((item) => Suggestion(
              text: item,
              source: 'history',
              score: 1,
            ))
        .toList();

    final defaults = <Suggestion>[
      Suggestion(text: '$query news', source: 'smart'),
      Suggestion(text: '$query images', source: 'smart'),
      Suggestion(text: '$query videos', source: 'smart'),
      Suggestion(text: '$query wiki', source: 'smart'),
    ];

    return [...matches, ...defaults].take(10).toList(growable: false);
  }

  Future<void> remember(String query) async {
    final value = query.trim();
    if (value.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = List<String>.from(prefs.getStringList(_key) ?? const []);
    list.remove(value);
    list.insert(0, value);
    await prefs.setStringList(_key, list.take(50).toList());
  }

  void debounce(Duration duration, void Function() callback) {
    _debounce?.cancel();
    _debounce = Timer(duration, callback);
  }

  void dispose() => _debounce?.cancel();
}
