import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/local/local_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _javascript = true;
  bool _adBlock = true;
  final LocalRepository _repo = const LocalRepository();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    if (mounted) {
      setState(() {
        _javascript = prefs.getBool('javascript') ?? true;
        _adBlock = prefs.getBool('ad_block') ?? true;
      });
    }
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(widget.themeMode.name),
            onTap: () {
              final next = widget.themeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
              widget.onThemeChanged(next);
            },
          ),
          SwitchListTile(
            title: const Text('JavaScript'),
            value: _javascript,
            onChanged: (value) {
              setState(() => _javascript = value);
              _save('javascript', value);
            },
          ),
          SwitchListTile(
            title: const Text('Ad blocker'),
            subtitle: const Text('Browser-level filtering hook'),
            value: _adBlock,
            onChanged: (value) {
              setState(() => _adBlock = value);
              _save('ad_block', value);
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('Privacy dashboard'),
            subtitle: Text(
              'Private tabs exclude history and clear WebView data at session boundaries. '
              'True per-profile storage isolation, network tracker blocking, secure DNS, '
              'WebRTC controls and fingerprint randomization require a native browser engine.',
            ),
          ),
          const ListTile(
            title: Text('HTTPS policy'),
            subtitle: Text(
              'Only HTTP/HTTPS navigation is accepted; blocked domains are rejected by policy.',
            ),
          ),
          ListTile(
            title: const Text('Clear browsing history'),
            onTap: () async {
              await _repo.clearHistory();
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History cleared.')),
                );
              }
            },
          ),
          const Divider(),
          const ListTile(
            title: Text('Search'),
            subtitle: Text(
              'Native Optimistic results with Web, Images, Videos, News and Shopping categories.',
            ),
          ),
          const ListTile(
            title: Text('App identity'),
            subtitle: Text('Optimistic Browser'),
          ),
        ],
      ),
    );
  }
}
