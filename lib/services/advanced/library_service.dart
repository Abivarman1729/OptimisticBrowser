import 'dart:convert';

class LibraryItem {
  LibraryItem({required this.url, required this.title, this.archived = false, this.readingList = false});
  final String url;
  String title;
  bool archived;
  bool readingList;
  final Set<String> tags = {};
}

class LibraryService {
  final Map<String, LibraryItem> _items = {};

  void add(LibraryItem item) => _items[item.url] = item;
  void archive(String url, bool value) => _items[url]?.archived = value;
  void readingList(String url, bool value) => _items[url]?.readingList = value;
  List<LibraryItem> duplicatesByTitle(String title) => _items.values.where((x) => x.title.trim().toLowerCase() == title.trim().toLowerCase()).toList(growable: false);
  List<LibraryItem> all() => _items.values.toList(growable: false);
  String exportJson() => jsonEncode(_items.values.map((x) => {'url': x.url, 'title': x.title, 'archived': x.archived, 'readingList': x.readingList, 'tags': x.tags.toList()}).toList());
  void importJson(String raw) {
    final data = jsonDecode(raw);
    if (data is! List) return;
    for (final value in data) {
      if (value is! Map) continue;
      final url = '${value['url'] ?? ''}';
      if (url.isEmpty) continue;
      final item = LibraryItem(url: url, title: '${value['title'] ?? ''}', archived: value['archived'] == true, readingList: value['readingList'] == true);
      final tags = value['tags'];
      if (tags is List) item.tags.addAll(tags.map((e) => '$e'));
      add(item);
    }
  }
}
