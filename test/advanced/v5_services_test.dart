import 'package:flutter_test/flutter_test.dart';
import 'package:optimistic_browser/services/advanced/search_advanced_service.dart';
import 'package:optimistic_browser/services/advanced/ai_workspace_service.dart';
import 'package:optimistic_browser/services/advanced/notebook_service.dart';
import 'package:optimistic_browser/services/advanced/library_service.dart';

void main() {
  test('advanced search suggests and corrects', () {
    const service = AdvancedSearchService();
    expect(service.suggest('goo', ['google', 'github']).first.text, 'google');
    expect(service.correctTypo('googel', ['google', 'github']), 'google');
  });

  test('AI workspace folders and streaming work', () async {
    final service = AiWorkspaceService();
    service.createConversation('1', 'Test');
    service.moveToFolder('1', 'Work');
    expect(service.byFolder('Work').length, 1);
    expect(await service.streamText('abcdef', chunkSize: 2).toList(), ['ab', 'cd', 'ef']);
  });

  test('notebook autosave/version/export work', () {
    final service = NotebookService();
    service.create('1', 'Note', body: 'old');
    service.autosave('1', 'new');
    expect(service.all().single.versions.single, 'old');
    expect(service.exportMarkdown('1'), contains('# Note'));
  });

  test('library import/export/archive/reading-list work', () {
    final service = LibraryService();
    service.add(LibraryItem(url: 'https://example.com', title: 'Example'));
    service.archive('https://example.com', true);
    service.readingList('https://example.com', true);
    final copy = LibraryService()..importJson(service.exportJson());
    expect(copy.all().single.archived, isTrue);
    expect(copy.all().single.readingList, isTrue);
  });
}
