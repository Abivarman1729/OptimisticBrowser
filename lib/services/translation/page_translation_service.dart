import 'dart:convert';

import 'package:http/http.dart' as http;

class TranslationResult {
  const TranslationResult({
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.text,
  });

  final String sourceLanguage;
  final String targetLanguage;
  final String text;
}

class PageTranslationService {
  PageTranslationService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<TranslationResult> translate({
    required String text,
    required String targetLanguage,
    String sourceLanguage = 'auto',
    Uri? endpoint,
  }) async {
    if (text.trim().isEmpty) {
      return TranslationResult(
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        text: '',
      );
    }

    if (endpoint == null) {
      return TranslationResult(
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        text: text,
      );
    }

    final response = await _client.post(
      endpoint,
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'text': text,
        'source': sourceLanguage,
        'target': targetLanguage,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Translation failed: HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final translated = data is Map<String, dynamic>
        ? '${data['translatedText'] ?? data['text'] ?? ''}'
        : '';

    return TranslationResult(
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      text: translated,
    );
  }

  void dispose() => _client.close();
}
