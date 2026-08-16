
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/search/search_service.dart';
import 'browser_controller.dart';
import 'models/browser_tab.dart';

class BrowserPage extends StatefulWidget {
  const BrowserPage({super.key, required this.controller});
  final OptimisticBrowserController controller;

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  bool _desktopSite = false;
  bool _readerMode = false;
  bool _javaScript = true;
  final _find = TextEditingController();
  final _address = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncAddress);
    _syncAddress();
  }

  void _syncAddress() {
    final value = widget.controller.currentUrl;
    if (_address.text != value && value.isNotEmpty) {
      _address.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncAddress);
    _find.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _goAddress() async {
    final value = _address.text.trim();
    if (value.isEmpty) return;
    await widget.controller.openInput(value);
  }

  Future<void> _toggleReader() async {
    _readerMode = !_readerMode;
    if (_readerMode) {
      await widget.controller.webView.runJavaScript(
        "document.body.style.maxWidth='900px';document.body.style.margin='auto';document.body.style.fontSize='20px';document.body.style.lineHeight='1.7';",
      );
    } else {
      await widget.controller.reload();
    }
    if (mounted) setState(() {});
  }

  Future<void> _findInPage() async {
    final q = _find.text.trim();
    if (q.isEmpty) return;
    await widget.controller.webView.runJavaScript(
      "window.find(${_js(q)});",
    );
  }

  String _js(String value) =>
      "'${value.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll('\n', r'\n')}'";

  Future<void> _showTabs() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tabs',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'New tab',
                  onPressed: () async {
                    Navigator.pop(context);
                    await widget.controller.newTab();
                  },
                  icon: const Icon(Icons.add),
                ),
                IconButton(
                  tooltip: 'Private tab',
                  onPressed: () async {
                    Navigator.pop(context);
                    await widget.controller.newTab(private: true);
                  },
                  icon: const Icon(Icons.visibility_off_outlined),
                ),
                IconButton(
                  tooltip: 'Reopen closed',
                  onPressed: () async {
                    Navigator.pop(context);
                    await widget.controller.reopenLastClosed();
                  },
                  icon: const Icon(Icons.restore),
                ),
              ],
            ),
            ...widget.controller.tabs.tabs.map(
              (tab) => ListTile(
                selected: widget.controller.tabs.active?.id == tab.id,
                leading: Icon(
                  tab.mode == BrowserTabMode.private
                      ? Icons.visibility_off
                      : Icons.public,
                ),
                title: Text(
                  tab.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    if (tab.groupId != null) tab.groupId!,
                    tab.url.isEmpty ? 'New tab' : tab.url,
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await widget.controller.selectTab(tab.id);
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopupMenuButton<String?>(
                      tooltip: 'Tab group',
                      onSelected: (group) {
                        widget.controller.tabs.assignGroup(tab.id, group);
                        if (mounted) setState(() {});
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: null, child: Text('No group')),
                        PopupMenuItem(value: 'group-1', child: Text('Group 1')),
                        PopupMenuItem(value: 'group-2', child: Text('Group 2')),
                        PopupMenuItem(value: 'group-3', child: Text('Group 3')),
                      ],
                      icon: const Icon(Icons.folder_outlined),
                    ),
                    IconButton(
                      onPressed: () async {
                        await widget.controller.closeTab(tab.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: TextField(
          controller: _address,
          onSubmitted: (_) => _goAddress(),
          decoration: InputDecoration(
            hintText: 'Search or enter URL',
            prefixIcon: Icon(
              widget.controller.incognito
                  ? Icons.visibility_off
                  : Icons.lock_outline,
            ),
            suffixIcon: IconButton(
              onPressed: _goAddress,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Tabs',
            onPressed: _showTabs,
            icon: Badge(
              label: Text('${widget.controller.tabs.tabs.length}'),
              child: const Icon(Icons.tab),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'private':
                  await widget.controller.newTab(private: true);
                  break;
                case 'desktop':
                  setState(() => _desktopSite = !_desktopSite);
                  await widget.controller.webView.setUserAgent(
                    _desktopSite
                        ? 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/140 Safari/537.36'
                        : null,
                  );
                  await widget.controller.reload();
                  break;
                case 'reader':
                  await _toggleReader();
                  break;
                case 'javascript':
                  setState(() => _javaScript = !_javaScript);
                  await widget.controller.webView.setJavaScriptMode(
                    _javaScript
                        ? JavaScriptMode.unrestricted
                        : JavaScriptMode.disabled,
                  );
                  break;
                case 'private-data':
                  await widget.controller.clearPrivateData();
                  break;
                case 'find':
                  if (!mounted) return;
                  await showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Find in page'),
                      content: TextField(
                        controller: _find,
                        autofocus: true,
                        onSubmitted: (_) {
                          Navigator.pop(context);
                          _findInPage();
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _findInPage();
                          },
                          child: const Text('Find'),
                        ),
                      ],
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'private',
                child: Text('New private tab'),
              ),
              CheckedPopupMenuItem(
                value: 'desktop',
                checked: _desktopSite,
                child: const Text('Desktop site'),
              ),
              CheckedPopupMenuItem(
                value: 'reader',
                checked: _readerMode,
                child: const Text('Reader mode'),
              ),
              CheckedPopupMenuItem(
                value: 'javascript',
                checked: _javaScript,
                child: const Text('JavaScript'),
              ),
              const PopupMenuItem(
                value: 'private-data',
                child: Text('Private storage status'),
              ),
              const PopupMenuItem(
                value: 'find',
                child: Text('Find in page'),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Bookmark',
            onPressed: widget.controller.bookmarkCurrentPage,
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return Column(
            children: [
              _TabStrip(controller: widget.controller, onShowTabs: _showTabs),
              if (widget.controller.results.isNotEmpty)
                Expanded(
                  child: Column(
                    children: [
                      _SearchCategoryBar(controller: widget.controller),
                      Expanded(
                        child: _SearchResults(
                          results: widget.controller.results,
                          onOpen: widget.controller.openResult,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: Stack(
                    children: [
                      WebViewWidget(controller: widget.controller.webView),
                      if (widget.controller.loading)
                        const Align(
                          alignment: Alignment.topCenter,
                          child: LinearProgressIndicator(),
                        ),
                      if (widget.controller.lastError != null)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Material(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                widget.controller.lastError!.message,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: widget.controller.goBack,
              icon: const Icon(Icons.arrow_back),
            ),
            IconButton(
              onPressed: widget.controller.goForward,
              icon: const Icon(Icons.arrow_forward),
            ),
            IconButton(
              onPressed: widget.controller.reload,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              onPressed: _showTabs,
              icon: const Icon(Icons.tab),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.home_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results, required this.onOpen});
  final List<SearchResult> results;
  final Future<void> Function(String) onOpen;

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.public_rounded),
              title: Text(result.title),
              subtitle: Text(
                result.url.isEmpty
                    ? result.description
                    : '${result.url}\n\n${result.description}',
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: result.url.isEmpty ? null : () => onOpen(result.url),
            ),
          );
        },
      );
}


class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.controller, required this.onShowTabs});
  final OptimisticBrowserController controller;
  final VoidCallback onShowTabs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              itemCount: controller.tabs.tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final tab = controller.tabs.tabs[index];
                final selected = controller.tabs.active?.id == tab.id;
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => controller.selectTab(tab.id),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 190),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: selected
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.mode == BrowserTabMode.private
                              ? Icons.visibility_off
                              : Icons.public,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            tab.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => controller.closeTab(tab.id),
                          child: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            tooltip: 'New tab',
            onPressed: () => controller.newTab(),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Tab overview',
            onPressed: onShowTabs,
            icon: const Icon(Icons.grid_view_rounded),
          ),
        ],
      ),
    );
  }
}

class _SearchCategoryBar extends StatelessWidget {
  const _SearchCategoryBar({required this.controller});
  final OptimisticBrowserController controller;

  @override
  Widget build(BuildContext context) {
    const categories = <String>['web', 'images', 'videos', 'news', 'shopping'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: categories.map((category) {
          final selected = controller.searchCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(category[0].toUpperCase() + category.substring(1)),
              selected: selected,
              onSelected: (_) => controller.searchCategory,
            ),
          );
        }).toList(),
      ),
    );
  }
}
