import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/ai/ai_page.dart';
import 'features/browser/browser_controller.dart';
import 'features/browser/browser_page.dart';
import 'features/home/home_page.dart';
import 'features/library/library_page.dart';
import 'features/notebook/notebook_page.dart';
import 'features/settings/settings_page.dart';

class OptimisticAiApp extends StatefulWidget {
  const OptimisticAiApp({super.key});

  @override
  State<OptimisticAiApp> createState() => _OptimisticAiAppState();
}

class _OptimisticAiAppState extends State<OptimisticAiApp> with WidgetsBindingObserver {
  final OptimisticBrowserController _browser =
      OptimisticBrowserController();

  int _index = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeBrowser();
  }

  Future<void> _initializeBrowser() async {
    try {
      await _browser.initialize();
      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('Browser initialization failed: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _browser.persistSession();
    }
  }

  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _browser.persistSession();
    _browser.dispose();
    super.dispose();
  }

  void _openBrowserInput(String value) {
    final input = value.trim();
    if (input.isEmpty) return;

    _browser.openInput(input);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrowserPage(controller: _browser),
      ),
    );
  }

  void _openAi() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiPage(
          pageUrl: _browser.currentUrl,
          pageTitle: _browser.title,
          browser: _browser,
        ),
      ),
    );
  }

  void _openLibrary() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LibraryPage(
          onOpenUrl: _openBrowserInput,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Optimistic Browser',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            HomePage(
              onOpenInput: _openBrowserInput,
              onOpenAi: _openAi,
              onOpenLibrary: _openLibrary,
            ),
            const NotebookPage(),
            AiPage(
              pageUrl: _browser.currentUrl,
              pageTitle: _browser.title,
              browser: _browser,
            ),
            LibraryPage(
              onOpenUrl: _openBrowserInput,
            ),
            SettingsPage(
              themeMode: _themeMode,
              onThemeChanged: (mode) {
                setState(() => _themeMode = mode);
              },
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) {
            setState(() => _index = value);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Notebook',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'AI',
            ),
            NavigationDestination(
              icon: Icon(Icons.library_books_outlined),
              selectedIcon: Icon(Icons.library_books),
              label: 'Library',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
