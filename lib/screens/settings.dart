import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:downsta/services/services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  static const routeName = "/settings";

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _organizeByUsername = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final db = Provider.of<DB>(context, listen: false);
    final organizeByUsername = await db.getOrganizeByUsername();
    setState(() {
      _organizeByUsername = organizeByUsername;
      _loading = false;
    });
  }

  Future<void> _setOrganizeByUsername(bool value) async {
    final db = Provider.of<DB>(context, listen: false);
    final downloader = Provider.of<Downloader>(context, listen: false);

    setState(() => _organizeByUsername = value);
    await db.setOrganizeByUsername(value);
    downloader.setOrganizeByUsername(value);
  }

  Future<void> _clearImageCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Image Cache"),
        content: const Text(
          "This will remove all cached images. They will be re-downloaded as needed.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Clear"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await DefaultCacheManager().emptyCache();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Image cache cleared"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // ── Downloads Section ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    "DOWNLOADS",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text("Organize by username"),
                  subtitle: const Text(
                    "Save downloads into separate folders for each user",
                  ),
                  value: _organizeByUsername,
                  onChanged: _setOrganizeByUsername,
                  activeThumbColor: theme.colorScheme.primary,
                  secondary: Icon(
                    Icons.folder_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const Divider(height: 32),

                // ── Storage Section ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Text(
                    "STORAGE",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.cached_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  title: const Text("Clear image cache"),
                  subtitle: const Text(
                    "Free up space by removing cached images",
                  ),
                  onTap: _clearImageCache,
                ),
              ],
            ),
    );
  }
}
