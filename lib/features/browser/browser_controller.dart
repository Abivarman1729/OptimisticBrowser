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

  // ===========================================================================
  // CORE DEPENDENCIES
  // ===========================================================================

  final LocalRepository _repository = const LocalRepository();
  final PrivacyService _privacy = const PrivacyService();
  final TabManager tabs = TabManager();

  final Map<String, WebViewController> _webViews =
      <String, WebViewController>{};

  // ===========================================================================
  // STATE
  // ===========================================================================

  String _currentUrl = '';
  String _title = 'Optimistic Browser';

  bool _loading = false;
  bool _incognito = false;

  List<SearchResult> _results = const <SearchResult>[];

  final String _searchCategory = 'web';
  String _lastSearchQuery = '';

  AppError? _lastError;

  bool _initialized = false;
  bool _disposed = false;

  int _navigationGeneration = 0;

  // ===========================================================================
  // GETTERS
  // ===========================================================================

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

  // ===========================================================================
  // TAB LOOKUP
  // ===========================================================================

  BrowserTab? _findTab(String tabId) {
    for (final BrowserTab tab in tabs.tabs) {
      if (tab.id == tabId) {
        return tab;
      }
    }

    return null;
  }

  // ===========================================================================
  // INITIAL TAB
  // ===========================================================================

  void _createInitialTab() {
    final BrowserTab tab = tabs.create();

    _webViews[tab.id] = _makeWebView(tab.id);

    _syncActive(notify: false);
  }

  // ===========================================================================
  // WEBVIEW CREATION
  // ===========================================================================

  WebViewController _makeWebView(String tabId) {
    late final WebViewController controller;

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          // -------------------------------------------------------------------
          // PAGE STARTED
          // -------------------------------------------------------------------
          onPageStarted: (String url) {
            _pageState(tabId: tabId, url: url, title: '', loading: true);
          },

          // -------------------------------------------------------------------
          // PAGE FINISHED
          // -------------------------------------------------------------------
          onPageFinished: (String url) {
            unawaited(_pageFinished(tabId, url));
          },

          // -------------------------------------------------------------------
          // WEB RESOURCE ERROR
          // -------------------------------------------------------------------
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

          // -------------------------------------------------------------------
          // NAVIGATION REQUEST
          // -------------------------------------------------------------------
          onNavigationRequest: (NavigationRequest request) {
            final String requestedUrl = request.url.trim();

            if (requestedUrl.isEmpty) {
              _setNavigationBlockedError();

              return NavigationDecision.prevent;
            }

            final Uri? uri = Uri.tryParse(requestedUrl);

            if (uri == null) {
              _setNavigationBlockedError();

              return NavigationDecision.prevent;
            }

            // Do not allow unsupported schemes.
            if (!UrlPolicy.isHttp(uri)) {
              _setNavigationBlockedError();

              return NavigationDecision.prevent;
            }

            // Respect browser security policy.
            if (UrlPolicy.isBlocked(uri)) {
              _setNavigationBlockedError();

              return NavigationDecision.prevent;
            }

            // -----------------------------------------------------------------
            // HTTP -> HTTPS UPGRADE
            // -----------------------------------------------------------------

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

  // ===========================================================================
  // PAGE FINISHED
  // ===========================================================================

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
      } catch (_) {
        // Title extraction failure must never break navigation.
      }
    }

    _pageState(tabId: tabId, url: url, title: pageTitle, loading: false);

    // -------------------------------------------------------------------------
    // PRIVATE TABS NEVER ENTER HISTORY
    // -------------------------------------------------------------------------

    if (tab.mode == BrowserTabMode.normal && url.trim().isNotEmpty) {
      try {
        await _repository.addHistory(title: pageTitle, url: url);
      } catch (_) {
        // History failure must never crash browser navigation.
      }

      await persistSession();
    }
  }

  // ===========================================================================
  // PAGE STATE
  // ===========================================================================

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

  // ===========================================================================
  // LOADING STATE
  // ===========================================================================

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

  // ===========================================================================
  // NAVIGATION ERROR
  // ===========================================================================

  void _setNavigationBlockedError() {
    _lastError = const AppError(
      AppErrorType.navigationBlocked,
      'Navigation was blocked by the browser security policy.',
    );
  }

  // ===========================================================================
  // ACTIVE TAB SYNC
  // ===========================================================================

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

  // ===========================================================================
  // SAFE NOTIFY
  // ===========================================================================

  void _notifySafely() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  // ===========================================================================
  // INITIALIZE SESSION
  // ===========================================================================

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

          // Private tabs must never be restored.
          if (tab.mode == BrowserTabMode.normal) {
            savedTabs.add(tab);
          }
        } catch (_) {
          // Ignore a corrupted individual tab.
        }
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
      // Corrupted session data must never
      // prevent the browser from starting.

      _syncActive();
    }
  }

  // ===========================================================================
  // PERSIST SESSION
  // ===========================================================================

  Future<void> persistSession() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Only normal tabs are persisted.
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
    } catch (_) {
      // Persistence must never crash the browser.
    }
  }

  // ===========================================================================
  // ADDRESS BAR / SEARCH INPUT
  // ===========================================================================

  Future<void> openInput(String input) async {
    final String value = input.trim();

    if (value.isEmpty) {
      return;
    }

    _lastError = null;
    _lastSearchQuery = '';

    // -------------------------------------------------------------------------
    // DIRECT URL
    // -------------------------------------------------------------------------

    if (UrlPolicy.looksLikeUrl(value)) {
      try {
        final Uri directUri = UrlPolicy.resolveDirectUrl(value);

        await _loadUrl(directUri);
      } catch (error) {
        _lastError = AppError(AppErrorType.navigationBlocked, error.toString());

        _notifySafely();
      }

      return;
    }

    // -------------------------------------------------------------------------
    // SEARCH QUERY
    // -------------------------------------------------------------------------

    _lastSearchQuery = value;

    final Uri searchUrl = Uri.https(
      'search.brave.com',
      '/search',
      <String, String>{'q': value},
    );

    await _loadUrl(searchUrl);
  }

  // ===========================================================================
  // OPEN SEARCH RESULT
  // ===========================================================================

  Future<void> openResult(String url) async {
    try {
      final Uri uri = UrlPolicy.resolveDirectUrl(url);

      await _loadUrl(uri);
    } catch (error) {
      _lastError = AppError(AppErrorType.navigationBlocked, error.toString());

      _notifySafely();
    }
  }

  // ===========================================================================
  // CORE URL LOADER
  // ===========================================================================

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

    // IMPORTANT:
    // Do not force loading=false here.
    // WebView callbacks control actual page loading state.

    if (generation != _navigationGeneration) {
      return;
    }

    active.url = uri.toString();

    if (tabs.active?.id == active.id) {
      _currentUrl = uri.toString();
    }

    // Private tabs are never persisted.
    if (active.mode == BrowserTabMode.normal) {
      await persistSession();
    }
  }

  // ===========================================================================
  // NEW TAB
  // ===========================================================================

  Future<void> newTab({bool private = false, String url = ''}) async {
    final BrowserTab tab = tabs.create(
      mode: private ? BrowserTabMode.private : BrowserTabMode.normal,
      url: url,
    );

    final WebViewController controller = _makeWebView(tab.id);

    _webViews[tab.id] = controller;

    // -------------------------------------------------------------------------
    // PRIVATE SESSION
    // -------------------------------------------------------------------------

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

    _syncActive();

    // -------------------------------------------------------------------------
    // OPTIONAL INITIAL URL
    // -------------------------------------------------------------------------

    final String cleanUrl = url.trim();

    if (cleanUrl.isNotEmpty) {
      final Uri? uri = Uri.tryParse(cleanUrl);

      if (uri != null) {
        await _loadUrl(uri, controllerOverride: controller);
      }
    }

    await persistSession();
  }

  // ===========================================================================
  // SELECT TAB
  // ===========================================================================

  Future<void> selectTab(String id) async {
    final BrowserTab? selected = _findTab(id);

    if (selected == null) {
      return;
    }

    tabs.select(id);

    _syncActive();

    await persistSession();
  }

  // ===========================================================================
  // CLOSE TAB
  // ===========================================================================

  Future<void> closeTab(String id) async {
    final BrowserTab? tab = _findTab(id);

    if (tab == null) {
      return;
    }

    final WebViewController? controller = _webViews[tab.id];

    if (tab.mode == BrowserTabMode.private && controller != null) {
      try {
        await _privacy.endPrivateSession(controller);
      } catch (_) {
        // Cleanup failure must not prevent tab closure.
      }
    }

    tabs.close(id);

    _webViews.remove(id);

    if (tabs.tabs.isEmpty) {
      await newTab();
      return;
    }

    _syncActive();

    await persistSession();
  }

  // ===========================================================================
  // REOPEN LAST CLOSED TAB
  // ===========================================================================

  Future<void> reopenLastClosed() async {
    final BrowserTab? tab = tabs.reopenLastClosed();

    if (tab == null) {
      return;
    }

    // Never reopen private browsing sessions.
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

  // ===========================================================================
  // PAGE TEXT
  // ===========================================================================

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

  // ===========================================================================
  // JAVASCRIPT VALUE DECODER
  // ===========================================================================

  String _decodeJavaScriptValue(Object? value) {
    if (value == null) {
      return '';
    }

    String result = value.toString();

    // webview_flutter can return JSON
    // encoded strings from JS evaluation.
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

  // ===========================================================================
  // EXTERNAL PAGE STATE
  // ===========================================================================

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

  // ===========================================================================
  // BACK
  // ===========================================================================

  Future<void> goBack() async {
    try {
      final WebViewController controller = webView;

      final bool canGoBack = await controller.canGoBack();

      if (canGoBack) {
        await controller.goBack();
      }
    } catch (error) {
      _lastError = AppError(AppErrorType.network, error.toString());

      _notifySafely();
    }
  }

  // ===========================================================================
  // FORWARD
  // ===========================================================================

  Future<void> goForward() async {
    try {
      final WebViewController controller = webView;

      final bool canGoForward = await controller.canGoForward();

      if (canGoForward) {
        await controller.goForward();
      }
    } catch (error) {
      _lastError = AppError(AppErrorType.network, error.toString());

      _notifySafely();
    }
  }

  // ===========================================================================
  // RELOAD
  // ===========================================================================

  Future<void> reload() async {
    try {
      await webView.reload();
    } catch (error) {
      _lastError = AppError(AppErrorType.network, error.toString());

      _notifySafely();
    }
  }

  // ===========================================================================
  // BOOKMARK
  // ===========================================================================

  Future<void> bookmarkCurrentPage() async {
    if (_currentUrl.trim().isEmpty) {
      return;
    }

    // Private pages must never be bookmarked.
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

  // ===========================================================================
  // PRIVATE DATA
  // ===========================================================================

  Future<void> clearPrivateData() async {
    if (!_incognito) {
      _lastError = const AppError(
        AppErrorType.permission,
        'Private-session cleanup is only available in a private tab.',
      );

      _notifySafely();

      return;
    }

    // IMPORTANT:
    //
    // Do not clear global WebView cookies/cache/storage.
    // webview_flutter public APIs do not provide isolated
    // per-tab persistent profiles.
    //
    // Clearing global data could affect normal tabs.
    _lastError = const AppError(
      AppErrorType.permission,
      'Private history/session persistence is isolated. '
      'Cookie, cache, and storage isolation requires a native '
      'WebView profile engine.',
    );

    _notifySafely();
  }

  // ===========================================================================
  // SEARCH STATE
  // ===========================================================================

  void clearSearchResults() {
    _results = const <SearchResult>[];

    _lastSearchQuery = '';

    _notifySafely();
  }

  // ===========================================================================
  // ERROR STATE
  // ===========================================================================

  void clearError() {
    if (_lastError == null) {
      return;
    }

    _lastError = null;

    _notifySafely();
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _disposed = true;

    // Persist only normal tabs.
    unawaited(persistSession());

    super.dispose();
  }
}
