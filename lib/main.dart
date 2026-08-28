import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OptimisticBrowserApp());
}

class OptimisticBrowserApp extends StatefulWidget {
  const OptimisticBrowserApp({super.key});

  @override
  State<OptimisticBrowserApp> createState() => _OptimisticBrowserAppState();
}

class _OptimisticBrowserAppState extends State<OptimisticBrowserApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Optimistic Browser',
      themeMode: _themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: BrowserShell(themeMode: _themeMode, onThemeChanged: _setThemeMode),
    );
  }
}

class AppTheme {
  static const Color primary = Color(0xFF8A6CFF);
  static const Color cyan = Color(0xFF25D9FF);
  static const Color darkBackground = Color(0xFF070912);
  static const Color darkSurface = Color(0xFF0F1422);
  static const Color darkSurface2 = Color(0xFF151B2B);

  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkSurface,
      dividerColor: Colors.white10,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF090D18),
        indicatorColor: primary.withValues(alpha: .20),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750D8),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      cardColor: Colors.white,
      dividerColor: Colors.black12,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F6FA),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: scheme.primary.withValues(alpha: .13),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEFF0F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class BrowserTab {
  BrowserTab({
    required this.id,
    required this.initialUrl,
    required this.incognito,
  });

  final int id;
  final String initialUrl;
  final bool incognito;

  late WebViewController controller;

  String title = 'New Tab';
  String currentUrl = '';
  int progress = 0;
  bool loading = false;
  String? error;
}

class HistoryItem {
  HistoryItem({required this.title, required this.url, required this.time});

  final String title;
  final String url;
  final DateTime time;
}

class BookmarkItem {
  BookmarkItem({required this.title, required this.url});

  final String title;
  final String url;
}

class DownloadItem {
  DownloadItem({required this.name, required this.url, required this.time});

  final String name;
  final String url;
  final DateTime time;
}

class NoteItem {
  NoteItem({required this.title, required this.body, required this.created});

  final String title;
  final String body;
  final DateTime created;
}

class QuickLink {
  const QuickLink({
    required this.title,
    required this.url,
    required this.icon,
    required this.color,
  });

  final String title;
  final String url;
  final IconData icon;
  final Color color;
}

class BrowserShell extends StatefulWidget {
  const BrowserShell({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<BrowserShell> createState() => _BrowserShellState();
}

class _BrowserShellState extends State<BrowserShell> {
  final List<BrowserTab> _tabs = <BrowserTab>[];
  final List<HistoryItem> _history = <HistoryItem>[];
  final List<BookmarkItem> _bookmarks = <BookmarkItem>[];
  final List<DownloadItem> _downloads = <DownloadItem>[];
  final List<NoteItem> _notes = <NoteItem>[];

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _aiController = TextEditingController();
  final TextEditingController _noteTitleController = TextEditingController();
  final TextEditingController _noteBodyController = TextEditingController();

  int _selectedTab = 0;
  int _section = 0;
  int _nextTabId = 1;

  bool _incognito = false;
  bool _javaScript = true;
  bool _desktopSite = false;
  bool _readerMode = false;
  bool _adBlock = false;
  bool _safeSearch = true;
  bool _showHomeHeader = true;

  String _searchEngine = 'Google';
  String _aiProvider = 'Built-in demo';
  String _aiAnswer = '';
  String _findQuery = '';

  final List<QuickLink> _quickLinks = const <QuickLink>[
    QuickLink(
      title: 'Google',
      url: 'https://www.google.com',
      icon: Icons.search_rounded,
      color: Color(0xFF4285F4),
    ),
    QuickLink(
      title: 'YouTube',
      url: 'https://www.youtube.com',
      icon: Icons.play_circle_fill_rounded,
      color: Color(0xFFFF0033),
    ),
    QuickLink(
      title: 'WhatsApp',
      url: 'https://web.whatsapp.com',
      icon: Icons.chat_rounded,
      color: Color(0xFF25D366),
    ),
    QuickLink(
      title: 'Instagram',
      url: 'https://www.instagram.com',
      icon: Icons.camera_alt_rounded,
      color: Color(0xFFE4405F),
    ),
    QuickLink(
      title: 'GitHub',
      url: 'https://github.com',
      icon: Icons.code_rounded,
      color: Color(0xFF8B8BFF),
    ),
    QuickLink(
      title: 'Maps',
      url: 'https://maps.google.com',
      icon: Icons.map_rounded,
      color: Color(0xFF34A853),
    ),
    QuickLink(
      title: 'Spotify',
      url: 'https://open.spotify.com',
      icon: Icons.music_note_rounded,
      color: Color(0xFF1DB954),
    ),
    QuickLink(
      title: 'Reddit',
      url: 'https://www.reddit.com',
      icon: Icons.forum_rounded,
      color: Color(0xFFFF4500),
    ),
  ];

  BrowserTab get _currentTab => _tabs[_selectedTab];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _createTab(loadHome: true);
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _aiController.dispose();
    _noteTitleController.dispose();
    _noteBodyController.dispose();
    super.dispose();
  }

  void _createTab({bool loadHome = false, String? url, bool? incognito}) {
    final BrowserTab tab = BrowserTab(
      id: _nextTabId++,
      initialUrl: url ?? 'https://www.google.com',
      incognito: incognito ?? _incognito,
    );

    tab.controller = WebViewController()
      ..setJavaScriptMode(
        _javaScript ? JavaScriptMode.unrestricted : JavaScriptMode.disabled,
      )
      ..setBackgroundColor(Theme.of(context).scaffoldBackgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (!mounted) return;
            setState(() => tab.progress = progress);
          },
          onPageStarted: (String url) {
            if (!mounted) return;
            setState(() {
              tab.currentUrl = url;
              tab.loading = true;
              tab.error = null;
            });
            _syncAddressBar(tab);
          },
          onPageFinished: (String url) async {
            if (!mounted) return;
            final String? pageTitle = await tab.controller.getTitle();
            if (!mounted) return;

            setState(() {
              tab.currentUrl = url;
              tab.loading = false;
              if (pageTitle != null && pageTitle.trim().isNotEmpty) {
                tab.title = pageTitle.trim();
              }
            });

            _syncAddressBar(tab);

            if (!tab.incognito && url.isNotEmpty) {
              _recordHistory(tab.title, url);
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (!mounted) return;
            if (error.isForMainFrame ?? true) {
              setState(() {
                tab.loading = false;
                tab.error = error.description;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..enableZoom(true);

    _tabs.add(tab);

    if (mounted) {
      setState(() => _selectedTab = _tabs.length - 1);
    } else {
      _selectedTab = _tabs.length - 1;
    }

    final String destination =
        url ?? (loadHome ? 'https://www.google.com' : tab.initialUrl);

    tab.controller.loadRequest(Uri.parse(destination));
  }

  void _closeTab(int index) {
    if (_tabs.length == 1) {
      _tabs.first.controller.loadRequest(Uri.parse('https://www.google.com'));
      setState(() {
        _selectedTab = 0;
        _addressController.clear();
      });
      return;
    }

    setState(() {
      _tabs.removeAt(index);
      if (_selectedTab > index) {
        _selectedTab--;
      } else if (_selectedTab >= _tabs.length) {
        _selectedTab = _tabs.length - 1;
      }
    });

    _syncAddressBar(_currentTab);
  }

  void _selectTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    setState(() {
      _selectedTab = index;
      _section = 0;
    });
    _syncAddressBar(_tabs[index]);
  }

  void _syncAddressBar(BrowserTab tab) {
    if (!mounted || tab != _currentTab) return;
    final String value = tab.currentUrl;
    if (_addressController.text != value) {
      _addressController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  bool _looksLikeUrl(String value) {
    final String input = value.trim();
    if (input.contains(' ')) return false;
    if (input.startsWith('http://')) return true;
    if (input.startsWith('https://')) return true;
    if (input.startsWith('www.')) return true;
    return input.contains('.') && !input.startsWith('.');
  }

  String _searchUrl(String query) {
    final String q = Uri.encodeComponent(query);
    switch (_searchEngine) {
      case 'Bing':
        return 'https://www.bing.com/search?q=$q';
      case 'DuckDuckGo':
        return 'https://duckduckgo.com/?q=$q';
      default:
        return 'https://www.google.com/search?q=$q';
    }
  }

  void _navigate(String rawInput) {
    final String value = rawInput.trim();
    if (value.isEmpty) return;

    final String target = _looksLikeUrl(value)
        ? (value.startsWith('http') ? value : 'https://$value')
        : _searchUrl(value);

    final Uri? uri = Uri.tryParse(target);
    if (uri == null || !uri.hasScheme) {
      _showSnack('Invalid address');
      return;
    }

    _currentTab.controller.loadRequest(uri);
    FocusScope.of(context).unfocus();
  }

  Future<void> _goBack() async {
    if (await _currentTab.controller.canGoBack()) {
      await _currentTab.controller.goBack();
    } else {
      _showSnack('No previous page');
    }
  }

  Future<void> _goForward() async {
    if (await _currentTab.controller.canGoForward()) {
      await _currentTab.controller.goForward();
    } else {
      _showSnack('No next page');
    }
  }

  Future<void> _reload() async {
    await _currentTab.controller.reload();
  }

  void _goHome() {
    _currentTab.controller.loadRequest(Uri.parse('https://www.google.com'));
  }

  void _openQuickLink(QuickLink link) {
    _currentTab.controller.loadRequest(Uri.parse(link.url));
    setState(() => _section = 0);
  }

  void _recordHistory(String title, String url) {
    if (url.isEmpty || url == 'about:blank') return;

    _history.removeWhere((HistoryItem item) => item.url == url);
    _history.insert(
      0,
      HistoryItem(
        title: title.isEmpty ? 'Web page' : title,
        url: url,
        time: DateTime.now(),
      ),
    );

    if (_history.length > 250) {
      _history.removeRange(250, _history.length);
    }

    if (mounted) setState(() {});
  }

  void _clearHistory() {
    setState(() => _history.clear());
    _showSnack('Browsing history cleared');
  }

  bool _isBookmarked(String url) {
    return _bookmarks.any((BookmarkItem item) => item.url == url);
  }

  void _toggleBookmark() {
    final String url = _currentTab.currentUrl;
    if (url.isEmpty) {
      _showSnack('No page to bookmark');
      return;
    }

    if (_isBookmarked(url)) {
      setState(() {
        _bookmarks.removeWhere((BookmarkItem item) => item.url == url);
      });
      _showSnack('Bookmark removed');
      return;
    }

    setState(() {
      _bookmarks.insert(
        0,
        BookmarkItem(
          title: _currentTab.title.isEmpty ? 'Saved page' : _currentTab.title,
          url: url,
        ),
      );
    });
    _showSnack('Bookmark added');
  }

  void _openHistoryItem(HistoryItem item) {
    _currentTab.controller.loadRequest(Uri.parse(item.url));
    setState(() => _section = 0);
  }

  void _openBookmark(BookmarkItem item) {
    _currentTab.controller.loadRequest(Uri.parse(item.url));
    setState(() => _section = 0);
  }

  void _prepareDownload() {
    final String url = _currentTab.currentUrl;
    if (url.isEmpty) {
      _showSnack('There is no active page');
      return;
    }

    final String name = _currentTab.title.isEmpty
        ? 'web_page'
        : _safeFileName(_currentTab.title);

    setState(() {
      _downloads.insert(
        0,
        DownloadItem(name: '$name.html', url: url, time: DateTime.now()),
      );
    });

    _showSnack(
      'Download item added. Native file saving can be connected next.',
    );
  }

  String _safeFileName(String value) {
    final String cleaned = value.replaceAll(RegExp(r'[^a-zA-Z0-9 _-]'), '');
    final String compact = cleaned.trim().replaceAll(RegExp(r'\s+'), '_');
    return compact.isEmpty ? 'web_page' : compact;
  }

  void _toggleJavaScript(bool value) {
    setState(() => _javaScript = value);
    _currentTab.controller.setJavaScriptMode(
      value ? JavaScriptMode.unrestricted : JavaScriptMode.disabled,
    );
  }

  Future<void> _toggleReaderMode(bool value) async {
    setState(() => _readerMode = value);

    if (!value) {
      await _currentTab.controller.reload();
      return;
    }

    const String script = '''
      (function() {
        var body = document.body;
        if (!body) return;
        document.documentElement.style.background = '#f7f4ec';
        body.style.background = '#f7f4ec';
        body.style.color = '#202020';
        body.style.fontFamily = 'Georgia, serif';
        body.style.maxWidth = '760px';
        body.style.margin = '0 auto';
        body.style.padding = '32px';
        body.style.fontSize = '19px';
        var all = document.querySelectorAll('img, video, iframe, aside, nav, footer');
        for (var i = 0; i < all.length; i++) {
          all[i].style.maxWidth = '100%';
          if (all[i].tagName !== 'IMG') all[i].style.display = 'none';
        }
      })();
    ''';

    await _currentTab.controller.runJavaScript(script);
  }

  Future<void> _findInPage() async {
    final String query = _findQuery.trim();
    if (query.isEmpty) {
      _showSnack('Enter text to find');
      return;
    }

    final String safe = query.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

    await _currentTab.controller.runJavaScript('''
      (function() {
        var text = '$safe';
        var walker = document.createTreeWalker(
          document.body,
          NodeFilter.SHOW_TEXT
        );
        var node;
        while (node = walker.nextNode()) {
          if (node.nodeValue.toLowerCase().indexOf(text.toLowerCase()) >= 0) {
            node.parentElement.scrollIntoView({
              behavior: 'smooth',
              block: 'center'
            });
            break;
          }
        }
      })();
    ''');

    if (mounted) Navigator.pop(context);
  }

  void _toggleDesktopSite(bool value) {
    setState(() => _desktopSite = value);
    _showSnack(
      value
          ? 'Desktop-site preference enabled'
          : 'Desktop-site preference disabled',
    );
  }

  void _runAiMode() {
    final String query = _aiController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _aiAnswer =
            'Ask a question, request a summary, or describe what you want to research.';
      });
      return;
    }

    final String page = _currentTab.title.isEmpty
        ? 'the current web page'
        : _currentTab.title;

    setState(() {
      _aiAnswer =
          '''
AI Mode is ready for: “$query”

Current context: $page

This build includes the AI workspace and notebook flow. The answer engine is
local/demo-only because no external AI API key or private backend is embedded.

For production AI, connect _runAiMode() to your own secure server. Never ship
private API keys inside an APK.
''';
    });
  }

  void _summarizeCurrentPage() {
    final String title = _currentTab.title.isEmpty
        ? 'Current page'
        : _currentTab.title;

    setState(() {
      _aiAnswer =
          '''
Quick page brief

Title: $title
URL: ${_currentTab.currentUrl}

Optimistic Browser has captured the page context. A production AI connector
can read approved page text and return a real summary, key points, sources,
and follow-up questions.
''';
      _section = 3;
    });
  }

  void _showNewNoteDialog() {
    _noteTitleController.clear();
    _noteBodyController.clear();

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('New notebook note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: _noteTitleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteBodyController,
                  minLines: 5,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final String title = _noteTitleController.text.trim();
                final String body = _noteBodyController.text.trim();
                if (title.isEmpty && body.isEmpty) return;

                setState(() {
                  _notes.insert(
                    0,
                    NoteItem(
                      title: title.isEmpty ? 'Untitled note' : title,
                      body: body,
                      created: DateTime.now(),
                    ),
                  );
                });

                Navigator.pop(dialogContext);
                _showSnack('Note saved');
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteNote(NoteItem note) {
    setState(() => _notes.remove(note));
  }

  void _chooseSearchEngine() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const ListTile(
                title: Text(
                  'Search engine',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
              RadioGroup<String>(
                groupValue: _searchEngine,
                onChanged: (String? value) {
                  if (value == null) return;

                  setState(() => _searchEngine = value);
                  Navigator.pop(sheetContext);
                },
                child: Column(
                  children: <Widget>[
                    for (final String engine in <String>[
                      'Google',
                      'Bing',
                      'DuckDuckGo',
                    ])
                      RadioListTile<String>(value: engine, title: Text(engine)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _chooseAiProvider() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const ListTile(
                title: Text(
                  'AI provider',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
              RadioGroup<String>(
                groupValue: _aiProvider,
                onChanged: (String? value) {
                  if (value == null) return;

                  setState(() => _aiProvider = value);
                  Navigator.pop(sheetContext);
                },
                child: Column(
                  children: <Widget>[
                    for (final String provider in <String>[
                      'Built-in demo',
                      'OpenAI GPT-3.5',
                      'OpenAI GPT-4',
                      'Anthropic Claude',
                    ])
                      RadioListTile<String>(
                        value: provider,
                        title: Text(provider),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            if (_section == 0) _buildBrowserHeader(),
            Expanded(
              child: IndexedStack(
                index: _section,
                children: <Widget>[
                  _buildBrowserPage(),
                  _buildHomePage(),
                  _buildSavedPage(),
                  _buildAiPage(),
                  _buildNotebookPage(),
                  _buildSettingsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBrowserHeader() {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(
            children: <Widget>[
              const CosmicLogo(size: 42),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Optimistic Browser',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: 'Incognito',
                onPressed: () {
                  setState(() => _incognito = !_incognito);
                  _showSnack(
                    _incognito
                        ? 'Incognito mode enabled'
                        : 'Incognito mode disabled',
                  );
                },
                icon: Icon(
                  _incognito
                      ? Icons.visibility_off_rounded
                      : Icons.person_outline_rounded,
                ),
              ),
              IconButton(
                tooltip: 'Tabs',
                onPressed: _showTabsSheet,
                icon: const Icon(Icons.tab_rounded),
              ),
              IconButton(
                tooltip: 'More',
                onPressed: _showMainMenu,
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
          ),
        ),
        _buildAddressBar(),
        if (_currentTab.loading)
          LinearProgressIndicator(
            minHeight: 2,
            value: _currentTab.progress / 100,
          ),
      ],
    );
  }

  Widget _buildAddressBar() {
    final bool secure = _currentTab.currentUrl.startsWith('https://');

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: .12),
          ),
        ),
        child: Row(
          children: <Widget>[
            const SizedBox(width: 12),
            Icon(
              secure ? Icons.lock_rounded : Icons.language_rounded,
              size: 19,
              color: secure
                  ? Colors.greenAccent
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _addressController,
                onSubmitted: _navigate,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                decoration: const InputDecoration(
                  hintText: 'Search or enter website',
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Search',
              onPressed: () => _navigate(_addressController.text),
              icon: const Icon(Icons.search_rounded),
            ),
            IconButton(
              tooltip: _isBookmarked(_currentTab.currentUrl)
                  ? 'Remove bookmark'
                  : 'Add bookmark',
              onPressed: _toggleBookmark,
              icon: Icon(
                _isBookmarked(_currentTab.currentUrl)
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowserPage() {
    return Column(
      children: <Widget>[
        Expanded(
          child: Stack(
            children: <Widget>[
              WebViewWidget(controller: _currentTab.controller),
              if (_currentTab.error != null)
                Positioned.fill(child: _buildWebError(_currentTab.error!)),
            ],
          ),
        ),
        _buildBrowserToolbar(),
      ],
    );
  }

  Widget _buildWebError(String message) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.cloud_off_rounded, size: 54),
            const SizedBox(height: 14),
            const Text(
              'Page could not be loaded',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowserToolbar() {
    return Material(
      elevation: 10,
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: <Widget>[
              _toolbarButton(Icons.arrow_back_ios_new_rounded, 'Back', _goBack),
              _toolbarButton(
                Icons.arrow_forward_ios_rounded,
                'Forward',
                _goForward,
              ),
              _toolbarButton(Icons.home_rounded, 'Home', _goHome),
              _toolbarButton(Icons.refresh_rounded, 'Reload', _reload),
              _toolbarButton(
                Icons.add_rounded,
                'New tab',
                () => _createTab(loadHome: true),
              ),
              _toolbarButton(
                Icons.auto_awesome_rounded,
                'AI',
                () => setState(() => _section = 3),
              ),
              _toolbarButton(
                Icons.download_outlined,
                'Download',
                _prepareDownload,
              ),
              _toolbarButton(Icons.share_outlined, 'Share', _shareCurrentPage),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbarButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: IconButton(tooltip: label, onPressed: onTap, icon: Icon(icon)),
    );
  }

  Widget _buildHomePage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
      children: <Widget>[
        if (_showHomeHeader) ...<Widget>[
          const SizedBox(height: 12),
          const Center(child: CosmicLogo(size: 92)),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Optimistic Browser',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w900,
                letterSpacing: -.6,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: Text(
              'Fast  •  Private  •  Intelligent',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: .58),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        _buildHomeSearch(),
        const SizedBox(height: 26),
        _sectionTitle('Quick access'),
        const SizedBox(height: 12),
        _buildQuickLinks(),
        const SizedBox(height: 28),
        _buildDiscoverCard(),
        const SizedBox(height: 14),
        _buildFeatureGrid(),
      ],
    );
  }

  Widget _buildHomeSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .20),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            blurRadius: 28,
            spreadRadius: -12,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .30),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 10),
          Icon(
            Icons.search_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onSubmitted: (String value) {
                _navigate(value);
                setState(() => _section = 0);
              },
              decoration: const InputDecoration(
                hintText: 'Search the web...',
                border: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              _navigate('https://www.google.com');
              setState(() => _section = 0);
            },
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinks() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _quickLinks.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 10,
        childAspectRatio: .82,
      ),
      itemBuilder: (BuildContext context, int index) {
        final QuickLink link = _quickLinks[index];

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openQuickLink(link),
          child: Column(
            children: <Widget>[
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: link.color.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: link.color.withValues(alpha: .18)),
                ),
                child: Center(
                  child: Icon(link.icon, size: 28, color: link.color),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                link.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscoverCard() {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _summarizeCurrentPage,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: <Color>[AppTheme.primary, AppTheme.cyan],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Discover with AI Mode',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Research, summarize and save ideas into your notebook.',
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final List<_FeatureData> features = <_FeatureData>[
      _FeatureData(Icons.speed_rounded, 'Fast engine', 'System WebView'),
      _FeatureData(Icons.shield_outlined, 'Privacy', 'Incognito + controls'),
      _FeatureData(Icons.layers_outlined, 'Tabs', 'Multi-tab workspace'),
      _FeatureData(Icons.auto_awesome, 'AI Mode', 'Research workspace'),
      _FeatureData(Icons.menu_book_rounded, 'Notebook', 'Ideas + notes'),
      _FeatureData(Icons.palette_outlined, 'Themes', 'Dark / Light / System'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (BuildContext context, int index) {
        final _FeatureData feature = features[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  feature.icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const Spacer(),
                Text(
                  feature.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(feature.subtitle, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedPage() {
    return DefaultTabController(
      length: 3,
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              title: const Text(
                'Your Library',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              bottom: const TabBar(
                tabs: <Widget>[
                  Tab(text: 'Bookmarks'),
                  Tab(text: 'History'),
                  Tab(text: 'Downloads'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          children: <Widget>[
            _buildBookmarkList(),
            _buildHistoryList(),
            _buildDownloadList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkList() {
    if (_bookmarks.isEmpty) {
      return _emptyState(
        icon: Icons.bookmark_border_rounded,
        title: 'No bookmarks',
        subtitle: 'Use the bookmark button in the address bar.',
        actionText: 'Open browser',
        action: () => setState(() => _section = 0),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookmarks.length,
      itemBuilder: (BuildContext context, int index) {
        final BookmarkItem item = _bookmarks[index];

        return Card(
          child: ListTile(
            leading: const Icon(Icons.bookmark_rounded),
            title: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              item.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _openBookmark(item),
            trailing: IconButton(
              tooltip: 'Remove',
              onPressed: () {
                setState(() => _bookmarks.remove(item));
              },
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return _emptyState(
        icon: Icons.history_rounded,
        title: 'No history',
        subtitle: 'Pages you visit will appear here.',
        actionText: 'Start browsing',
        action: () => setState(() => _section = 0),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (BuildContext context, int index) {
        final HistoryItem item = _history[index];

        return Card(
          child: ListTile(
            leading: const Icon(Icons.public_rounded),
            title: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              item.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _openHistoryItem(item),
          ),
        );
      },
    );
  }

  Widget _buildDownloadList() {
    if (_downloads.isEmpty) {
      return _emptyState(
        icon: Icons.download_outlined,
        title: 'No downloads',
        subtitle: 'Download actions will appear here.',
        actionText: 'Open browser',
        action: () => setState(() => _section = 0),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _downloads.length,
      itemBuilder: (BuildContext context, int index) {
        final DownloadItem item = _downloads[index];

        return Card(
          child: ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(item.name),
            subtitle: Text(
              item.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
      children: <Widget>[
        _pageHeader(
          'AI Mode',
          'Search, reason and organize research',
          Icons.auto_awesome_rounded,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Research assistant',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _chooseAiProvider,
                      child: Text(_aiProvider),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _aiController,
                  minLines: 3,
                  maxLines: 7,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText:
                        'Ask anything, summarize a topic, compare ideas...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _runAiMode,
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Ask AI'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Save answer to notebook',
                      onPressed: _saveAiAnswer,
                      icon: const Icon(Icons.bookmark_add_outlined),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _aiAnswer.isEmpty ? _buildAiSuggestions() : _buildAiAnswerCard(),
        const SizedBox(height: 14),
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.language_rounded),
                title: const Text('Current page context'),
                subtitle: Text(
                  _currentTab.currentUrl.isEmpty
                      ? 'No page loaded'
                      : _currentTab.currentUrl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.summarize_rounded),
                title: const Text('Summarize current page'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _summarizeCurrentPage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiSuggestions() {
    final List<String> suggestions = <String>[
      'Explain this topic in simple words',
      'Give me a short comparison',
      'Create a study plan',
      'Extract the key points',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Try asking',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            for (final String suggestion in suggestions)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.arrow_outward_rounded),
                title: Text(suggestion),
                onTap: () {
                  _aiController.text = suggestion;
                  _runAiMode();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAnswerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(_aiAnswer, style: const TextStyle(height: 1.5)),
      ),
    );
  }

  void _saveAiAnswer() {
    if (_aiAnswer.trim().isEmpty) {
      _showSnack('There is no AI answer to save');
      return;
    }

    setState(() {
      _notes.insert(
        0,
        NoteItem(
          title: 'AI Research',
          body: _aiAnswer,
          created: DateTime.now(),
        ),
      );
    });

    _showSnack('AI answer saved to Notebook');
  }

  Widget _buildNotebookPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _pageHeader(
                'Notebook',
                '${_notes.length} saved idea${_notes.length == 1 ? '' : 's'}',
                Icons.menu_book_rounded,
              ),
            ),
            FilledButton.icon(
              onPressed: _showNewNoteDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_notes.isEmpty)
          _emptyState(
            icon: Icons.menu_book_outlined,
            title: 'Your notebook is empty',
            subtitle:
                'Save AI research or create a note for ideas, study and projects.',
            actionText: 'Create note',
            action: _showNewNoteDialog,
          )
        else
          ..._notes.map(
            (NoteItem note) => Card(
              child: ExpansionTile(
                leading: const Icon(Icons.note_alt_outlined),
                title: Text(
                  note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(_formatDate(note.created)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(note.body),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _deleteNote(note),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSettingsPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
      children: <Widget>[
        _pageHeader(
          'Settings',
          'Make Optimistic Browser yours',
          Icons.settings_rounded,
        ),
        const SizedBox(height: 16),
        _settingsCard('Appearance', <Widget>[
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(widget.themeMode)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _chooseTheme,
          ),
        ]),
        _settingsCard('Search', <Widget>[
          ListTile(
            leading: const Icon(Icons.search_rounded),
            title: const Text('Search engine'),
            subtitle: Text(_searchEngine),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _chooseSearchEngine,
          ),
        ]),
        _settingsCard('Privacy', <Widget>[
          SwitchListTile(
            value: _incognito,
            onChanged: (bool value) {
              setState(() => _incognito = value);
            },
            title: const Text('Incognito mode'),
            subtitle: const Text(
              'Do not add new pages to the normal history list',
            ),
            secondary: const Icon(Icons.visibility_off_outlined),
          ),
          SwitchListTile(
            value: _safeSearch,
            onChanged: (bool value) {
              setState(() => _safeSearch = value);
            },
            title: const Text('Safe search preference'),
            secondary: const Icon(Icons.verified_user_outlined),
          ),
          SwitchListTile(
            value: _adBlock,
            onChanged: (bool value) {
              setState(() => _adBlock = value);
              _showSnack(
                value
                    ? 'Ad-block preference enabled'
                    : 'Ad-block preference disabled',
              );
            },
            title: const Text('Ad-block preference'),
            subtitle: const Text(
              'UI preference; full filtering needs a network filter layer',
            ),
            secondary: const Icon(Icons.block_outlined),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Clear browsing history'),
            onTap: _clearHistory,
          ),
        ]),
        _settingsCard('Web', <Widget>[
          SwitchListTile(
            value: _javaScript,
            onChanged: _toggleJavaScript,
            title: const Text('JavaScript'),
            subtitle: const Text('Required by many modern websites'),
            secondary: const Icon(Icons.code_rounded),
          ),
          SwitchListTile(
            value: _desktopSite,
            onChanged: _toggleDesktopSite,
            title: const Text('Desktop site preference'),
            secondary: const Icon(Icons.desktop_windows_outlined),
          ),
          SwitchListTile(
            value: _readerMode,
            onChanged: _toggleReaderMode,
            title: const Text('Reader mode'),
            subtitle: const Text('Apply a cleaner reading layout'),
            secondary: const Icon(Icons.chrome_reader_mode_outlined),
          ),
          ListTile(
            leading: const Icon(Icons.find_in_page_outlined),
            title: const Text('Find in page'),
            onTap: _showFindDialog,
          ),
        ]),
        _settingsCard('Browser', <Widget>[
          SwitchListTile(
            value: _showHomeHeader,
            onChanged: (bool value) {
              setState(() => _showHomeHeader = value);
            },
            title: const Text('Show premium home header'),
            secondary: const Icon(Icons.auto_awesome_outlined),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Version'),
            subtitle: const Text('1.0.0 • Optimistic Browser'),
          ),
        ]),
        _settingsCard('About', <Widget>[
          const ListTile(
            leading: CosmicLogo(size: 44),
            title: Text(
              'Optimistic Browser',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text('Fast • Private • Intelligent'),
          ),
          const ListTile(
            leading: Icon(Icons.bolt_rounded),
            title: Text('Engine'),
            subtitle: Text('Flutter + system WebView'),
          ),
        ]),
      ],
    );
  }

  Widget _settingsCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return NavigationBar(
      selectedIndex: _section,
      onDestinationSelected: (int index) {
        setState(() => _section = index);
      },
      destinations: const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.public_outlined),
          selectedIcon: Icon(Icons.public_rounded),
          label: 'Browser',
        ),
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.bookmark_border_rounded),
          selectedIcon: Icon(Icons.bookmark_rounded),
          label: 'Library',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome_rounded),
          label: 'AI',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_rounded),
          label: 'Notebook',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
    );
  }

  void _showTabsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .76,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Tabs',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _createTab(loadHome: true);
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('New tab'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tabs.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.15,
                        ),
                    itemBuilder: (BuildContext context, int index) {
                      final BrowserTab tab = _tabs[index];
                      final bool active = index == _selectedTab;

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            _selectTab(index);
                            Navigator.pop(sheetContext);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Icon(
                                      tab.incognito
                                          ? Icons.visibility_off_rounded
                                          : Icons.public_rounded,
                                      size: 18,
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        Navigator.pop(sheetContext);
                                        _closeTab(index);
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  tab.title.isEmpty ? 'New Tab' : tab.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tab.currentUrl.isEmpty
                                      ? 'New tab'
                                      : tab.currentUrl,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                if (active)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 7),
                                    child: Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMainMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 18),
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  'Optimistic Browser',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
              _menuTile(
                Icons.home_outlined,
                'Home',
                () => setState(() => _section = 1),
              ),
              _menuTile(Icons.tab_outlined, 'Tabs', _showTabsSheet),
              _menuTile(
                Icons.bookmark_outline,
                'Library',
                () => setState(() => _section = 2),
              ),
              _menuTile(
                Icons.auto_awesome_outlined,
                'AI Mode',
                () => setState(() => _section = 3),
              ),
              _menuTile(
                Icons.menu_book_outlined,
                'Notebook',
                () => setState(() => _section = 4),
              ),
              _menuTile(
                Icons.settings_outlined,
                'Settings',
                () => setState(() => _section = 5),
              ),
              _menuTile(Icons.info_outline_rounded, 'About', _showAbout),
            ],
          ),
        );
      },
    );
  }

  Widget _menuTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _showFindDialog() {
    final TextEditingController controller = TextEditingController(
      text: _findQuery,
    );

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Find in page'),
          content: TextField(
            controller: controller,
            autofocus: true,
            onSubmitted: (_) {
              _findQuery = controller.text;
              Navigator.pop(dialogContext);
              _findInPage();
            },
            decoration: const InputDecoration(hintText: 'Text to find'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                _findQuery = controller.text;
                Navigator.pop(dialogContext);
                _findInPage();
              },
              child: const Text('Find'),
            ),
          ],
        );
      },
    );
  }

  void _chooseTheme() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const ListTile(
                title: Text(
                  'Theme',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
              RadioGroup<ThemeMode>(
                groupValue: widget.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value == null) return;
                  widget.onThemeChanged(value);
                  Navigator.pop(sheetContext);
                },
                child: Column(
                  children: <Widget>[
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      title: const Text('Dark'),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      title: const Text('Light'),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.system,
                      title: const Text('System'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _shareCurrentPage() {
    _showSnack(
      'Share UI is ready. Add a native share plugin when you want OS sharing.',
    );
  }

  void _showAbout() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: const <Widget>[
              CosmicLogo(size: 44),
              SizedBox(width: 12),
              Expanded(child: Text('Optimistic Browser')),
            ],
          ),
          content: const Text(
            'A premium Flutter browser interface with tabs, bookmarks, '
            'history, downloads UI, incognito mode, AI workspace, '
            'notebook, reader mode and theme controls.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
    );
  }

  Widget _pageHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: .55),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .10),
              ),
              child: Icon(
                icon,
                size: 44,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: action,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime time) {
    final String day = time.day.toString().padLeft(2, '0');
    final String month = time.month.toString().padLeft(2, '0');
    return '$day/$month/${time.year}';
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FeatureData {
  const _FeatureData(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}

class CosmicLogo extends StatelessWidget {
  const CosmicLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _CosmicLogoPainter());
  }
}

class _CosmicLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.shortestSide;
    final Offset center = Offset(s / 2, s / 2);
    final Rect box = Rect.fromLTWH(0, 0, s, s);

    final Paint background = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[Color(0xFF111536), Color(0xFF080A19)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(box);

    canvas.drawRRect(
      RRect.fromRectAndRadius(box, Radius.circular(s * .28)),
      background,
    );

    final Paint glow = Paint()
      ..shader = const RadialGradient(
        colors: <Color>[Color(0x5525D9FF), Color(0x001B1F4A)],
      ).createShader(Rect.fromCircle(center: center, radius: s * .48));

    canvas.drawCircle(center, s * .48, glow);

    final Paint planet = Paint()
      ..shader = const RadialGradient(
        colors: <Color>[
          Color(0xFF5FDCFF),
          Color(0xFF4730B5),
          Color(0xFF0A102B),
        ],
        stops: <double>[0, .45, 1],
      ).createShader(Rect.fromCircle(center: center, radius: s * .25));

    canvas.drawCircle(center, s * .25, planet);

    final Paint starPaint = Paint()..color = Colors.white;
    final List<Offset> stars = <Offset>[
      Offset(s * .18, s * .22),
      Offset(s * .74, s * .18),
      Offset(s * .79, s * .70),
      Offset(s * .27, s * .77),
      Offset(s * .61, s * .30),
    ];

    for (int i = 0; i < stars.length; i++) {
      final double radius = i == 4 ? s * .025 : s * .015;
      canvas.drawCircle(stars[i], radius, starPaint);
    }

    final Paint orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .075
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFF8D5CFF),
          Color(0xFF25D9FF),
          Color(0xFFFFB15C),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(box);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-.27);
    canvas.translate(-center.dx, -center.dy);

    canvas.drawOval(
      Rect.fromCenter(center: center, width: s * .92, height: s * .38),
      orbit,
    );

    canvas.restore();

    final Paint arrow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .065
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white;

    final Path arrowPath = Path()
      ..moveTo(s * .55, s * .55)
      ..lineTo(s * .76, s * .34)
      ..moveTo(s * .76, s * .34)
      ..lineTo(s * .68, s * .35)
      ..moveTo(s * .76, s * .34)
      ..lineTo(s * .74, s * .43);

    canvas.drawPath(arrowPath, arrow);

    final Paint rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .012
      ..color = Colors.white.withValues(alpha: .22);

    canvas.drawRRect(
      RRect.fromRectAndRadius(box.deflate(s * .008), Radius.circular(s * .28)),
      rim,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// OPTIMISTIC AI — EXPANDED WORKSPACE
// ============================================================================
// This section intentionally uses Flutter SDK APIs only. It does not pretend
// to contain private Google Cloud APIs or credentials. Cloud providers can be
// connected later through secure backend adapters.
// ============================================================================

class OptimisticAIMessage {
  const OptimisticAIMessage({
    required this.text,
    required this.fromUser,
    required this.createdAt,
  });

  final String text;
  final bool fromUser;
  final DateTime createdAt;
}

class OptimisticAINote {
  OptimisticAINote({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  final String id;
  String title;
  String body;
  DateTime updatedAt;
}

class OptimisticAITask {
  OptimisticAITask({
    required this.id,
    required this.title,
    this.completed = false,
    this.priority = 0,
  });

  final String id;
  String title;
  bool completed;
  int priority;
}

class OptimisticAIPlan {
  OptimisticAIPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  final String id;
  String title;
  String description;
  DateTime createdAt;
}

class OptimisticAINewsItem {
  const OptimisticAINewsItem({
    required this.title,
    required this.category,
    required this.summary,
  });

  final String title;
  final String category;
  final String summary;
}

class OptimisticAIWorkspace extends StatefulWidget {
  const OptimisticAIWorkspace({super.key});

  @override
  State<OptimisticAIWorkspace> createState() => _OptimisticAIWorkspaceState();
}

class _OptimisticAIWorkspaceState extends State<OptimisticAIWorkspace> {
  final TextEditingController _prompt = TextEditingController();
  final TextEditingController _noteTitle = TextEditingController();
  final TextEditingController _noteBody = TextEditingController();

  final List<OptimisticAIMessage> _messages = [];
  final List<OptimisticAINote> _notes = [];
  final List<OptimisticAITask> _tasks = [];
  final List<OptimisticAIPlan> _plans = [];

  int _section = 0;
  final bool _compactMode = false;
  bool _focusMode = false;
  final bool _smartSuggestions = true;
  String _model = 'Optimistic Core';

  @override
  void initState() {
    super.initState();

    _notes.add(
      OptimisticAINote(
        id: 'welcome-note',
        title: 'Optimistic AI Notebook',
        body:
            'Capture ideas, research, plans, prompts, and decisions in one place.',
        updatedAt: DateTime.now(),
      ),
    );

    _tasks.add(
      OptimisticAITask(
        id: 'first-task',
        title: 'Create your first Optimistic AI plan',
        priority: 1,
      ),
    );
  }

  @override
  void dispose() {
    _prompt.dispose();
    _noteTitle.dispose();
    _noteBody.dispose();
    super.dispose();
  }

  void _askAI() {
    final text = _prompt.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        OptimisticAIMessage(
          text: text,
          fromUser: true,
          createdAt: DateTime.now(),
        ),
      );
      _messages.add(
        OptimisticAIMessage(
          text:
              'Optimistic AI is ready to organize this into research, notes, tasks, or a plan. Connect your preferred secure AI backend for live model responses.',
          fromUser: false,
          createdAt: DateTime.now(),
        ),
      );
      _prompt.clear();
    });
  }

  void _addTask() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New task'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Task name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  setState(() {
                    _tasks.add(
                      OptimisticAITask(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        title: value,
                      ),
                    );
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addPlan() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New plan'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Plan title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  setState(() {
                    _plans.add(
                      OptimisticAIPlan(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        title: value,
                        description: 'Plan generated in Optimistic AI.',
                        createdAt: DateTime.now(),
                      ),
                    );
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _addNote() {
    final title = _noteTitle.text.trim();
    final body = _noteBody.text.trim();
    if (title.isEmpty && body.isEmpty) return;

    setState(() {
      _notes.insert(
        0,
        OptimisticAINote(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: title.isEmpty ? 'Untitled note' : title,
          body: body,
          updatedAt: DateTime.now(),
        ),
      );
      _noteTitle.clear();
      _noteBody.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Optimistic AI',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Focus mode',
            onPressed: () => setState(() => _focusMode = !_focusMode),
            icon: Icon(
              _focusMode ? Icons.center_focus_strong : Icons.center_focus_weak,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _model = value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'Optimistic Core',
                child: Text('Optimistic Core'),
              ),
              PopupMenuItem(
                value: 'Optimistic Reason',
                child: Text('Optimistic Reason'),
              ),
              PopupMenuItem(
                value: 'Optimistic Fast',
                child: Text('Optimistic Fast'),
              ),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          if (!_focusMode)
            NavigationRail(
              selectedIndex: _section,
              onDestinationSelected: (value) {
                setState(() => _section = value);
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome),
                  label: Text('AI'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: Text('Notebook'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.task_alt_outlined),
                  selectedIcon: Icon(Icons.task_alt),
                  label: Text('Tasks'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.route_outlined),
                  selectedIcon: Icon(Icons.route),
                  label: Text('Planning'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.newspaper_outlined),
                  selectedIcon: Icon(Icons.newspaper),
                  label: Text('News'),
                ),
              ],
            ),
          Expanded(child: _buildSection()),
        ],
      ),
    );
  }

  Widget _buildSection() {
    switch (_section) {
      case 1:
        return _buildNotebook();
      case 2:
        return _buildTasks();
      case 3:
        return _buildPlans();
      case 4:
        return _buildNews();
      default:
        return _buildAI();
    }
  }

  Widget _buildAI() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _hero(
          'Think with Optimistic AI',
          'Search, summarize, plan, write, and organize from one clean workspace.',
          Icons.auto_awesome,
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(
          initialValue: _model,
          decoration: const InputDecoration(
            labelText: 'AI engine',
            prefixIcon: Icon(Icons.memory_outlined),
          ),
          items: const [
            DropdownMenuItem(
              value: 'Optimistic Core',
              child: Text('Optimistic Core'),
            ),
            DropdownMenuItem(
              value: 'Optimistic Reason',
              child: Text('Optimistic Reason'),
            ),
            DropdownMenuItem(
              value: 'Optimistic Fast',
              child: Text('Optimistic Fast'),
            ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _model = value);
          },
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Column(
            children: [
              ..._messages.map(
                (message) => Align(
                  alignment: message.fromUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 720),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: message.fromUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surface,
                    ),
                    child: Text(message.text),
                  ),
                ),
              ),
              if (_messages.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Text(
                    'Ask Optimistic AI to explain a topic, draft text, build a plan, or organize your research.',
                    textAlign: TextAlign.center,
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _prompt,
                      minLines: 1,
                      maxLines: 5,
                      onSubmitted: (_) => _askAI(),
                      decoration: const InputDecoration(
                        hintText: 'Ask Optimistic AI...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send',
                    onPressed: _askAI,
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_smartSuggestions)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _suggestion('Summarize this'),
              _suggestion('Create a study plan'),
              _suggestion('Explain step by step'),
              _suggestion('Turn this into tasks'),
              _suggestion('Generate ideas'),
            ],
          ),
      ],
    );
  }

  Widget _suggestion(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _prompt.text = text;
        _askAI();
      },
    );
  }

  Widget _buildNotebook() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _hero(
          'Notebook',
          'A focused place for notes, research, prompts, and ideas.',
          Icons.menu_book,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _noteTitle,
          decoration: const InputDecoration(
            labelText: 'Note title',
            prefixIcon: Icon(Icons.title),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _noteBody,
          minLines: 4,
          maxLines: 10,
          decoration: const InputDecoration(
            labelText: 'Write your note',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.edit_note),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _addNote,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save note'),
          ),
        ),
        const SizedBox(height: 18),
        ..._notes.map(
          (note) => Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(note.title),
              subtitle: Text(
                note.body,
                maxLines: _compactMode ? 1 : 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                tooltip: 'Delete',
                onPressed: () {
                  setState(() => _notes.remove(note));
                },
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTasks() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _hero(
          'Tasks',
          'Turn ideas into small, trackable actions.',
          Icons.task_alt,
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _addTask,
          icon: const Icon(Icons.add),
          label: const Text('Add task'),
        ),
        const SizedBox(height: 14),
        ..._tasks.map(
          (task) => Card(
            child: CheckboxListTile(
              value: task.completed,
              onChanged: (value) {
                setState(() => task.completed = value ?? false);
              },
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: task.completed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: Text(
                task.priority > 0 ? 'Priority ${task.priority}' : 'Normal',
              ),
              secondary: const Icon(Icons.drag_indicator),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlans() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _hero(
          'Planning',
          'Build structured plans for projects, study, travel, or work.',
          Icons.route,
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _addPlan,
          icon: const Icon(Icons.add_road),
          label: const Text('Create plan'),
        ),
        const SizedBox(height: 14),
        ..._plans.map(
          (plan) => Card(
            child: ExpansionTile(
              leading: const Icon(Icons.route_outlined),
              title: Text(plan.title),
              subtitle: Text(plan.description),
              children: const [
                ListTile(
                  leading: Icon(Icons.check_circle_outline),
                  title: Text('Define the goal'),
                ),
                ListTile(
                  leading: Icon(Icons.check_circle_outline),
                  title: Text('Break the goal into milestones'),
                ),
                ListTile(
                  leading: Icon(Icons.check_circle_outline),
                  title: Text('Review progress'),
                ),
              ],
            ),
          ),
        ),
        if (_plans.isEmpty)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Text(
              'Create a plan and Optimistic AI can later be connected to a real model service to generate milestones.',
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildNews() {
    const items = [
      OptimisticAINewsItem(
        title: 'AI and developer tools',
        category: 'Technology',
        summary: 'A daily feed concept for technology and AI research.',
      ),
      OptimisticAINewsItem(
        title: 'Flutter ecosystem',
        category: 'Development',
        summary: 'Track framework, package, and developer-tool updates.',
      ),
      OptimisticAINewsItem(
        title: 'Cloud computing',
        category: 'Cloud',
        summary: 'Organize cloud platform updates and architecture notes.',
      ),
      OptimisticAINewsItem(
        title: 'Productivity ideas',
        category: 'Productivity',
        summary: 'Turn useful stories into notes, tasks, and plans.',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _hero(
          'Daily Flow',
          'A clean news-and-research dashboard. Live feeds require a news API.',
          Icons.newspaper,
        ),
        const SizedBox(height: 14),
        ...items.map(
          (item) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.article_outlined)),
              title: Text(item.title),
              subtitle: Text('${item.category}\n${item.summary}'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ],
    );
  }

  Widget _hero(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ],
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 42),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
