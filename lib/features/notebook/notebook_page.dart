import 'package:flutter/material.dart';
import '../../data/local/local_repository.dart';

class NotebookPage extends StatefulWidget {
  const NotebookPage({super.key});

  @override
  State<NotebookPage> createState() => _NotebookPageState();
}

class _NotebookPageState extends State<NotebookPage> {
  final LocalRepository _repo = const LocalRepository();
  final TextEditingController _search = TextEditingController();
  List<Map<String, Object?>> _notes = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
    _search.addListener(_onSearch);
  }

  void _onSearch() => _refresh();

  Future<void> _refresh() async {
    final notes = await _repo.notes(query: _search.text);
    if (mounted) setState(() => _notes = notes);
  }

  Future<void> _edit([Map<String, Object?>? note]) async {
    final title = TextEditingController(text: note?['title'] as String? ?? '');
    final body = TextEditingController(text: note?['body'] as String? ?? '');
    final tags = TextEditingController(text: note?['tags'] as String? ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note == null ? 'New note' : 'Edit note'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 10),
              TextField(
                controller: body,
                minLines: 5,
                maxLines: 12,
                decoration: const InputDecoration(labelText: 'Markdown / text'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tags,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'flutter, browser, idea',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await _repo.saveNote(
                id: note?['id'] as int?,
                title: title.text.trim(),
                body: body.text.trim(),
                tags: tags.text.trim(),
              );
              if (context.mounted) Navigator.pop(context);
              await _refresh();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    title.dispose();
    body.dispose();
    tags.dispose();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notebook'),
        actions: [
          IconButton(onPressed: () => _edit(), icon: const Icon(Icons.add)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search notes, content and tags',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _notes.isEmpty
                ? const Center(child: Text('No notes found.'))
                : ListView.builder(
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      final tags = note['tags'] as String? ?? '';
                      return Card(
                        child: ListTile(
                          title: Text(note['title'] as String),
                          subtitle: Text(
                            '${note['body'] as String}${tags.isEmpty ? '' : '\n\n# $tags'}',
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _edit(note),
                          trailing: IconButton(
                            onPressed: () async {
                              await _repo.deleteNote(note['id'] as int);
                              await _refresh();
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
