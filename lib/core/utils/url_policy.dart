class UrlPolicy {
  // ===========================================================================
  // BLOCKED HOSTS
  // ===========================================================================
  //
  // Keep these as explicit security-policy entries rather than relying on
  // string matching at call sites.
  //
  static const Set<String> _blockedHosts = <String>{
    'google.com',
    'google.co.in',
    'google.co.uk',
    'google.ca',
    'google.com.au',
    'google.de',
    'google.fr',
    'google.es',
    'google.it',
    'google.co.jp',
    'googleusercontent.com',
    'googleapis.com',
    'gstatic.com',
  };

  // ===========================================================================
  // BLOCKED SCHEMES
  // ===========================================================================
  //
  // Optimistic Browser currently permits only normal web navigation.
  //
  // Examples intentionally rejected:
  // javascript:
  // data:
  // file:
  // content:
  // intent:
  // about:
  // chrome:
  // edge:
  //
  static const Set<String> _blockedSchemes = <String>{
    'javascript',
    'data',
    'file',
    'content',
    'intent',
    'about',
    'chrome',
    'edge',
    'blob',
    'view-source',
  };

  // ===========================================================================
  // BLOCKED HOSTS / LOCAL NETWORK
  // ===========================================================================
  //
  // These hosts are not considered normal public web destinations.
  //
  static const Set<String> _blockedExactHosts = <String>{
    'localhost',
    'localhost.localdomain',
    'ip6-localhost',
    'ip6-loopback',
  };

  // ===========================================================================
  // BLOCKED PORTS
  // ===========================================================================
  //
  // Allow standard web ports only when a port is explicitly present.
  //
  static const Set<int> _blockedPorts = <int>{
    21, // FTP
    22, // SSH
    23, // Telnet
    25, // SMTP
    110, // POP3
    143, // IMAP
    389, // LDAP
    445, // SMB
    1433, // MSSQL
    1521, // Oracle
    2375, // Docker
    2376, // Docker TLS
    3306, // MySQL
    3389, // RDP
    5432, // PostgreSQL
    5900, // VNC
    6379, // Redis
    9200, // Elasticsearch
    11211, // Memcached
  };

  // ===========================================================================
  // PUBLIC API
  // ===========================================================================

  static bool isHttp(Uri uri) {
    final String scheme = uri.scheme.toLowerCase();

    return scheme == 'http' || scheme == 'https';
  }

  static bool isHttps(Uri uri) {
    return uri.scheme.toLowerCase() == 'https';
  }

  static bool isBlocked(Uri uri) {
    final Uri normalized = _normalizeUri(uri);

    final String host = _normalizeHost(normalized.host);

    if (host.isEmpty) {
      return true;
    }

    if (_blockedExactHosts.contains(host)) {
      return true;
    }

    if (_blockedHosts.any(
      (String blocked) => host == blocked || host.endsWith('.$blocked'),
    )) {
      return true;
    }

    if (_isLocalOrPrivateHost(host)) {
      return true;
    }

    if (_containsUnsafePort(normalized)) {
      return true;
    }

    if (_hasCredentials(normalized)) {
      return true;
    }

    if (_isSuspiciousHostname(host)) {
      return true;
    }

    return false;
  }

  static bool isSafeNavigation(Uri uri) {
    final Uri normalized = _normalizeUri(uri);

    if (!isHttp(normalized)) {
      return false;
    }

    if (normalized.host.isEmpty) {
      return false;
    }

    if (_hasCredentials(normalized)) {
      return false;
    }

    if (_containsUnsafePort(normalized)) {
      return false;
    }

    if (_blockedByScheme(normalized)) {
      return false;
    }

    if (isBlocked(normalized)) {
      return false;
    }

    return true;
  }

  static bool isPublicWebUri(Uri uri) {
    final Uri normalized = _normalizeUri(uri);

    if (!isSafeNavigation(normalized)) {
      return false;
    }

    return !_isLocalOrPrivateHost(_normalizeHost(normalized.host));
  }

  // ===========================================================================
  // SEARCH INPUT DETECTION
  // ===========================================================================

  static bool looksLikeUrl(String input) {
    final String value = input.trim();

    if (value.isEmpty) {
      return false;
    }

    // Natural-language searches should not be treated as URLs.
    if (_containsWhitespace(value)) {
      return false;
    }

    // A URL with a scheme is considered URL-like only when the scheme itself
    // is supported.
    if (value.contains('://')) {
      final Uri? parsed = Uri.tryParse(value);

      if (parsed == null) {
        return false;
      }

      if (!isHttp(parsed)) {
        return false;
      }

      return isSafeNavigation(parsed);
    }

    // A bare domain:
    //
    // example.com
    // www.example.com
    // example.co.in
    //
    final Uri? uri = Uri.tryParse('https://$value');

    if (uri == null) {
      return false;
    }

    if (uri.host.isEmpty) {
      return false;
    }

    if (!_looksLikeDomain(uri.host)) {
      return false;
    }

    return isSafeNavigation(uri);
  }

  // ===========================================================================
  // DIRECT URL RESOLUTION
  // ===========================================================================

  static Uri resolveDirectUrl(String input) {
    final String value = input.trim();

    if (value.isEmpty) {
      throw const FormatException('URL cannot be empty.');
    }

    if (_containsWhitespace(value)) {
      throw const FormatException('URL contains invalid whitespace.');
    }

    final String prepared = value.contains('://') ? value : 'https://$value';

    final Uri? parsed = Uri.tryParse(prepared);

    if (parsed == null) {
      throw const FormatException('Invalid URL.');
    }

    Uri uri = _normalizeUri(parsed);

    // Optimistic Browser prefers HTTPS.
    if (uri.scheme.toLowerCase() == 'http') {
      uri = uri.replace(scheme: 'https');
    }

    if (!isSafeNavigation(uri)) {
      throw const FormatException(
        'Navigation blocked by Optimistic security policy.',
      );
    }

    return uri;
  }

  // ===========================================================================
  // HTTPS UPGRADE
  // ===========================================================================

  static Uri upgradeToHttps(Uri uri) {
    if (!isHttp(uri)) {
      throw const FormatException('Only HTTP/HTTPS URLs can be upgraded.');
    }

    final Uri secure = uri.replace(scheme: 'https');

    if (!isSafeNavigation(secure)) {
      throw const FormatException(
        'HTTPS navigation blocked by Optimistic security policy.',
      );
    }

    return secure;
  }

  // ===========================================================================
  // HOST HELPERS
  // ===========================================================================

  static String normalizeHost(String host) {
    return _normalizeHost(host);
  }

  static bool isLocalHost(String host) {
    return _isLocalOrPrivateHost(_normalizeHost(host));
  }

  // ===========================================================================
  // INTERNAL URI NORMALIZATION
  // ===========================================================================

  static Uri _normalizeUri(Uri uri) {
    String host = uri.host.trim().toLowerCase();

    if (host.startsWith('www.')) {
      host = host.substring(4);
    }

    // Uri.replace() preserves all other components while normalizing host.
    if (host.isEmpty || host == uri.host) {
      return uri;
    }

    return uri.replace(host: host);
  }

  static String _normalizeHost(String host) {
    String value = host.trim().toLowerCase();

    while (value.startsWith('www.')) {
      value = value.substring(4);
    }

    // Hostnames are case-insensitive.
    value = value.replaceAll(RegExp(r'\.+$'), '');

    return value;
  }

  // ===========================================================================
  // SCHEME SECURITY
  // ===========================================================================

  static bool _blockedByScheme(Uri uri) {
    final String scheme = uri.scheme.toLowerCase();

    return _blockedSchemes.contains(scheme);
  }

  // ===========================================================================
  // CREDENTIAL SECURITY
  // ===========================================================================

  static bool _hasCredentials(Uri uri) {
    return uri.userInfo.isNotEmpty;
  }

  // ===========================================================================
  // PORT SECURITY
  // ===========================================================================

  static bool _containsUnsafePort(Uri uri) {
    if (!uri.hasPort) {
      return false;
    }

    final int port = uri.port;

    // Normal HTTPS.
    if (port == 443) {
      return false;
    }

    // Normal HTTP.
    if (port == 80) {
      return false;
    }

    return _blockedPorts.contains(port);
  }

  // ===========================================================================
  // DOMAIN DETECTION
  // ===========================================================================

  static bool _looksLikeDomain(String host) {
    final String normalized = _normalizeHost(host);

    if (normalized.isEmpty) {
      return false;
    }

    // localhost and IP addresses should not be interpreted as public domains.
    if (_isLocalOrPrivateHost(normalized)) {
      return false;
    }

    // IPv4 address.
    if (_isIpv4(normalized)) {
      return true;
    }

    // IPv6 address.
    if (normalized.contains(':')) {
      return true;
    }

    // Domain must contain a dot and have sane labels.
    if (!normalized.contains('.')) {
      return false;
    }

    final List<String> labels = normalized.split('.');

    if (labels.length < 2) {
      return false;
    }

    for (final String label in labels) {
      if (label.isEmpty) {
        return false;
      }

      if (label.startsWith('-') || label.endsWith('-')) {
        return false;
      }

      if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(label)) {
        return false;
      }
    }

    final String tld = labels.last;

    if (tld.length < 2 && !_isNumeric(tld)) {
      return false;
    }

    return true;
  }

  // ===========================================================================
  // SUSPICIOUS HOSTNAME DETECTION
  // ===========================================================================

  static bool _isSuspiciousHostname(String host) {
    // Reject invalid hostname characters.
    if (host.contains(RegExp(r'[\s<>"{}|\\^`]'))) {
      return true;
    }

    // Reject excessively long individual host labels.
    final List<String> labels = host.split('.');

    for (final String label in labels) {
      if (label.length > 63) {
        return true;
      }
    }

    // RFC-compatible practical hostname limit.
    if (host.length > 253) {
      return true;
    }

    return false;
  }

  // ===========================================================================
  // LOCAL / PRIVATE ADDRESS DETECTION
  // ===========================================================================

  static bool _isLocalOrPrivateHost(String host) {
    final String normalized = _normalizeHost(host);

    if (normalized.isEmpty) {
      return true;
    }

    if (_blockedExactHosts.contains(normalized)) {
      return true;
    }

    if (normalized == '0.0.0.0' || normalized == '::' || normalized == '::1') {
      return true;
    }

    final List<int>? ipv4 = _parseIpv4(normalized);

    if (ipv4 != null) {
      final int a = ipv4[0];
      final int b = ipv4[1];

      // 10.0.0.0/8
      if (a == 10) {
        return true;
      }

      // 172.16.0.0/12
      if (a == 172 && b >= 16 && b <= 31) {
        return true;
      }

      // 192.168.0.0/16
      if (a == 192 && b == 168) {
        return true;
      }

      // 127.0.0.0/8
      if (a == 127) {
        return true;
      }

      // 169.254.0.0/16
      if (a == 169 && b == 254) {
        return true;
      }

      // 100.64.0.0/10 CGNAT
      if (a == 100 && b >= 64 && b <= 127) {
        return true;
      }

      return false;
    }

    // IPv6 loopback/link-local/private ranges.
    if (normalized.contains(':')) {
      final String lower = normalized.toLowerCase();

      if (lower == '::1' ||
          lower.startsWith('fe80:') ||
          lower.startsWith('fc') ||
          lower.startsWith('fd')) {
        return true;
      }
    }

    // Common internal DNS-style names.
    if (normalized.endsWith('.local') ||
        normalized.endsWith('.localhost') ||
        normalized.endsWith('.internal')) {
      return true;
    }

    return false;
  }

  // ===========================================================================
  // IPV4
  // ===========================================================================

  static bool _isIpv4(String value) {
    return _parseIpv4(value) != null;
  }

  static List<int>? _parseIpv4(String value) {
    final List<String> parts = value.split('.');

    if (parts.length != 4) {
      return null;
    }

    final List<int> output = <int>[];

    for (final String part in parts) {
      if (part.isEmpty || !RegExp(r'^\d+$').hasMatch(part)) {
        return null;
      }

      final int? number = int.tryParse(part);

      if (number == null || number < 0 || number > 255) {
        return null;
      }

      output.add(number);
    }

    return output;
  }

  static bool _isNumeric(String value) {
    return RegExp(r'^\d+$').hasMatch(value);
  }

  static bool _containsWhitespace(String value) {
    return value.contains(RegExp(r'\s'));
  }
}
