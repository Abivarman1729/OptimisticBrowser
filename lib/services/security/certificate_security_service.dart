import 'package:crypto/crypto.dart';

class CertificateInfo {
  const CertificateInfo({
    required this.host,
    required this.issuer,
    required this.expiresAt,
    required this.sha256,
    required this.isValid,
  });

  final String host;
  final String issuer;
  final DateTime expiresAt;
  final String sha256;
  final bool isValid;

  bool get expired => DateTime.now().isAfter(expiresAt);
}

class CertificateSecurityService {
  const CertificateSecurityService();

  bool allow(Uri uri) {
    if (uri.scheme == 'https') return true;
    return uri.host == 'localhost' || uri.host == '127.0.0.1';
  }

  bool isStrongHost(String host) {
    if (host.isEmpty || host.contains(' ')) return false;
    if (host.startsWith('.') || host.endsWith('.')) return false;
    return !host.contains('..');
  }

  bool isSecureRedirect(Uri from, Uri to) {
    if (from.scheme != 'https') return true;
    return to.scheme == 'https' || to.host == 'localhost';
  }

  String normalizeFingerprint(String fingerprint) {
    return fingerprint
        .replaceAll(':', '')
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .toLowerCase();
  }

  bool matchesPin(String fingerprint, Set<String> pins) {
    final value = normalizeFingerprint(fingerprint);
    return pins.map(normalizeFingerprint).contains(value);
  }

  CertificateInfo validate({
    required Uri uri,
    required String issuer,
    required DateTime expiresAt,
    required String sha256,
  }) {
    final normalized = normalizeFingerprint(sha256);
    final valid = uri.scheme == 'https' &&
        isStrongHost(uri.host) &&
        expiresAt.isAfter(DateTime.now()) &&
        RegExp(r'^[0-9a-f]{64}$').hasMatch(normalized);
    return CertificateInfo(
      host: uri.host,
      issuer: issuer,
      expiresAt: expiresAt,
      sha256: normalized,
      isValid: valid,
    );
  }

  /// Returns the lowercase hexadecimal SHA-256 digest of the certificate DER.
  ///
  /// The input must be the DER-encoded X.509 certificate bytes. This replaces
  /// the old non-cryptographic FNV-style fingerprint implementation.
  String fingerprintFromBytes(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }
}
