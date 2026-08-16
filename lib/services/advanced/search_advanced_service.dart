class SearchSuggestion {
  const SearchSuggestion(this.text, {this.score = 0});
  final String text;
  final double score;
}

class AdvancedSearchService {
  const AdvancedSearchService();

  List<SearchSuggestion> suggest(String query, Iterable<String> corpus) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final out = <SearchSuggestion>[];
    for (final item in corpus) {
      final value = item.trim();
      if (value.isEmpty) continue;
      final lower = value.toLowerCase();
      if (lower.startsWith(q)) {
        out.add(SearchSuggestion(value, score: 1));
      } else if (lower.contains(q)) {
        out.add(SearchSuggestion(value, score: .5));
      }
    }
    out.sort((a, b) => b.score.compareTo(a.score));
    return out.take(8).toList(growable: false);
  }

  String correctTypo(String query, Iterable<String> corpus) {
    final q = query.trim();
    if (q.isEmpty) return q;
    var best = q;
    var distance = 3;
    for (final item in corpus) {
      final d = _levenshtein(q.toLowerCase(), item.toLowerCase());
      if (d < distance) {
        distance = d;
        best = item;
      }
    }
    return best;
  }

  List<T> rank<T>(Iterable<T> results, double Function(T) score) {
    final list = results.toList();
    list.sort((a, b) => score(b).compareTo(score(a)));
    return list;
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        current[j] = [current[j - 1] + 1, previous[j] + 1, previous[j - 1] + cost].reduce((x, y) => x < y ? x : y);
      }
      previous = current;
    }
    return previous[b.length];
  }
}
