import 'package:flutter_test/flutter_test.dart';
import 'package:optimistic_browser/core/utils/url_policy.dart';

void main() {
  test('detects URLs without treating normal words as URLs', () {
    expect(UrlPolicy.looksLikeUrl('flutter.dev'), isTrue);
    expect(UrlPolicy.looksLikeUrl('https://flutter.dev'), isTrue);
    expect(UrlPolicy.looksLikeUrl('flutter tutorial'), isFalse);
  });

  test('blocks Google search domains including www hosts', () {
    expect(
      UrlPolicy.isBlocked(Uri.parse('https://www.google.com/search?q=test')),
      isTrue,
    );
    expect(UrlPolicy.isBlocked(Uri.parse('https://google.co.in')), isTrue);
  });

  test('rejects non-http schemes', () {
    expect(UrlPolicy.isSafeNavigation(Uri.parse('javascript:alert(1)')), isFalse);
    expect(UrlPolicy.isSafeNavigation(Uri.parse('file:///tmp/a')), isFalse);
    expect(UrlPolicy.isSafeNavigation(Uri.parse('https://flutter.dev')), isTrue);
  });

  test('upgrades direct HTTP input to HTTPS', () {
    expect(
      UrlPolicy.resolveDirectUrl('http://flutter.dev').scheme,
      'https',
    );
  });
}
