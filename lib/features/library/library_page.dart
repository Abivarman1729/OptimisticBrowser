import 'package:flutter/material.dart';
import '../../data/local/local_repository.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.onOpenUrl});
  final ValueChanged<String> onOpenUrl;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final LocalRepository _repo = const LocalRepository();
  final TextEditingController _search = TextEditingController();
  List<Map<String, Object?>> _bookmarks = const [];
  List<Map<String, Object?>> _history = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
    _search.addListener(_refresh);
  }

  Future<void> _refresh() async {
    final bookmarks = await _repo.bookmarks(query: _search.text);
    final history = await _repo.history(query: _search.text);
    if (!mounted) return;
    setState(() {
      _bookmarks = bookmarks;
      _history = history;
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Library'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Bookmarks'), Tab(text: 'History')],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search library',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _UrlList(
                    items: _bookmarks,
                    onOpen: widget.onOpenUrl,
                    onDelete: (id) async {
                      await _repo.deleteBookmark(id);
                      await _refresh();
                    },
                  ),
                  _UrlList(items: _history, onOpen: widget.onOpenUrl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UrlList extends StatelessWidget {
  const _UrlList({
    required this.items,
    required this.onOpen,
    this.onDelete,
  });

  final List<Map<String, Object?>> items;
  final ValueChanged<String> onOpen;
  final Future<void> Function(int id)? onDelete;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('Nothing saved yet.'));
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final title = item['title'] as String? ?? 'Untitled';
        final url = item['url'] as String? ?? '';
        return ListTile(
          leading: const Icon(Icons.public),
          title: Text(title),
          subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => onOpen(url),
          trailing: onDelete == null
              ? null
              : IconButton(
                  onPressed: () => onDelete!(item['id'] as int),
                  icon: const Icon(Icons.delete_outline),
                ),
        );
      },
    );
  }
}
