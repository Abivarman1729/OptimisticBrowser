import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/errors/app_error.dart';
import '../../core/utils/url_policy.dart';
import '../../data/local/local_repository.dart';
import '../../services/privacy/privacy_service.dart';
import '../../services/search/search_service.dart';
import 'models/browser_tab.dart';
import 'tab_manager.dart';

class OptimisticBrowserController extends ChangeNotifier {
  OptimisticBrowserController() {
    _createInitialTab();
  }

  final LocalRepository _repository = const LocalRepository();

  final PrivacyService _privacy = const PrivacyService();

  final SearchService _searchService = const SearchService();

  final TabManager tabs = TabManager();

  final Map<String, WebViewController> _webViews =
      <String, WebViewController>{};

  String _currentUrl = '';
  String _title = 'Optimistic Browser';

  bool _loading = false;
  bool _incognito = false;

  List<SearchResult> _results = const <SearchResult>[];

  String _searchCategory = 'web';

  String _lastSearchQuery = '';

  AppError? _lastError;

  bool _initialized = false;
  bool _disposed = false;

  int _navigationGeneration = 0;
  int _searchGeneration = 0;

  DateTime? _lastSearchCompletedAt;

  // ---------------------------------------------------------------------------
  // GETTERS
  // ---------------------------------------------------------------------------

  WebViewController get webView {
    final BrowserTab? active = tabs.active;

    if (active == null) {
      throw StateError('No active browser tab.');
    }

    final WebViewController? controller = _webViews[active.id];

    if (controller == null) {
      throw StateError('WebView controller not found for tab ${active.id}.');
    }

    return controller;
  }

  String get currentUrl => _currentUrl;

  String get title => _title;

  bool get loading => _loading;

  bool get incognito => _incognito;

  List<SearchResult> get results => List<SearchResult>.unmodifiable(_results);

  String get searchCategory => _searchCategory;

  String get lastSearchQuery => _lastSearchQuery;

  AppError? get lastError => _lastError;

  bool get hasSearchResults => _results.isNotEmpty;

  bool get hasSearchQuery => _lastSearchQuery.isNotEmpty;

  int get searchResultCount => _results.length;

  DateTime? get lastSearchCompletedAt => _lastSearchCompletedAt;

  bool get isSearchLoading => _loading && _lastSearchQuery.isNotEmpty;

  // ---------------------------------------------------------------------------
  // TAB HELPERS
  // ---------------------------------------------------------------------------

  BrowserTab? _findTab(String tabId) {
    for (final BrowserTab tab in tabs.tabs) {
      if (tab.id == tabId) {
        return tab;
      }
    }

    return null;
  }

  void _createInitialTab() {
    final BrowserTab tab = tabs.create();

    _webViews[tab.id] = _makeWebView(tab.id);

    _syncActive(notify: false);
  }

  // ---------------------------------------------------------------------------
  // WEBVIEW
  // ---------------------------------------------------------------------------

  WebViewController _makeWebView(String tabId) {
    late final WebViewController controller;

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            _pageState(tabId: tabId, url: url, title: '', loading: true);
          },
          onPageFinished: (String url) {
            unawaited(_pageFinished(tabId, url));
          },
          onWebResourceError: (WebResourceError error) {
            final bool mainFrame = error.isForMainFrame ?? true;

            if (!mainFrame) {
              return;
            }

            final String description = error.description.trim();

            _lastError = AppError(
              AppErrorType.network,
              description.isEmpty
                  ? 'The webpage could not be loaded.'
                  : description,
            );

            _setLoadingForTab(tabId, false);

            _notifySafely();
          },
          onNavigationRequest: (NavigationRequest request) {
            final String requestedUrl = request.url.trim();

            final Uri? uri = Uri.tryParse(requestedUrl);

            if (requestedUrl.isEmpty || uri == null) {
              _setNavigationBlockedError();
              return NavigationDecision.prevent;
            }

            if (!UrlPolicy.isHttp(uri)) {
              _setNavigationBlockedError();
              return NavigationDecision.prevent;
            }

            if (UrlPolicy.isBlocked(uri)) {
              _setNavigationBlockedError();
              return NavigationDecision.prevent;
            }

            if (uri.scheme.toLowerCase() == 'http') {
              final Uri secureUri = uri.replace(scheme: 'https');

              if (!UrlPolicy.isSafeNavigation(secureUri)) {
                _setNavigationBlockedError();
                return NavigationDecision.prevent;
              }

              unawaited(_loadUrl(secureUri, controllerOverride: controller));

              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    return controller;
  }

  Future<void> _pageFinished(String tabId, String url) async {
    final BrowserTab? tab = _findTab(tabId);

    if (tab == null) {
      return;
    }

    String pageTitle = tab.title;

    final WebViewController? controller = _webViews[tabId];

    if (controller != null) {
      try {
        final Object value = await controller.runJavaScriptReturningResult(
          'document.title || ""',
        );

        final String parsedTitle = _decodeJavaScriptValue(value);

        if (parsedTitle.trim().isNotEmpty) {
          pageTitle = parsedTitle.trim();
        }
      } catch (_) {}
    }

    _pageState(tabId: tabId, url: url, title: pageTitle, loading: false);

    if (tab.mode == BrowserTabMode.normal && url.trim().isNotEmpty) {
      try {
        await _repository.addHistory(title: pageTitle, url: url);
      } catch (_) {}

      await persistSession();
    }
  }

  void _pageState({
    required String tabId,
    required String url,
    required String title,
    required bool loading,
  }) {
    final BrowserTab? tab = _findTab(tabId);

    if (tab == null) {
      return;
    }

    tab.url = url;

    if (title.trim().isNotEmpty) {
      tab.title = title.trim();
    }

    tab.isLoading = loading;

    if (tabs.active?.id == tabId) {
      _currentUrl = url;

      _title = tab.title.trim().isEmpty ? 'Optimistic Browser' : tab.title;

      _loading = loading;
    }

    _notifySafely();
  }

  void _setLoadingForTab(String tabId, bool loading) {
    final BrowserTab? tab = _findTab(tabId);

    if (tab == null) {
      return;
    }

    tab.isLoading = loading;

    if (tabs.active?.id == tabId) {
      _loading = loading;
    }
  }

  void _setNavigationBlockedError() {
    _lastError = const AppError(
      AppErrorType.navigationBlocked,
      'Navigation was blocked by the browser security policy.',
    );

    _notifySafely();
  }

  void _syncActive({bool notify = true}) {
    final BrowserTab? active = tabs.active;

    if (active == null) {
      _currentUrl = '';
      _title = 'Optimistic Browser';
      _loading = false;
      _incognito = false;

      if (notify) {
        _notifySafely();
      }

      return;
    }

    _currentUrl = active.url;

    _title = active.title.trim().isEmpty ? 'Optimistic Browser' : active.title;

    _loading = active.isLoading;

    _incognito = active.mode == BrowserTabMode.private;

    if (notify) {
      _notifySafely();
    }
  }

  void _notifySafely() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // SESSION
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final String? raw = prefs.getString('optimistic.session');

      if (raw == null || raw.trim().isEmpty) {
        _syncActive();
        return;
      }

      final dynamic decoded = jsonDecode(raw);

      if (decoded is! Map<String, dynamic>) {
        _syncActive();
        return;
      }

      final dynamic rawTabs = decoded['tabs'];

      if (rawTabs is! List) {
        _syncActive();
        return;
      }

      final List<BrowserTab> savedTabs = <BrowserTab>[];

      for (final dynamic item in rawTabs) {
        try {
          if (item is! Map<String, dynamic>) {
            continue;
          }

          final BrowserTab tab = BrowserTab.fromJson(item);

          if (tab.mode == BrowserTabMode.normal) {
            savedTabs.add(tab);
          }
        } catch (_) {}
      }

      if (savedTabs.isEmpty) {
        _syncActive();
        return;
      }

      final String? savedActiveId = decoded['activeId'] is String
          ? decoded['activeId'] as String
          : null;

      _webViews.clear();

      tabs.restore(savedTabs, activeId: savedActiveId);

      for (final BrowserTab tab in savedTabs) {
        _webViews[tab.id] = _makeWebView(tab.id);
      }

      final BrowserTab? active = tabs.active;

      if (active != null && active.url.trim().isNotEmpty) {
        final Uri? uri = Uri.tryParse(active.url.trim());

        if (uri != null && UrlPolicy.isSafeNavigation(uri)) {
          try {
            await _webViews[active.id]!.loadRequest(uri);
          } catch (_) {
            _lastError = const AppError(
              AppErrorType.network,
              'The saved page could not be restored.',
            );
          }
        } else {
          active.url = '';
        }
      }

      _syncActive();
    } catch (_) {
      _syncActive();
    }
  }

  Future<void> persistSession() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final List<BrowserTab> normalTabs = tabs.tabs
          .where((BrowserTab tab) => tab.mode == BrowserTabMode.normal)
          .toList();

      String? activeId;

      final BrowserTab? active = tabs.active;

      if (active != null && active.mode == BrowserTabMode.normal) {
        activeId = active.id;
      } else if (normalTabs.isNotEmpty) {
        activeId = normalTabs.first.id;
      }

      final Map<String, dynamic> data = <String, dynamic>{
        'tabs': normalTabs.map((BrowserTab tab) => tab.toJson()).toList(),
        'activeId': activeId,
      };

      await prefs.setString('optimistic.session', jsonEncode(data));
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // SEARCH
  // ---------------------------------------------------------------------------

  void setSearchCategory(String category) {
    const Set<String> allowed = <String>{
      'web',
      'images',
      'videos',
      'news',
      'shopping',
    };

    final String value = category.trim().toLowerCase();

    if (!allowed.contains(value) || value == _searchCategory) {
      return;
    }

    _searchCategory = value;

    final String query = _lastSearchQuery.trim();

    _notifySafely();

    if (query.isNotEmpty) {
      unawaited(search(query));
    }
  }

  Future<void> search(String query, {bool forceRefresh = false}) async {
    final String value = query.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (value.isEmpty) {
      clearSearchResults();
      return;
    }

    if (value.length > 500) {
      _lastError = const AppError(
        AppErrorType.validation,
        'Search query is too long.',
      );

      _notifySafely();
      return;
    }

    final int generation = ++_searchGeneration;

    _lastSearchQuery = value;

    _lastError = null;

    _loading = true;

    // Results from a previous query must not
    // remain visible during a new search.
    _results = const <SearchResult>[];

    _notifySafely();

    try {
      final List<SearchResult> results = await _searchService.search(
        value,
        category: _searchCategory,
        forceRefresh: forceRefresh,
      );

      if (_disposed || generation != _searchGeneration) {
        return;
      }

      _results = List<SearchResult>.unmodifiable(results);

      _loading = false;

      _lastSearchCompletedAt = DateTime.now();

      if (_results.isEmpty) {
        _lastError = const AppError(
          AppErrorType.searchProvider,
          'No search results were found.',
        );
      }
    } on AppError catch (error) {
      if (_disposed || generation != _searchGeneration) {
        return;
      }

      _results = const <SearchResult>[];

      _loading = false;

      _lastError = error;
    } catch (error) {
      if (_disposed || generation != _searchGeneration) {
        return;
      }

      _results = const <SearchResult>[];

      _loading = false;

      _lastError = AppError(
        AppErrorType.network,
        'Search failed. Please try again.',
        cause: error,
      );
    }

    _notifySafely();
  }

  Future<void> retrySearch() async {
    final String query = _lastSearchQuery.trim();

    if (query.isEmpty) {
      return;
    }

    await search(query, forceRefresh: true);
  }

  void clearSearchResults() {
    _searchGeneration++;

    _results = const <SearchResult>[];

    _lastSearchQuery = '';

    _lastError = null;

    _loading = false;

    _lastSearchCompletedAt = null;

    _notifySafely();
  }

  Future<void> openInput(String input) async {
    final String value = input.trim();

    if (value.isEmpty) {
      return;
    }

    _lastError = null;

    if (UrlPolicy.looksLikeUrl(value)) {
      _lastSearchQuery = '';
      _searchGeneration++;

      try {
        final Uri directUri = UrlPolicy.resolveDirectUrl(value);

        await _loadUrl(directUri);
      } catch (error) {
        _lastError = AppError(AppErrorType.navigationBlocked, error.toString());

        _notifySafely();
      }

      return;
    }

    await search(value);
  }

  Future<void> openResult(String url) async {
    try {
      final Uri uri = UrlPolicy.resolveDirectUrl(url);

      _lastSearchQuery = '';

      _searchGeneration++;

      await _loadUrl(uri);
    } catch (error) {
      _lastError = AppError(AppErrorType.navigationBlocked, error.toString());

      _notifySafely();
    }
  }

  // ---------------------------------------------------------------------------
  // URL LOAD
  // ---------------------------------------------------------------------------

  Future<void> _loadUrl(
    Uri uri, {
    WebViewController? controllerOverride,
  }) async {
    if (!UrlPolicy.isSafeNavigation(uri)) {
      _lastError = const AppError(
        AppErrorType.navigationBlocked,
        'This domain is blocked by the browser security policy.',
      );

      _notifySafely();
      return;
    }

    final BrowserTab? active = tabs.active;

    if (active == null) {
      _lastError = const AppError(
        AppErrorType.navigationBlocked,
        'No active browser tab is available.',
      );

      _notifySafely();
      return;
    }

    final WebViewController? controller =
        controllerOverride ?? _webViews[active.id];

    if (controller == null) {
      _lastError = const AppError(
        AppErrorType.network,
        'The browser view is not available.',
      );

      _notifySafely();
      return;
    }

    final int generation = ++_navigationGeneration;

    _lastError = null;

    _results = const <SearchResult>[];

    _pageState(
      tabId: active.id,
      url: uri.toString(),
      title: active.title,
      loading: true,
    );

    try {
      await controller.loadRequest(uri);
    } catch (error) {
      if (generation != _navigationGeneration) {
        return;
      }

      _lastError = AppError(AppErrorType.network, error.toString());

      _pageState(
        tabId: active.id,
        url: uri.toString(),
        title: active.title,
        loading: false,
      );

      return;
    }

    if (generation != _navigationGeneration) {
      return;
    }

    active.url = uri.toString();

    if (tabs.active?.id == active.id) {
      _currentUrl = uri.toString();
    }

    if (active.mode == BrowserTabMode.normal) {
      await persistSession();
    }
  }

  // ---------------------------------------------------------------------------
  // TABS
  // ---------------------------------------------------------------------------

  Future<void> newTab({bool private = false, String url = ''}) async {
    final BrowserTab tab = tabs.create(
      mode: private ? BrowserTabMode.private : BrowserTabMode.normal,
      url: url,
    );

    final WebViewController controller = _makeWebView(tab.id);

    _webViews[tab.id] = controller;

    if (private) {
      _incognito = true;

      try {
        await _privacy.preparePrivateSession(controller);
      } catch (_) {
        _lastError = const AppError(
          AppErrorType.permission,
          'Private browsing mode could not be prepared.',
        );
      }
    } else {
      _incognito = false;
    }

    _lastSearchQuery = '';

    _searchGeneration++;

    _results = const <SearchResult>[];

    _syncActive();

    final String cleanUrl = url.trim();

    if (cleanUrl.isNotEmpty) {
      final Uri? uri = Uri.tryParse(cleanUrl);

      if (uri != null) {
        await _loadUrl(uri, controllerOverride: controller);
      }
    }

    await persistSession();
  }

  Future<void> selectTab(String id) async {
    final BrowserTab? selected = _findTab(id);

    if (selected == null) {
      return;
    }

    tabs.select(id);

    _syncActive();

    await persistSession();
  }

  Future<void> closeTab(String id) async {
    final BrowserTab? tab = _findTab(id);

    if (tab == null) {
      return;
    }

    final WebViewController? controller = _webViews[tab.id];

    if (tab.mode == BrowserTabMode.private && controller != null) {
      try {
        await _privacy.endPrivateSession(controller);
      } catch (_) {}
    }

    tabs.close(id);

    _webViews.remove(id);

    if (tabs.tabs.isEmpty) {
      await newTab();
      return;
    }

    _lastSearchQuery = '';

    _searchGeneration++;

    _results = const <SearchResult>[];

    _syncActive();

    await persistSession();
  }

  Future<void> reopenLastClosed() async {
    final BrowserTab? tab = tabs.reopenLastClosed();

    if (tab == null) {
      return;
    }

    if (tab.mode == BrowserTabMode.private) {
      _syncActive();
      return;
    }

    final WebViewController controller = _makeWebView(tab.id);

    _webViews[tab.id] = controller;

    _incognito = false;

    _syncActive();

    final String cleanUrl = tab.url.trim();

    if (cleanUrl.isNotEmpty) {
      final Uri? uri = Uri.tryParse(cleanUrl);

      if (uri != null && UrlPolicy.isSafeNavigation(uri)) {
        try {
          await controller.loadRequest(uri);
        } catch (error) {
          _lastError = AppError(AppErrorType.network, error.toString());

          _notifySafely();
        }
      }
    }

    await persistSession();
  }

  // ---------------------------------------------------------------------------
  // PAGE UTILITIES
  // ---------------------------------------------------------------------------

  Future<String> pageText() async {
    try {
      final Object value = await webView.runJavaScriptReturningResult(
        'document.body '
        '? document.body.innerText.slice(0, 60000) '
        ': ""',
      );

      return _decodeJavaScriptValue(value);
    } catch (_) {
      return '';
    }
  }

  String _decodeJavaScriptValue(Object? value) {
    if (value == null) {
      return '';
    }

    String result = value.toString();

    if (result.length >= 2 && result.startsWith('"') && result.endsWith('"')) {
      try {
        final dynamic decoded = jsonDecode(result);

        if (decoded is String) {
          result = decoded;
        }
      } catch (_) {
        result = result.substring(1, result.length - 1);
      }
    }

    return result.replaceAll(r'\"', '"').replaceAll(r'\n', '\n').trim();
  }

  void setPageState({
    required String url,
    required String title,
    required bool loading,
  }) {
    final BrowserTab? active = tabs.active;

    if (active != null) {
      active.url = url;

      active.title = title.trim().isEmpty ? 'Optimistic Browser' : title.trim();

      active.isLoading = loading;
    }

    _currentUrl = url;

    _title = title.trim().isEmpty ? 'Optimistic Browser' : title.trim();

    _loading = loading;

    _notifySafely();
  }

  Future<void> goBack() async {
    try {
      final WebViewController controller = webView;

      if (await controller.canGoBack()) {
        await controller.goBack();
      }
    } catch (error) {
      _lastError = AppError(AppErrorType.network, error.toString());

      _notifySafely();
    }
  }

  Future<void> goForward() async {
    try {
      final WebViewController controller = webView;

      if (await controller.canGoForward()) {
        await controller.goForward();
      }
    } catch (error) {
      _lastError = AppError(AppErrorType.network, error.toString());

      _notifySafely();
    }
  }

  Future<void> reload() async {
    try {
      await webView.reload();
    } catch (error) {
      _lastError = AppError(AppErrorType.network, error.toString());

      _notifySafely();
    }
  }

  Future<void> bookmarkCurrentPage() async {
    if (_currentUrl.trim().isEmpty) {
      return;
    }

    if (_incognito) {
      return;
    }

    try {
      await _repository.addBookmark(title: _title, url: _currentUrl);
    } catch (error) {
      _lastError = AppError(AppErrorType.permission, error.toString());

      _notifySafely();
    }
  }

  Future<void> clearPrivateData() async {
    if (!_incognito) {
      _lastError = const AppError(
        AppErrorType.permission,
        'Private-session cleanup is only available in a private tab.',
      );

      _notifySafely();
      return;
    }

    _lastError = const AppError(
      AppErrorType.permission,
      'Private history/session persistence is isolated. '
      'Cookie, cache, and storage isolation requires a native '
      'WebView profile engine.',
    );

    _notifySafely();
  }

  void clearError() {
    if (_lastError == null) {
      return;
    }

    _lastError = null;

    _notifySafely();
  }

  @override
  void dispose() {
    _disposed = true;

    _searchGeneration++;
    _navigationGeneration++;

    unawaited(persistSession());

    super.dispose();
  }
}
