
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
  final TabManager tabs = TabManager();
  final Map<String, WebViewController> _webViews = {};

  String _currentUrl = '';
  String _title = 'Optimistic Browser';
  bool _loading = false;
  bool _incognito = false;
  List<SearchResult> _results = const [];
  final String _searchCategory = 'web';
  String _lastSearchQuery = '';
  AppError? _lastError;

  WebViewController get webView {
    final active = tabs.active;
    if (active == null) throw StateError('No active browser tab.');
    return _webViews[active.id]!;
  }

  String get currentUrl => _currentUrl;
  String get title => _title;
  bool get loading => _loading;
  bool get incognito => _incognito;
  List<SearchResult> get results => _results;
  String get searchCategory => _searchCategory;
  String get lastSearchQuery => _lastSearchQuery;
  AppError? get lastError => _lastError;

  void _createInitialTab() {
    final tab = tabs.create();
    _webViews[tab.id] = _makeWebView(tab.id);
  }

  WebViewController _makeWebView(String tabId) {
    late final WebViewController controller;
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => _pageState(tabId, url, '', true),
          onPageFinished: (url) => _pageFinished(tabId, url),
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              _lastError = AppError(
                AppErrorType.network,
                error.description,
              );
              notifyListeners();
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null || !UrlPolicy.isHttp(uri) || UrlPolicy.isBlocked(uri)) {
              _lastError = const AppError(
                AppErrorType.navigationBlocked,
                'Navigation was blocked by the browser security policy.',
              );
              notifyListeners();
              return NavigationDecision.prevent;
            }
            if (uri.scheme == 'http') {
              controller.loadRequest(uri.replace(scheme: 'https'));
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    return controller;
  }


  Future<void> _pageFinished(String tabId, String url) async {
    final tab = tabs.tabs.where((e) => e.id == tabId).firstOrNull;
    if (tab == null) return;
    var title = tab.title;
    try {
      final value = await _webViews[tabId]?.runJavaScriptReturningResult(
        "document.title || ''",
      );
      title = value?.toString().replaceAll(r'\"', '"') ?? title;
      if (title.startsWith('"') && title.endsWith('"') && title.length >= 2) {
        title = title.substring(1, title.length - 1);
      }
    } catch (_) {}
    _pageState(tabId, url, title, false);
    if (tab.mode == BrowserTabMode.normal && url.isNotEmpty) {
      await _repository.addHistory(title: title, url: url);
      await persistSession();
    }
  }

  void _pageState(String tabId, String url, String title, bool loading) {
    final tab = tabs.tabs.where((e) => e.id == tabId).firstOrNull;
    if (tab == null) return;
    tab.url = url;
    if (title.isNotEmpty) tab.title = title;
    tab.isLoading = loading;
    if (tabs.active?.id == tabId) {
      _currentUrl = url;
      _title = tab.title;
      _loading = loading;
    }
    notifyListeners();
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('optimistic.session');
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final saved = (data['tabs'] as List<dynamic>? ?? [])
          .map((e) => BrowserTab.fromJson(e as Map<String, dynamic>))
          .where((e) => e.mode == BrowserTabMode.normal)
          .toList();
      if (saved.isEmpty) return;

      _webViews.clear();
      tabs.restore(saved, activeId: data['activeId'] as String?);
      for (final tab in saved) {
        final controller = _makeWebView(tab.id);
        _webViews[tab.id] = controller;
      }
      final active = tabs.active;
      if (active != null && active.url.isNotEmpty) {
        await _webViews[active.id]!.loadRequest(Uri.parse(active.url));
      }
      _syncActive();
    } catch (_) {
      // A corrupt session must never prevent the browser from starting.
    }
  }

  Future<void> persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    // Private tabs must never enter persisted session state.
    final normalTabs = tabs.tabs
        .where((tab) => tab.mode == BrowserTabMode.normal)
        .toList();
    final data = <String, dynamic>{
      'tabs': normalTabs.map((tab) => tab.toJson()).toList(),
      'activeId': tabs.active?.mode == BrowserTabMode.normal
          ? tabs.active?.id
          : normalTabs.isNotEmpty
              ? normalTabs.first.id
              : null,
    };
    await prefs.setString('optimistic.session', jsonEncode(data));
  }

  Future<void> openInput(String input) async {
    final value = input.trim();
    if (value.isEmpty) return;
    _lastError = null;

    if (UrlPolicy.looksLikeUrl(value)) {
      await _loadUrl(UrlPolicy.resolveDirectUrl(value));
      return;
    }

    _loading = true;
    _lastSearchQuery = value;
    _results = const [];
    notifyListeners();
    try {
      _results = await const SearchService().search(value, category: _searchCategory);
    } on AppError catch (error) {
      _lastError = error;
    } catch (error) {
      _lastError = AppError(AppErrorType.searchProvider, '$error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> openResult(String url) => _loadUrl(UrlPolicy.resolveDirectUrl(url));

  Future<void> _loadUrl(Uri uri) async {
    if (!UrlPolicy.isSafeNavigation(uri)) {
      throw const AppError(
        AppErrorType.navigationBlocked,
        'This domain is blocked by the browser security policy.',
      );
    }
    _lastError = null;
    _loading = true;
    _results = const [];
    notifyListeners();

    await webView.loadRequest(uri);
    final active = tabs.active;
    if (active != null) active.url = uri.toString();
    _currentUrl = uri.toString();

    await persistSession();
    _loading = false;
    notifyListeners();
  }

  void _syncActive() {
    final active = tabs.active;
    if (active == null) return;
    _currentUrl = active.url;
    _title = active.title;
    _loading = active.isLoading;
  }

  Future<void> newTab({bool private = false, String url = ''}) async {
    final tab = tabs.create(
      mode: private ? BrowserTabMode.private : BrowserTabMode.normal,
      url: url,
    );
    _webViews[tab.id] = _makeWebView(tab.id);
    if (private) {
      _incognito = true;
      await _privacy.preparePrivateSession(_webViews[tab.id]!);
    } else {
      _incognito = false;
    }
    _syncActive();
    notifyListeners();
    if (url.isNotEmpty) await _loadUrl(Uri.parse(url));
    await persistSession();
  }

  Future<void> selectTab(String id) async {
    final selected = tabs.tabs.where((e) => e.id == id).firstOrNull;
    if (selected == null) return;
    tabs.select(id);
    _incognito = selected.mode == BrowserTabMode.private;
    _syncActive();
    notifyListeners();
  }

  Future<void> closeTab(String id) async {
    final tab = tabs.tabs.where((e) => e.id == id).firstOrNull;
    if (tab == null) return;
    if (tab.mode == BrowserTabMode.private) {
      final controller = _webViews[tab.id];
      if (controller != null) await _privacy.endPrivateSession(controller);
    }
    tabs.close(id);
    _webViews.remove(id);
    if (tabs.tabs.isEmpty) {
      await newTab();
      return;
    }
    _incognito = tabs.active?.mode == BrowserTabMode.private;
    _syncActive();
    notifyListeners();
    await persistSession();
  }

  Future<void> reopenLastClosed() async {
    final tab = tabs.reopenLastClosed();
    if (tab == null) return;
    _webViews[tab.id] = _makeWebView(tab.id);
    _incognito = false;
    _syncActive();
    notifyListeners();
    if (tab.url.isNotEmpty) await _webViews[tab.id]!.loadRequest(Uri.parse(tab.url));
    await persistSession();
  }

  Future<String> pageText() async {
    try {
      final value = await webView.runJavaScriptReturningResult(
        "document.body ? document.body.innerText.slice(0, 60000) : ''",
      );
      return value.toString().replaceAll(r'\"', '"');
    } catch (_) {
      return '';
    }
  }

  void setPageState({
    required String url,
    required String title,
    required bool loading,
  }) {
    final active = tabs.active;
    if (active != null) {
      active.url = url;
      active.title = title.isEmpty ? 'Optimistic Browser' : title;
      active.isLoading = loading;
    }
    _currentUrl = url;
    _title = title.isEmpty ? 'Optimistic Browser' : title;
    _loading = loading;
    notifyListeners();
  }

  Future<void> goBack() async {
    if (await webView.canGoBack()) await webView.goBack();
  }

  Future<void> goForward() async {
    if (await webView.canGoForward()) await webView.goForward();
  }

  Future<void> reload() => webView.reload();

  Future<void> bookmarkCurrentPage() async {
    if (_currentUrl.isEmpty || _incognito) return;
    await _repository.addBookmark(title: _title, url: _currentUrl);
  }

  Future<void> clearPrivateData() async {
    if (!_incognito) {
      _lastError = const AppError(
        AppErrorType.permission,
        'Private-session cleanup is only available in a private tab.',
      );
      notifyListeners();
      return;
    }
    // Do not clear global WebView cookies/cache/local-storage. The public
    // webview_flutter API cannot isolate those stores per tab.
    _lastError = const AppError(
      AppErrorType.permission,
      'Private history/session persistence is isolated. Cookie/cache/storage '
      'isolation requires a native WebView profile engine.',
    );
    notifyListeners();
  }

  @override
  void dispose() {
    persistSession();
    super.dispose();
  }
}
