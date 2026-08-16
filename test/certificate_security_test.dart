import 'package:flutter_test/flutter_test.dart';
import 'package:optimistic_browser/services/security/certificate_security_service.dart';

void main() {
  const service = CertificateSecurityService();

  test('certificate fingerprint is real SHA-256 hex', () {
    expect(
      service.fingerprintFromBytes('abc'.codeUnits),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  test('certificate validation accepts only SHA-256 fingerprints', () {
    final valid = service.validate(
      uri: Uri.parse('https://example.com'),
      issuer: 'test',
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      sha256: service.fingerprintFromBytes([1, 2, 3]),
    );
    expect(valid.isValid, isTrue);

    final invalid = service.validate(
      uri: Uri.parse('https://example.com'),
      issuer: 'test',
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      sha256: 'not-a-sha256',
    );
    expect(invalid.isValid, isFalse);
  });
}
