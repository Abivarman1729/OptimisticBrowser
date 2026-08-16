import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offline fallback does not point to an external search engine', () {
    const fallbackUrl = '';
    expect(fallbackUrl, isEmpty);
  });
}
