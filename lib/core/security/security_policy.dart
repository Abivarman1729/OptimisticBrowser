import '../utils/url_policy.dart';
class SecurityPolicy {
  const SecurityPolicy();
  bool allowNavigation(Uri uri) => UrlPolicy.isSafeNavigation(uri);
  bool allowDownload(Uri uri) => UrlPolicy.isSafeNavigation(uri);
  bool allowExternalIntent(Uri uri) => UrlPolicy.isSafeNavigation(uri);
  bool allowScheme(String scheme) => scheme == 'http' || scheme == 'https';
  bool isSuspiciousHost(String host) => host.toLowerCase().contains('xn--') || host.split('.').length > 6;
}
