import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/browser/browser_controller.dart';
import '../../services/ai/ai_models.dart';
import '../../services/ai/ai_service.dart';

class AiPage extends StatefulWidget {
  const AiPage({
    super.key,
    required this.pageUrl,
    required this.pageTitle,
    this.browser,
  });

  final String pageUrl;
  final String pageTitle;
  final OptimisticBrowserController? browser;

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final TextEditingController _prompt = TextEditingController();
  final List<Map<String, String>> _messages = [];
  AiModel _model = AiModel.auto;
  bool _busy = false;
  int _estimatedTokens = 0;

  @override
  void initState() {
    super.initState();
    _restoreConversation();
  }

  Future<void> _restoreConversation() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('optimistic.ai.conversation');
    if (raw == null) return;
    try {
      final decoded = (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((e) => {
                'role': '${e['role'] ?? ''}',
                'text': '${e['text'] ?? ''}',
              })
          .toList();
      if (mounted) setState(() => _messages.addAll(decoded));
    } catch (_) {}
  }

  Future<void> _persistConversation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('optimistic.ai.conversation', jsonEncode(_messages));
  }

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final prompt = _prompt.text.trim();
    if (prompt.isEmpty || _busy) return;

    setState(() {
      _busy = true;
      _messages.add({'role': 'user', 'text': prompt});
      _prompt.clear();
    });

    final pageText = await widget.browser?.pageText() ?? '';
    String answer;
    try {
      answer = await const AiService().ask(
        prompt: prompt,
        pageUrl: widget.browser?.currentUrl ?? widget.pageUrl,
        pageTitle: widget.browser?.title ?? widget.pageTitle,
        pageText: _cleanContext(pageText),
        model: _model,
      );
    } catch (error) {
      answer = 'AI error: $error';
    }

    if (!mounted) return;
    setState(() {
      _messages.add({'role': 'assistant', 'text': answer});
      _estimatedTokens = _messages.fold<int>(
        0,
        (sum, item) => sum + ((item['text']?.length ?? 0) / 4).ceil(),
      );
      _busy = false;
    });
    await _persistConversation();
  }

  String _cleanContext(String value) {
    final cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.length > 60000 ? cleaned.substring(0, 60000) : cleaned;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Optimistic AI',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                DropdownButton<AiModel>(
                  value: _model,
                  onChanged: (value) => setState(() => _model = value ?? AiModel.auto),
                  items: AiModel.values
                      .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                      .toList(),
                ),
              ],
            ),
            Text(
              widget.browser == null
                  ? 'AI Workspace'
                  : 'Ask this page • visible text is extracted locally before AI processing',
            ),
            if (_estimatedTokens > 0)
              Text('Estimated conversation tokens: $_estimatedTokens'),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  if (_messages.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'Ask about the current page. The AI context contains the current URL, title and extracted visible text.',
                        ),
                      ),
                    ),
                  ..._messages.map(
                    (message) => Align(
                      alignment: message['role'] == 'user'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(message['text'] ?? ''),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_busy) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            TextField(
              controller: _prompt,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _ask(),
              decoration: InputDecoration(
                hintText: 'Ask about this page...',
                suffixIcon: IconButton(
                  onPressed: _busy ? null : _ask,
                  icon: _busy
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.send_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
