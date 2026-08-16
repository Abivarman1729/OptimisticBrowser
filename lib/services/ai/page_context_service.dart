class PageContext {
  const PageContext({
    required this.url,
    required this.title,
    required this.text,
    required this.wordCount,
  });
  final String url;
  final String title;
  final String text;
  final int wordCount;

  String clipped(int maxCharacters) =>
      text.length <= maxCharacters ? text : '${text.substring(0, maxCharacters)}…';
}

class PageContextService {
  PageContext build({
    required String url,
    required String title,
    required String html,
  }) {
    final text = html
        .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final count = text.isEmpty ? 0 : text.split(' ').length;
    return PageContext(url: url, title: title, text: text, wordCount: count);
  }

  String promptFor({
    required PageContext context,
    required String instruction,
    int maxCharacters = 12000,
  }) =>
      'Title: ${context.title}\nURL: ${context.url}\n\n'
      'Page:\n${context.clipped(maxCharacters)}\n\n'
      'Instruction:\n$instruction';
}
