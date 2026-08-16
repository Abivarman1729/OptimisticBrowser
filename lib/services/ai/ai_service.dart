import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/errors/app_error.dart';
import 'ai_models.dart';

class AiService {
  const AiService();

  Future<String> ask({
    required String prompt,
    String pageUrl = '',
    String pageTitle = '',
    String pageText = '',
    AiModel model = AiModel.auto,
  }) async {
    final value = prompt.trim();
    if (value.isEmpty) {
      throw const AppError(AppErrorType.validation, 'Type a question first.');
    }

    final payload = {
      'prompt': value,
      'pageUrl': pageUrl,
      'pageTitle': pageTitle,
      'pageText': pageText.length > 60000 ? pageText.substring(0, 60000) : pageText,
      'model': model.name,
    };

    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.aiBaseUrl}/api/ai'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppError(
          AppErrorType.aiProvider,
          'AI service returned HTTP ${response.statusCode}.',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final answer = (data['answer'] as String?)?.trim();
      if (answer == null || answer.isEmpty) {
        throw const AppError(AppErrorType.aiProvider, 'No answer returned.');
      }
      return answer;
    } on AppError {
      rethrow;
    } on FormatException catch (error) {
      throw AppError(AppErrorType.aiProvider, 'AI returned invalid JSON.', cause: error);
    } catch (error) {
      throw AppError(AppErrorType.network, 'AI service unavailable.', cause: error);
    }
  }
}
