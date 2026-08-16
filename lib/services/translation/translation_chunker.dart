class TranslationChunker {
  const TranslationChunker({this.maxCharacters = 3500});
  final int maxCharacters;

  List<String> split(String text) {
    final value = text.trim();
    if (value.isEmpty) return const [];
    if (value.length <= maxCharacters) return [value];
    final chunks = <String>[];
    var start = 0;
    while (start < value.length) {
      var end = (start + maxCharacters).clamp(0, value.length);
      if (end < value.length) {
        final boundary = value.lastIndexOf(RegExp(r'[.!?\n]'), end);
        if (boundary > start + 500) end = boundary + 1;
      }
      chunks.add(value.substring(start, end).trim());
      start = end;
    }
    return chunks.where((e) => e.isNotEmpty).toList(growable: false);
  }

  String join(Iterable<String> chunks) =>
      chunks.map((e) => e.trim()).where((e) => e.isNotEmpty).join(' ');
}
