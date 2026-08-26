import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/errors/app_error.dart';

class SearchResult {
  const SearchResult({
    required this.title,
    required this.url,
    required this.description,
  });

  final String title;
  final String url;
  final String description;

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      title: _readString(json, const [
        'title',
        'name',
        'headline',
      ]).ifEmpty('Untitled'),
      url: _readString(json, const ['url', 'link', 'href']),
      description: _readString(json, const [
        'description',
        'snippet',
        'summary',
        'content',
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'url': url,
      'description': description,
    };
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = json[key];

      if (value is String) {
        final String normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();

        if (normalized.isNotEmpty) {
          return normalized;
        }
      }
    }

    return '';
  }

  @override
  String toString() {
    return 'SearchResult(title: $title, url: $url)';
  }
}

extension on String {
  String ifEmpty(String fallback) {
    return isEmpty ? fallback : this;
  }
}

class SearchService {
  const SearchService();

  static const Duration _requestTimeout = Duration(seconds: 8);

  static const Duration _cacheLifetime = Duration(minutes: 2);

  static const int _maxAttempts = 3;

  static const int _defaultMaxResults = 50;

  static const int _maxAllowedResults = 100;

  static const int _maxCacheEntries = 20;

  // Shared in-process cache.
  static final Map<String, _SearchCacheEntry> _cache =
      <String, _SearchCacheEntry>{};

  static int _requestCount = 0;
  static int _cacheHitCount = 0;

  static int get requestCount => _requestCount;

  static int get cacheHitCount => _cacheHitCount;

  Future<List<SearchResult>> search(
    String query, {
    String category = 'web',
    int maxResults = _defaultMaxResults,
    bool forceRefresh = false,
  }) async {
    final String normalizedQuery = _normalizeQuery(query);

    if (normalizedQuery.isEmpty) {
      return const <SearchResult>[];
    }

    _validateQuery(normalizedQuery);

    final String normalizedCategory = _normalizeCategory(category);

    final int resultLimit = _normalizeResultLimit(maxResults);

    final String cacheKey = _buildCacheKey(
      normalizedQuery,
      normalizedCategory,
      resultLimit,
    );

    if (!forceRefresh) {
      final _SearchCacheEntry? cached = _cache[cacheKey];

      if (cached != null && !cached.isExpired) {
        _cacheHitCount++;

        return List<SearchResult>.unmodifiable(cached.results);
      }

      _cache.remove(cacheKey);
    }

    final Uri uri = _buildSearchUri(
      query: normalizedQuery,
      category: normalizedCategory,
    );

    Object? lastError;

    for (int attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        _requestCount++;

        final http.Response response = await _performRequest(uri);

        final List<SearchResult> results = _parseResponse(
          response,
          maxResults: resultLimit,
        );

        _putCache(cacheKey, results);

        return List<SearchResult>.unmodifiable(results);
      } on AppError catch (error) {
        lastError = error;

        if (!_shouldRetry(error, attempt)) {
          rethrow;
        }

        await _backoff(attempt);
      } catch (error) {
        lastError = error;

        if (attempt >= _maxAttempts) {
          throw AppError(
            AppErrorType.network,
            'Search service unavailable.',
            cause: error,
          );
        }

        await _backoff(attempt);
      }
    }

    throw AppError(
      AppErrorType.network,
      'Search request failed.',
      cause: lastError,
    );
  }

  void clearCache() {
    _cache.clear();
  }

  void removeCachedSearch(
    String query, {
    String category = 'web',
    int maxResults = _defaultMaxResults,
  }) {
    final String key = _buildCacheKey(
      _normalizeQuery(query),
      _normalizeCategory(category),
      _normalizeResultLimit(maxResults),
    );

    _cache.remove(key);
  }

  int get cacheSize => _cache.length;

  // ---------------------------------------------------------------------------
  // QUERY
  // ---------------------------------------------------------------------------

  String _normalizeQuery(String query) {
    return query.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _validateQuery(String query) {
    if (query.isEmpty) {
      throw const AppError(
        AppErrorType.validation,
        'Search query cannot be empty.',
      );
    }

    if (query.length > AppConfig.maxSearchLength) {
      throw AppError(
        AppErrorType.validation,
        'Search query is too long. Maximum length is '
        '${AppConfig.maxSearchLength} characters.',
      );
    }
  }

  String _normalizeCategory(String category) {
    const Set<String> supported = <String>{
      'web',
      'news',
      'images',
      'videos',
      'shopping',
    };

    final String value = category.trim().toLowerCase();

    if (!supported.contains(value)) {
      return 'web';
    }

    return value;
  }

  int _normalizeResultLimit(int value) {
    if (value <= 0) {
      return _defaultMaxResults;
    }

    return value > _maxAllowedResults ? _maxAllowedResults : value;
  }

  // ---------------------------------------------------------------------------
  // CACHE
  // ---------------------------------------------------------------------------

  String _buildCacheKey(String query, String category, int maxResults) {
    return '${category.toLowerCase()}'
        '|$maxResults'
        '|${query.toLowerCase()}';
  }

  void _putCache(String key, List<SearchResult> results) {
    _cache.remove(key);

    _cache[key] = _SearchCacheEntry(
      results: List<SearchResult>.unmodifiable(results),
      createdAt: DateTime.now(),
    );

    while (_cache.length > _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  // ---------------------------------------------------------------------------
  // REQUEST
  // ---------------------------------------------------------------------------

  Uri _buildSearchUri({required String query, required String category}) {
    final String base = AppConfig.apiBaseUrl.trim();

    if (base.isEmpty) {
      throw const AppError(
        AppErrorType.searchProvider,
        'Search API endpoint is not configured.',
      );
    }

    final Uri baseUri;

    try {
      baseUri = Uri.parse(base);
    } catch (error) {
      throw AppError(
        AppErrorType.searchProvider,
        'Search API endpoint is invalid.',
        cause: error,
      );
    }

    if (!baseUri.hasScheme || baseUri.host.isEmpty) {
      throw const AppError(
        AppErrorType.searchProvider,
        'Search API endpoint is invalid.',
      );
    }

    String path = baseUri.path.trim();

    if (path.isEmpty || path == '/') {
      path = '/api/search';
    } else if (!path.endsWith('/api/search')) {
      path = path.endsWith('/') ? '${path}api/search' : '$path/api/search';
    }

    return baseUri.replace(
      path: path,
      queryParameters: <String, String>{
        'q': query,
        'category': category,
        'region': AppConfig.defaultSearchRegion,
        'language': AppConfig.defaultSearchLanguage,
      },
    );
  }

  Future<http.Response> _performRequest(Uri uri) async {
    try {
      return await http
          .get(
            uri,
            headers: const <String, String>{
              'Accept': 'application/json',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(_requestTimeout);
    } on TimeoutException catch (error) {
      throw AppError(
        AppErrorType.timeout,
        'Search request timed out.',
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw AppError(
        AppErrorType.network,
        'Unable to connect to the search service.',
        cause: error,
      );
    } catch (error) {
      throw AppError(
        AppErrorType.network,
        'Unable to connect to the search service.',
        cause: error,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // RESPONSE
  // ---------------------------------------------------------------------------

  List<SearchResult> _parseResponse(
    http.Response response, {
    required int maxResults,
  }) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppError(
        AppErrorType.searchProvider,
        _httpErrorMessage(response.statusCode),
      );
    }

    final String body = response.body.trim();

    if (body.isEmpty) {
      throw const AppError(
        AppErrorType.searchProvider,
        'Search service returned an empty response.',
      );
    }

    final dynamic decoded;

    try {
      decoded = jsonDecode(body);
    } on FormatException catch (error) {
      throw AppError(
        AppErrorType.searchProvider,
        'Search service returned invalid JSON.',
        cause: error,
      );
    } catch (error) {
      throw AppError(
        AppErrorType.searchProvider,
        'Unable to decode search response.',
        cause: error,
      );
    }

    final List<dynamic> raw = _extractRawResults(decoded);

    if (raw.isEmpty) {
      return const <SearchResult>[];
    }

    final List<SearchResult> output = <SearchResult>[];

    final Set<String> seen = <String>{};

    for (final dynamic item in raw) {
      if (item is! Map) {
        continue;
      }

      final Map<String, dynamic> json = <String, dynamic>{
        for (final MapEntry<dynamic, dynamic> entry in item.entries)
          if (entry.key is String) entry.key as String: entry.value,
      };

      try {
        final SearchResult result = SearchResult.fromJson(json);

        final String url = _normalizeResultUrl(result.url);

        if (url.isEmpty) {
          continue;
        }

        final String key = _dedupeKey(url);

        if (!seen.add(key)) {
          continue;
        }

        output.add(
          SearchResult(
            title: result.title.trim().isEmpty
                ? 'Untitled'
                : _cleanText(result.title),
            url: url,
            description: _cleanText(result.description),
          ),
        );

        if (output.length >= maxResults) {
          break;
        }
      } catch (_) {
        continue;
      }
    }

    return output;
  }

  List<dynamic> _extractRawResults(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }

    if (decoded is! Map) {
      throw const AppError(
        AppErrorType.searchProvider,
        'Search service returned an unsupported response format.',
      );
    }

    dynamic value = decoded['results'];

    if (value is List) {
      return value;
    }

    value = decoded['data'];

    if (value is Map) {
      final dynamic nested = value['results'];

      if (nested is List) {
        return nested;
      }

      final dynamic items = value['items'];

      if (items is List) {
        return items;
      }
    }

    value = decoded['items'];

    if (value is List) {
      return value;
    }

    value = decoded['hits'];

    if (value is List) {
      return value;
    }

    return const <dynamic>[];
  }

  // ---------------------------------------------------------------------------
  // RESULT NORMALIZATION
  // ---------------------------------------------------------------------------

  String _normalizeResultUrl(String value) {
    final String raw = value.trim();

    if (raw.isEmpty) {
      return '';
    }

    final Uri? uri = Uri.tryParse(raw);

    if (uri == null || uri.host.isEmpty) {
      return '';
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return '';
    }

    if (uri.userInfo.isNotEmpty) {
      return '';
    }

    return uri.toString();
  }

  String _dedupeKey(String url) {
    final Uri? uri = Uri.tryParse(url);

    if (uri == null) {
      return url.toLowerCase();
    }

    final String scheme = uri.scheme.toLowerCase();

    final String host = uri.host.toLowerCase();

    final String path = uri.path.isEmpty ? '/' : uri.path;

    return '$scheme://$host$path'
        '${uri.hasQuery ? '?${uri.query}' : ''}';
  }

  String _cleanText(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ---------------------------------------------------------------------------
  // RETRY
  // ---------------------------------------------------------------------------

  bool _shouldRetry(AppError error, int attempt) {
    if (attempt >= _maxAttempts) {
      return false;
    }

    switch (error.type) {
      case AppErrorType.timeout:
      case AppErrorType.network:
        return true;

      case AppErrorType.searchProvider:
        final String message = error.message;

        return message.contains('HTTP 408') ||
            message.contains('HTTP 429') ||
            message.contains('HTTP 500') ||
            message.contains('HTTP 502') ||
            message.contains('HTTP 503') ||
            message.contains('HTTP 504');

      default:
        return false;
    }
  }

  Future<void> _backoff(int attempt) async {
    final Duration duration = attempt == 1
        ? const Duration(milliseconds: 300)
        : const Duration(milliseconds: 800);

    await Future<void>.delayed(duration);
  }

  // ---------------------------------------------------------------------------
  // STATUS
  // ---------------------------------------------------------------------------

  String _httpErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Search request was invalid.';
      case 401:
        return 'Search service authentication failed.';
      case 403:
        return 'Search service access was denied.';
      case 404:
        return 'Search endpoint was not found.';
      case 408:
        return 'Search service request timed out.';
      case 429:
        return 'Search service rate limit was reached.';
      case 500:
        return 'Search service encountered an internal error.';
      case 502:
        return 'Search service gateway error.';
      case 503:
        return 'Search service is temporarily unavailable.';
      case 504:
        return 'Search service gateway timed out.';
      default:
        return 'Search service returned HTTP $statusCode.';
    }
  }
}

class _SearchCacheEntry {
  _SearchCacheEntry({required this.results, required this.createdAt});

  final List<SearchResult> results;
  final DateTime createdAt;

  bool get isExpired {
    return DateTime.now().difference(createdAt) > SearchService._cacheLifetime;
  }
}
