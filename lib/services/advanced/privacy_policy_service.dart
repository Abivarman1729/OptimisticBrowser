class PrivacyPolicy {
  const PrivacyPolicy({
    this.httpsOnly = true,
    this.blockThirdPartyCookies = true,
    this.blockTrackers = true,
    this.blockAds = true,
    this.preventWebRtcLeak = true,
    this.fingerprintResistance = true,
  });
  final bool httpsOnly;
  final bool blockThirdPartyCookies;
  final bool blockTrackers;
  final bool blockAds;
  final bool preventWebRtcLeak;
  final bool fingerprintResistance;
}

class PrivacyPolicyService {
  const PrivacyPolicyService(this.policy);
  final PrivacyPolicy policy;

  Uri? sanitizeNavigation(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'http' && policy.httpsOnly) {
      return uri.replace(scheme: 'https');
    }
    if (scheme == 'https') return uri;
    return null;
  }

  bool shouldBlockHost(String host, Set<String> blockedHosts) => blockedHosts.contains(host.toLowerCase());
}

abstract interface class NativePrivacyAdapter {
  Future<void> createIsolatedPrivateProfile(String profileId);
  Future<void> destroyPrivateProfile(String profileId);
  Future<void> setDnsPolicy(String mode);
  Future<void> setWebRtcPolicy(bool blockLeaks);
  Future<void> setFingerprintPolicy(bool resist);
  Future<void> handleCertificateFailure(String host, String reason);
}
