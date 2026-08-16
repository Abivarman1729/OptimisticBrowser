class UrlPolicy {
  static const Set<String> _blockedHosts = <String>{
    'google.com', 'google.co.in', 'google.co.uk', 'google.ca', 'google.com.au',
    'google.de', 'google.fr', 'google.es', 'google.it', 'google.co.jp',
    'googleusercontent.com', 'googleapis.com', 'gstatic.com',
  };

  static bool isHttp(Uri uri) => uri.scheme == 'http' || uri.scheme == 'https';

  static bool isBlocked(Uri uri) {
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    return _blockedHosts.any((blocked) =>
        host == blocked || host.endsWith('.$blocked'));
  }

  static bool isSafeNavigation(Uri uri) =>
      isHttp(uri) && uri.host.isNotEmpty && !isBlocked(uri);

  static bool looksLikeUrl(String input) {
    final value = input.trim();
    if (value.isEmpty || value.contains(' ')) return false;
    final uri = Uri.tryParse(value.contains('://') ? value : 'https://$value');
    return uri != null && uri.host.contains('.') && uri.host.length >= 3 &&
        isSafeNavigation(uri);
  }

  static Uri resolveDirectUrl(String input) {
    final value = input.trim();
    var uri = Uri.parse(value.contains('://') ? value : 'https://$value');
    if (uri.scheme == 'http') {
      uri = uri.replace(scheme: 'https');
    }
    if (!isSafeNavigation(uri)) {
      throw const FormatException(
        'Navigation blocked by Optimistic security policy.',
      );
    }
    return uri;
  }
}
