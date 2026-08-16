import 'package:flutter_test/flutter_test.dart';
import 'package:optimistic_browser/core/v8/v8_application_kernel.dart';
import 'package:optimistic_browser/services/privacy/cookie_policy_service.dart';

void main() {
  test('cookie policy blocks third party by default', () {
    final kernel = V8ApplicationKernel();
    expect(
      kernel.allowCookie(
        firstParty: Uri.parse('https://example.com'),
        origin: Uri.parse('https://tracker.example.net'),
      ),
      isFalse,
    );
  });

  test('kernel cookie store is profile scoped', () {
    final kernel = V8ApplicationKernel();
    const cookie = BrowserCookie(
      name: 'session',
      domain: 'example.com',
      path: '/',
      value: 'private',
      secure: true,
      httpOnly: true,
      sameSite: 'Lax',
    );
    kernel.storeCookie('private-profile', cookie);
    expect(
      kernel.cookiesFor('private-profile', Uri.parse('https://example.com')).length,
      1,
    );
    expect(
      kernel.cookiesFor('normal-profile', Uri.parse('https://example.com')),
      isEmpty,
    );
  });

  test('certificate pinning accepts unpinned hosts', () {
    final kernel = V8ApplicationKernel();
    expect(kernel.certificateMatches('example.com', 'not-pinned'), isTrue);
  });

  test('health monitor starts healthy', () {
    final kernel = V8ApplicationKernel();
    expect(kernel.engineHealth().errorCount, 0);
  });

  test('private clear does not throw for missing profile', () async {
    final kernel = V8ApplicationKernel();
    await kernel.clearPrivateProfile('missing');
  });
}
