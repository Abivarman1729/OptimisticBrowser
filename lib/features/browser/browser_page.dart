import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/search/search_service.dart';
import 'browser_controller.dart';
import 'models/browser_tab.dart';

class BrowserPage extends StatefulWidget {
  const BrowserPage({
    super.key,
    required this.controller,
  });

  final OptimisticBrowserController
      controller;

  @override
  State<BrowserPage> createState() =>
      _BrowserPageState();
}

class _BrowserPageState
    extends State<BrowserPage> {
  bool _desktopSite = false;
  bool _readerMode = false;
  bool _javaScript = true;

  final TextEditingController
      _find =
      TextEditingController();

  final TextEditingController
      _address =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    widget.controller
        .addListener(
      _syncAddress,
    );

    _syncAddress();
  }

  void _syncAddress() {
    final String value =
        widget.controller
            .currentUrl;

    if (value.isEmpty ||
        _address.text ==
            value) {
      return;
    }

    _address.value =
        TextEditingValue(
      text: value,
      selection:
          TextSelection.collapsed(
        offset: value.length,
      ),
    );
  }

  @override
  void dispose() {
    widget.controller
        .removeListener(
      _syncAddress,
    );

    _find.dispose();
    _address.dispose();

    super.dispose();
  }

  Future<void>
      _submitInput() async {
    final String value =
        _address.text.trim();

    if (value.isEmpty) {
      return;
    }

    FocusScope.of(context)
        .unfocus();

    await widget.controller
        .openInput(value);
  }

  Future<void>
      _toggleReader() async {
    _readerMode =
        !_readerMode;

    try {
      if (_readerMode) {
        await widget.controller
            .webView
            .runJavaScript(
          "document.body.style.maxWidth='900px';"
          "document.body.style.margin='auto';"
          "document.body.style.fontSize='20px';"
          "document.body.style.lineHeight='1.7';",
        );
      } else {
        await widget.controller
            .reload();
      }
    } catch (error) {
      debugPrint(
        'Reader mode failed: $error',
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void>
      _findInPage() async {
    final String query =
        _find.text.trim();

    if (query.isEmpty) {
      return;
    }

    try {
      await widget.controller
          .webView
          .runJavaScript(
        'window.find(${_js(query)});',
      );
    } catch (error) {
      debugPrint(
        'Find in page failed: $error',
      );
    }
  }

  String _js(String value) {
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll('\n', r'\n');

    return "'$escaped'";
  }

  Future<void>
      _showTabs() async {
    await showModalBottomSheet<
        void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding:
                const EdgeInsets.all(12),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tabs',
                      style:
                          TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip:
                        'New tab',
                    onPressed:
                        () async {
                      Navigator.pop(
                        context,
                      );

                      await widget
                          .controller
                          .newTab();
                    },
                    icon: const Icon(
                      Icons.add,
                    ),
                  ),
                  IconButton(
                    tooltip:
                        'Private tab',
                    onPressed:
                        () async {
                      Navigator.pop(
                        context,
                      );

                      await widget
                          .controller
                          .newTab(
                        private: true,
                      );
                    },
                    icon:
                        const Icon(
                      Icons
                          .visibility_off_outlined,
                    ),
                  ),
                  IconButton(
                    tooltip:
                        'Reopen closed',
                    onPressed:
                        () async {
                      Navigator.pop(
                        context,
                      );

                      await widget
                          .controller
                          .reopenLastClosed();
                    },
                    icon:
                        const Icon(
                      Icons.restore,
                    ),
                  ),
                ],
              ),
              ...widget
                  .controller
                  .tabs
                  .tabs
                  .map(
                (BrowserTab tab) =>
                    ListTile(
                  selected:
                      widget
                              .controller
                              .tabs
                              .active
                              ?.id ==
                          tab.id,
                  leading:
                      Icon(
                    tab.mode ==
                            BrowserTabMode
                                .private
                        ? Icons
                            .visibility_off
                        : Icons.public,
                  ),
                  title:
                      Text(
                    tab.title,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                  ),
                  subtitle:
                      Text(
                    [
                      if (tab.groupId !=
                          null)
                        tab.groupId!,
                      tab.url.isEmpty
                          ? 'New tab'
                          : tab.url,
                    ].join(' • '),
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                  ),
                  onTap:
                      () async {
                    Navigator.pop(
                      context,
                    );

                    await widget
                        .controller
                        .selectTab(
                      tab.id,
                    );
                  },
                  trailing:
                      Row(
                    mainAxisSize:
                        MainAxisSize
                            .min,
                    children: [
                      PopupMenuButton<
                          String?>(
                        tooltip:
                            'Tab group',
                        onSelected:
                            (group) {
                          widget
                              .controller
                              .tabs
                              .assignGroup(
                            tab.id,
                            group,
                          );

                          if (mounted) {
                            setState(
                              () {},
                            );
                          }
                        },
                        itemBuilder:
                            (_) =>
                                const [
                          PopupMenuItem(
                            value:
                                null,
                            child:
                                Text(
                              'No group',
                            ),
                          ),
                          PopupMenuItem(
                            value:
                                'group-1',
                            child:
                                Text(
                              'Group 1',
                            ),
                          ),
                          PopupMenuItem(
                            value:
                                'group-2',
                            child:
                                Text(
                              'Group 2',
                            ),
                          ),
                          PopupMenuItem(
                            value:
                                'group-3',
                            child:
                                Text(
                              'Group 3',
                            ),
                          ),
                        ],
                        icon:
                            const Icon(
                          Icons
                              .folder_outlined,
                        ),
                      ),
                      IconButton(
                        onPressed:
                            () async {
                          await widget
                              .controller
                              .closeTab(
                            tab.id,
                          );

                          if (context
                              .mounted) {
                            Navigator.pop(
                              context,
                            );
                          }
                        },
                        icon:
                            const Icon(
                          Icons.close,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void>
      _handleMenu(
    String value,
  ) async {
    switch (value) {
      case 'private':
        await widget.controller
            .newTab(
          private: true,
        );
        break;

      case 'desktop':
        setState(() {
          _desktopSite =
              !_desktopSite;
        });

        await widget.controller
            .webView
            .setUserAgent(
          _desktopSite
              ? 'Mozilla/5.0 (X11; Linux x86_64) '
                  'AppleWebKit/537.36 '
                  'Chrome/140 Safari/537.36'
              : null,
        );

        await widget.controller
            .reload();

        break;

      case 'reader':
        await _toggleReader();
        break;

      case 'javascript':
        setState(() {
          _javaScript =
              !_javaScript;
        });

        await widget.controller
            .webView
            .setJavaScriptMode(
          _javaScript
              ? JavaScriptMode
                  .unrestricted
              : JavaScriptMode
                  .disabled,
        );

        break;

      case 'private-data':
        await widget.controller
            .clearPrivateData();
        break;

      case 'find':
        if (!mounted) {
          return;
        }

        await _showFindDialog();
        break;
    }
  }

  Future<void>
      _showFindDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) =>
          AlertDialog(
        title: const Text(
          'Find in page',
        ),
        content: TextField(
          controller: _find,
          autofocus: true,
          textInputAction:
              TextInputAction.search,
          onSubmitted: (_) {
            Navigator.pop(
              context,
            );

            _findInPage();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
              );
            },
            child: const Text(
              'Close',
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
              );

              _findInPage();
            },
            child: const Text(
              'Find',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: TextField(
          controller: _address,
          keyboardType:
              TextInputType.url,
          textInputAction:
              TextInputAction.search,
          onSubmitted: (_) =>
              _submitInput(),
          decoration:
              InputDecoration(
            hintText:
                'Search or enter URL',
            prefixIcon: Icon(
              widget.controller
                      .incognito
                  ? Icons
                      .visibility_off
                  : Icons
                      .lock_outline,
            ),
            suffixIcon:
                IconButton(
              tooltip: 'Go',
              onPressed:
                  _submitInput,
              icon: const Icon(
                Icons
                    .arrow_forward_rounded,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Tabs',
            onPressed:
                _showTabs,
            icon: Badge(
              label: Text(
                '${widget.controller.tabs.tabs.length}',
              ),
              child: const Icon(
                Icons.tab,
              ),
            ),
          ),
          PopupMenuButton<
              String>(
            onSelected:
                _handleMenu,
            itemBuilder:
                (_) => [
              const PopupMenuItem(
                value:
                    'private',
                child: Text(
                  'New private tab',
                ),
              ),
              CheckedPopupMenuItem(
                value:
                    'desktop',
                checked:
                    _desktopSite,
                child: const Text(
                  'Desktop site',
                ),
              ),
              CheckedPopupMenuItem(
                value:
                    'reader',
                checked:
                    _readerMode,
                child: const Text(
                  'Reader mode',
                ),
              ),
              CheckedPopupMenuItem(
                value:
                    'javascript',
                checked:
                    _javaScript,
                child: const Text(
                  'JavaScript',
                ),
              ),
              const PopupMenuItem(
                value:
                    'private-data',
                child: Text(
                  'Private storage status',
                ),
              ),
              const PopupMenuItem(
                value:
                    'find',
                child: Text(
                  'Find in page',
                ),
              ),
            ],
          ),
          IconButton(
            tooltip:
                'Bookmark',
            onPressed:
                widget.controller
                    .bookmarkCurrentPage,
            icon: const Icon(
              Icons
                  .bookmark_add_outlined,
            ),
          ),
        ],
      ),
      body:
          ListenableBuilder(
        listenable:
            widget.controller,
        builder:
            (context, _) {
          final bool
              searchMode =
              widget.controller
                  .hasSearchQuery;

          final bool
              hasResults =
              widget.controller
                  .hasSearchResults;

          return Column(
            children: [
              _TabStrip(
                controller:
                    widget.controller,
                onShowTabs:
                    _showTabs,
              ),
              if (searchMode)
                _SearchHeader(
                  controller:
                      widget.controller,
                ),
              if (searchMode &&
                  widget.controller
                      .isSearchLoading)
                const LinearProgressIndicator(
                  minHeight: 2,
                ),
              if (searchMode &&
                  hasResults)
                Expanded(
                  child:
                      Column(
                    children: [
                      _SearchCategoryBar(
                        controller:
                            widget.controller,
                      ),
                      Expanded(
                        child:
                            _SearchResults(
                          results:
                              widget.controller
                                  .results,
                          onOpen:
                              widget.controller
                                  .openResult,
                        ),
                      ),
                    ],
                  ),
                )
              else if (searchMode &&
                  !widget.controller
                      .isSearchLoading)
                Expanded(
                  child:
                      _SearchEmptyState(
                    controller:
                        widget.controller,
                  ),
                )
              else
                Expanded(
                  child:
                      Stack(
                    children: [
                      WebViewWidget(
                        controller:
                            widget.controller
                                .webView,
                      ),
                      if (widget.controller
                              .loading)
                        const Align(
                          alignment:
                              Alignment
                                  .topCenter,
                          child:
                              LinearProgressIndicator(),
                        ),
                      if (widget.controller
                              .lastError !=
                          null)
                        Align(
                          alignment:
                              Alignment
                                  .bottomCenter,
                          child:
                              _ErrorBanner(
                            message:
                                widget.controller
                                    .lastError!
                                    .message,
                            onClose:
                                widget.controller
                                    .clearError,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar:
          SafeArea(
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceEvenly,
          children: [
            IconButton(
              tooltip:
                  'Back',
              onPressed:
                  widget.controller
                      .goBack,
              icon: const Icon(
                Icons.arrow_back,
              ),
            ),
            IconButton(
              tooltip:
                  'Forward',
              onPressed:
                  widget.controller
                      .goForward,
              icon: const Icon(
                Icons.arrow_forward,
              ),
            ),
            IconButton(
              tooltip:
                  'Reload',
              onPressed:
                  widget.controller
                      .reload,
              icon: const Icon(
                Icons.refresh,
              ),
            ),
            IconButton(
              tooltip:
                  'Tabs',
              onPressed:
                  _showTabs,
              icon: const Icon(
                Icons.tab,
              ),
            ),
            IconButton(
              tooltip:
                  'Home',
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              icon: const Icon(
                Icons.home_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchHeader
    extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
  });

  final OptimisticBrowserController
      controller;

  @override
  Widget build(
    BuildContext context,
  ) {
    final String category =
        controller
            .searchCategory;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        12,
        8,
        12,
        4,
      ),
      child: Row(
        children: [
          Icon(
            Icons
                .travel_explore,
            size: 18,
            color:
                Theme.of(context)
                    .colorScheme
                    .primary,
          ),
          const SizedBox(
            width: 8,
          ),
          Expanded(
            child: Text(
              'Search: '
              '${controller.lastSearchQuery}',
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
          Text(
            category
                .toUpperCase(),
            style:
                Theme.of(context)
                    .textTheme
                    .labelSmall,
          ),
          const SizedBox(
            width: 8,
          ),
          if (controller
              .hasSearchResults)
            Text(
              '${controller.searchResultCount} results',
              style: Theme.of(
                context,
              ).textTheme.labelSmall,
            ),
        ],
      ),
    );
  }
}

class _SearchEmptyState
    extends StatelessWidget {
  const _SearchEmptyState({
    required this.controller,
  });

  final OptimisticBrowserController
      controller;

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool hasError =
        controller.lastError !=
            null;

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              hasError
                  ? Icons
                      .wifi_off_rounded
                  : Icons
                      .search_off_rounded,
              size: 52,
            ),
            const SizedBox(
              height: 14,
            ),
            Text(
              hasError
                  ? controller
                      .lastError!
                      .message
                  : 'No results found.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 14,
            ),
            Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                if (hasError)
                  FilledButton.icon(
                    onPressed:
                        controller
                            .retrySearch,
                    icon: const Icon(
                      Icons.refresh,
                    ),
                    label: const Text(
                      'Retry',
                    ),
                  ),
                if (hasError)
                  const SizedBox(
                    width: 8,
                  ),
                OutlinedButton(
                  onPressed:
                      controller
                          .clearSearchResults,
                  child:
                      const Text(
                    'Back to page',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner
    extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onClose,
  });

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      child: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(
            10,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline,
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Text(
                  message,
                  maxLines: 3,
                  overflow:
                      TextOverflow
                          .ellipsis,
                ),
              ),
              IconButton(
                tooltip:
                    'Dismiss',
                onPressed:
                    onClose,
                icon: const Icon(
                  Icons.close,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResults
    extends StatelessWidget {
  const _SearchResults({
    required this.results,
    required this.onOpen,
  });

  final List<SearchResult>
      results;

  final Future<void> Function(
    String,
  ) onOpen;

  String _domain(String url) {
    final Uri? uri =
        Uri.tryParse(url);

    if (uri == null ||
        uri.host.isEmpty) {
      return '';
    }

    return uri.host
        .replaceFirst(
          RegExp(r'^www\.'),
          '',
        );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListView.builder(
      padding:
          const EdgeInsets.fromLTRB(
        12,
        8,
        12,
        24,
      ),
      itemCount:
          results.length,
      itemBuilder:
          (context, index) {
        final SearchResult
            result =
            results[index];

        final String domain =
            _domain(
          result.url,
        );

        return Card(
          margin:
              const EdgeInsets.only(
            bottom: 10,
          ),
          clipBehavior:
              Clip.antiAlias,
          child: InkWell(
            onTap:
                result.url.isEmpty
                    ? null
                    : () => onOpen(
                          result.url,
                        ),
            child: Padding(
              padding:
                  const EdgeInsets.all(
                14,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  if (domain.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.public,
                          size: 16,
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        Expanded(
                          child:
                              Text(
                            domain,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                Theme.of(
                              context,
                            ).textTheme
                                .labelMedium,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    result.title,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  if (result.description
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 7,
                    ),
                    Text(
                      result.description,
                      maxLines: 4,
                      overflow:
                          TextOverflow
                              .ellipsis,
                    ),
                  ],
                  if (result.url
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      result.url,
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          Theme.of(
                        context,
                      ).textTheme
                          .bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TabStrip
    extends StatelessWidget {
  const _TabStrip({
    required this.controller,
    required this.onShowTabs,
  });

  final OptimisticBrowserController
      controller;

  final VoidCallback onShowTabs;

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          Expanded(
            child:
                ListView.separated(
              scrollDirection:
                  Axis.horizontal,
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              itemCount:
                  controller.tabs
                      .tabs.length,
              separatorBuilder:
                  (_, _) =>
                      const SizedBox(
                width: 6,
              ),
              itemBuilder:
                  (context, index) {
                final BrowserTab tab =
                    controller
                        .tabs
                        .tabs[index];

                final bool selected =
                    controller
                            .tabs
                            .active
                            ?.id ==
                        tab.id;

                return InkWell(
                  borderRadius:
                      BorderRadius
                          .circular(
                    18,
                  ),
                  onTap: () =>
                      controller
                          .selectTab(
                    tab.id,
                  ),
                  child:
                      Container(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 190,
                    ),
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 10,
                    ),
                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius
                              .circular(
                        18,
                      ),
                      color: selected
                          ? Theme.of(
                              context,
                            )
                              .colorScheme
                              .secondaryContainer
                          : Theme.of(
                              context,
                            )
                              .colorScheme
                              .surfaceContainerHighest,
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize
                              .min,
                      children: [
                        Icon(
                          tab.mode ==
                                  BrowserTabMode
                                      .private
                              ? Icons
                                  .visibility_off
                              : Icons
                                  .public,
                          size: 16,
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        Flexible(
                          child:
                              Text(
                            tab.title,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        InkWell(
                          onTap:
                              () =>
                                  controller.closeTab(
                            tab.id,
                          ),
                          child:
                              const Icon(
                            Icons.close,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            tooltip:
                'New tab',
            onPressed: () =>
                controller.newTab(),
            icon: const Icon(
              Icons.add,
            ),
          ),
          IconButton(
            tooltip:
                'Tab overview',
            onPressed:
                onShowTabs,
            icon: const Icon(
              Icons
                  .grid_view_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchCategoryBar
    extends StatelessWidget {
  const _SearchCategoryBar({
    required this.controller,
  });

  final OptimisticBrowserController
      controller;

  @override
  Widget build(
    BuildContext context,
  ) {
    const List<String>
        categories =
        <String>[
      'web',
      'images',
      'videos',
      'news',
      'shopping',
    ];

    return SingleChildScrollView(
      scrollDirection:
          Axis.horizontal,
      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      child: Row(
        children:
            categories.map(
          (String category) {
            final bool selected =
                controller
                        .searchCategory ==
                    category;

            return Padding(
              padding:
                  const EdgeInsets
                      .only(
                right: 6,
              ),
              child:
                  ChoiceChip(
                label: Text(
                  category[0]
                          .toUpperCase() +
                      category
                          .substring(
                    1,
                  ),
                ),
                selected:
                    selected,
                onSelected:
                    (bool value) {
                  if (!value) {
                    return;
                  }

                  controller
                      .setSearchCategory(
                    category,
                  );
                },
              ),
            );
          },
        ).toList(),
      ),
    );
  }
}