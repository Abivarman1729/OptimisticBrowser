enum CookiePolicyMode { allowAll, blockThirdParty, blockAll }

class BrowserCookie {
  const BrowserCookie({
    required this.name,
    required this.domain,
    required this.path,
    required this.value,
    required this.secure,
    required this.httpOnly,
    required this.sameSite,
  });

  final String name;
  final String domain;
  final String path;
  final String value;
  final bool secure;
  final bool httpOnly;
  final String sameSite;
}

class CookiePolicyService {
  CookiePolicyService({this.mode = CookiePolicyMode.blockThirdParty});

  CookiePolicyMode mode;

  /// Cookies are isolated by browser profile.
  ///
  /// profileId -> cookies belonging to that profile.
  final Map<String, List<BrowserCookie>> _jar = <String, List<BrowserCookie>>{};

  /// Determines whether a site is allowed to set a cookie.
  bool allowSetCookie({required Uri firstParty, required Uri cookieOrigin}) {
    switch (mode) {
      case CookiePolicyMode.blockAll:
        return false;

      case CookiePolicyMode.allowAll:
        return true;

      case CookiePolicyMode.blockThirdParty:
        return _sameSite(firstParty.host, cookieOrigin.host);
    }
  }

  /// Stores a cookie inside the specified browser profile.
  ///
  /// Cookies from one profile can never be returned for another profile.
  void store(String profileId, BrowserCookie cookie) {
    final cookies = _jar.putIfAbsent(profileId, () => <BrowserCookie>[]);

    final normalizedDomain = _normalizeDomain(cookie.domain);
    final normalizedPath = _normalizePath(cookie.path);

    final normalizedCookie = BrowserCookie(
      name: cookie.name,
      domain: normalizedDomain,
      path: normalizedPath,
      value: cookie.value,
      secure: cookie.secure,
      httpOnly: cookie.httpOnly,
      sameSite: cookie.sameSite,
    );

    final existingIndex = cookies.indexWhere(
      (existing) =>
          existing.name == normalizedCookie.name &&
          _normalizeDomain(existing.domain) == normalizedDomain &&
          _normalizePath(existing.path) == normalizedPath,
    );

    if (existingIndex >= 0) {
      cookies[existingIndex] = normalizedCookie;
    } else {
      cookies.add(normalizedCookie);
    }
  }

  /// Returns cookies applicable to [uri] for [profileId].
  ///
  /// The returned cookies are restricted to:
  /// - the requested profile
  /// - matching domain
  /// - matching path
  /// - secure transport when required
  List<BrowserCookie> cookiesFor(String profileId, Uri uri) {
    final cookies = _jar[profileId];

    if (cookies == null || cookies.isEmpty) {
      return const <BrowserCookie>[];
    }

    final host = uri.host.toLowerCase();
    final requestPath = uri.path.isEmpty ? '/' : uri.path;
    final isSecure = uri.scheme.toLowerCase() == 'https';

    return cookies
        .where((cookie) {
          final domain = _normalizeDomain(cookie.domain);
          final cookiePath = _normalizePath(cookie.path);

          final domainMatches = _domainMatches(host, domain);

          final pathMatches = _pathMatches(requestPath, cookiePath);

          final secureMatches = !cookie.secure || isSecure;

          return domainMatches && pathMatches && secureMatches;
        })
        .toList(growable: false);
  }

  /// Removes every cookie belonging to one profile.
  void clear(String profileId) {
    _jar.remove(profileId);
  }

  /// Removes every cookie from every profile.
  void clearAll() {
    _jar.clear();
  }

  /// Returns the number of stored cookies for a profile.
  int count(String profileId) {
    return _jar[profileId]?.length ?? 0;
  }

  /// Checks whether two hosts belong to the same registrable-site level
  /// for the current lightweight cookie-policy implementation.
  bool _sameSite(String firstHost, String secondHost) {
    final left = _registrableSite(firstHost);
    final right = _registrableSite(secondHost);

    return left == right;
  }

  String _registrableSite(String host) {
    final normalized = host.toLowerCase().trim().replaceFirst(
      RegExp(r'^\.+'),
      '',
    );

    if (normalized.isEmpty) {
      return '';
    }

    final parts = normalized
        .split('.')
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length <= 2) {
      return normalized;
    }

    return '${parts[parts.length - 2]}.${parts[parts.length - 1]}';
  }

  String _normalizeDomain(String domain) {
    return domain.trim().toLowerCase().replaceFirst(RegExp(r'^\.+'), '');
  }

  String _normalizePath(String path) {
    final normalized = path.trim();

    if (normalized.isEmpty) {
      return '/';
    }

    return normalized.startsWith('/') ? normalized : '/$normalized';
  }

  bool _domainMatches(String host, String cookieDomain) {
    if (host.isEmpty || cookieDomain.isEmpty) {
      return false;
    }

    if (host == cookieDomain) {
      return true;
    }

    return host.endsWith('.$cookieDomain');
  }

  bool _pathMatches(String requestPath, String cookiePath) {
    if (cookiePath == '/') {
      return true;
    }

    if (requestPath == cookiePath) {
      return true;
    }

    if (!requestPath.startsWith(cookiePath)) {
      return false;
    }

    if (cookiePath.endsWith('/')) {
      return true;
    }

    return requestPath.length > cookiePath.length &&
        requestPath[cookiePath.length] == '/';
  }
}
