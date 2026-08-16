
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/errors/app_error.dart';

class SearchResult {
  const SearchResult({
    required this.title,
    required this.url,
    required this.description,
  });

  final String title;
  final String url;
  final String description;

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
        title: (json['title'] as String?)?.trim() ?? 'Untitled',
        url: (json['url'] as String?)?.trim() ?? '',
        description: (json['description'] as String?)?.trim() ?? '',
      );
}

class SearchService {
  const SearchService();

  Future<List<SearchResult>> search(
    String query, {
    String category = 'web',
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/search').replace(
        queryParameters: {'q': q, 'category': category},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppError(
          AppErrorType.searchProvider,
          'Search service returned HTTP ${response.statusCode}.',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = data['results'] as List<dynamic>? ?? const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(SearchResult.fromJson)
          .where((r) => r.url.isNotEmpty)
          .toList(growable: false);
    } on AppError {
      rethrow;
    } catch (error) {
      throw AppError(AppErrorType.network, 'Search service unavailable.', cause: error);
    }
  }
}
