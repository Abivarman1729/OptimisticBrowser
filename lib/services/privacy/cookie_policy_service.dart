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
  final Map<String, List<BrowserCookie>> _jar = {};

  bool allowSetCookie({required Uri firstParty, required Uri cookieOrigin}) {
    if (mode == CookiePolicyMode.blockAll) return false;
    if (mode == CookiePolicyMode.allowAll) return true;
    return _sameSite(firstParty.host, cookieOrigin.host);
  }

  void store(String profileId, BrowserCookie cookie) {
    _jar.putIfAbsent(profileId, () => <BrowserCookie>[]).add(cookie);
  }

  List<BrowserCookie> cookiesFor(String profileId, Uri uri) {
    final list = _jar[profileId] ?? const <BrowserCookie>[];
    return list.where((c) {
      final domain = c.domain.toLowerCase().replaceFirst('.', '');
      return (uri.host == domain || uri.host.endsWith('.$domain')) &&
          uri.path.startsWith(c.path);
    }).toList(growable: false);
  }

  void clear(String profileId) => _jar.remove(profileId);
  void clearAll() => _jar.clear();
  int count(String profileId) => _jar[profileId]?.length ?? 0;

  bool _sameSite(String a, String b) {
    final left = a.split('.').reversed.take(2).toList().reversed.join('.');
    final right = b.split('.').reversed.take(2).toList().reversed.join('.');
    return left == right;
  }
}
