import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../widgets/optimistic_logo.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.onOpenInput,
    required this.onOpenAi,
    required this.onOpenLibrary,
  });

  final ValueChanged<String> onOpenInput;
  final VoidCallback onOpenAi;
  final VoidCallback onOpenLibrary;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _submit() {
    final q = _search.text.trim();
    if (q.isNotEmpty) widget.onOpenInput(q);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
              child: Column(
                children: [
                  const OptimisticLogo(width: 320),
                  const SizedBox(height: 14),
                  Text(
                    AppConfig.homeTitle ?? 'Optimistic',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(AppConfig.homeSubtitle ?? 'Search the web faster.'),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Search the web or enter a URL',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: IconButton(
                        onPressed: _submit,
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [
                _ActionCard(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Optimistic AI',
                  onTap: widget.onOpenAi,
                ),
                _ActionCard(
                  icon: Icons.bookmarks_rounded,
                  title: 'Library',
                  onTap: widget.onOpenLibrary,
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Search is rendered by the Optimistic backend. Google search pages are intentionally not used as the browser home.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 32),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      );
}
