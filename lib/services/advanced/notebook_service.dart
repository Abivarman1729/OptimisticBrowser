class NotebookNote {
  NotebookNote({required this.id, required this.title, this.body = ''});
  final String id;
  String title;
  String body;
  final Set<String> tags = {};
  final Set<String> backlinks = {};
  final List<String> highlights = [];
  final List<String> versions = [];
  DateTime updatedAt = DateTime.now();
}

class NotebookService {
  final Map<String, NotebookNote> _notes = {};

  NotebookNote create(String id, String title, {String body = ''}) => _notes.putIfAbsent(id, () => NotebookNote(id: id, title: title, body: body));
  List<NotebookNote> all() => _notes.values.toList(growable: false);
  void autosave(String id, String body) {
    final note = _notes[id];
    if (note == null) return;
    note.versions.add(note.body);
    note.body = body;
    note.updatedAt = DateTime.now();
  }
  void addBacklink(String id, String targetId) => _notes[id]?.backlinks.add(targetId);
  void addHighlight(String id, String text) => _notes[id]?.highlights.add(text);
  String exportMarkdown(String id) {
    final n = _notes[id];
    if (n == null) return '';
    final tags = n.tags.map((t) => '#$t').join(' ');
    return '# ${n.title}\n\n${tags.isEmpty ? '' : '$tags\n\n'}${n.body}\n';
  }
  String rewrite(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ');
  String summarize(String text, {int maxWords = 40}) {
    final words = text.trim().split(RegExp(r'\s+'));
    return words.take(maxWords).join(' ');
  }
}
