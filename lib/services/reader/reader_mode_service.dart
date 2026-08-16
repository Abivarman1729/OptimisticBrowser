class ReaderDocument {
  const ReaderDocument({
    required this.title,
    required this.text,
    required this.url,
    required this.wordCount,
    required this.readingMinutes,
  });

  final String title;
  final String text;
  final String url;
  final int wordCount;
  final int readingMinutes;
}

class ReaderModeService {
  ReaderDocument extract({
    required String url,
    required String title,
    required String html,
  }) {
    var text = html
        .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final words = text.isEmpty ? 0 : text.split(' ').length;
    final minutes = (words / 220).ceil();

    return ReaderDocument(
      title: title.trim().isEmpty ? 'Reader' : title.trim(),
      text: text,
      url: url,
      wordCount: words,
      readingMinutes: minutes,
    );
  }

  List<String> paragraphs(String text) {
    return text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((e) => e.trim())
        .where((e) => e.length > 20)
        .toList(growable: false);
  }
}
