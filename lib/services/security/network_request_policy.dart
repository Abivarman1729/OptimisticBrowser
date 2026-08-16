import '../../core/security/security_policy.dart';
import '../privacy/ad_tracker_blocker.dart';
import 'certificate_security_service.dart';

class NetworkDecision {
  const NetworkDecision({
    required this.allowed,
    required this.reason,
    required this.finalUri,
  });

  final bool allowed;
  final String reason;
  final Uri finalUri;
}

class NetworkRequestPolicy {
  const NetworkRequestPolicy({
    this.security = const SecurityPolicy(),
    this.certificates = const CertificateSecurityService(),
    required this.blocker,
  }) : assert(true);

  final SecurityPolicy security;
  final CertificateSecurityService certificates;
  final AdTrackerBlocker blocker;

  factory NetworkRequestPolicy.empty() => NetworkRequestPolicy(
    security: const SecurityPolicy(),
    certificates: const CertificateSecurityService(),
    blocker: AdTrackerBlocker(),
  );

  NetworkDecision evaluate(Uri uri) {
    if (!security.allowNavigation(uri)) {
      return NetworkDecision(
        allowed: false,
        reason: 'security-policy',
        finalUri: uri,
      );
    }

    if (!certificates.allow(uri)) {
      return NetworkDecision(
        allowed: false,
        reason: 'certificate-policy',
        finalUri: uri,
      );
    }

    if (blocker.shouldBlock(uri)) {
      return NetworkDecision(
        allowed: false,
        reason: 'content-blocker',
        finalUri: uri,
      );
    }

    final finalUri = uri.scheme == 'http' ? uri.replace(scheme: 'https') : uri;
    return NetworkDecision(
      allowed: true,
      reason: 'allowed',
      finalUri: finalUri,
    );
  }
}
