import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../data/models/user_model.dart';

/// Settings Screen
///
/// Loads settings from the `settings` Firestore collection.
/// - Admin  → can read & update scope == 'shop' settings for their shop
/// - SuperAdmin → can read & update all settings (scope == 'shop' or 'system')
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? _currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          _currentUser = UserModel.fromMap(
            userDoc.data() as Map<String, dynamic>,
          );
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUser = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    }
  }

  Stream<QuerySnapshot> _settingsStream() {
    final db = FirebaseFirestore.instance;
    final user = _currentUser!;

    if (user.role == 'SuperAdmin') {
      // Super Admin sees all settings
      return db.collection('settings').snapshots();
    } else {
      // Admin sees only their shop-level settings
      return db
          .collection('settings')
          .where('scope', isEqualTo: 'shop')
          .where('shopId', isEqualTo: user.shopId)
          .snapshots();
    }
  }

  Future<void> _updateSetting(
    BuildContext context,
    Map<String, dynamic> settingData,
  ) async {
    final settingId = settingData['settingId'] as String;
    final currentValue = settingData['value']?.toString() ?? '';

    final controller = TextEditingController(text: currentValue);

    final newValue = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update: ${settingData['key']}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Value',
            hintText: 'Enter new value for ${settingData['key']}',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newValue == null || newValue == currentValue) return;
    if (!mounted) return;

    try {
      // Update setting in Firestore
      // Firestore rules allow Admin (scope=shop) and SuperAdmin to update settings directly
      await FirebaseFirestore.instance
          .collection('settings')
          .doc(settingId)
          .update({
        'value': newValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Write audit log via Cloud Function (direct client writes to audit_logs
      // are blocked by Firestore rules: allow create: if false)
      try {
        final functions = FirebaseFunctions.instance;
        final logEvent = functions.httpsCallable('logAuthEvent');
        await logEvent.call({
          'action': 'SETTING_UPDATED',
          'entityType': 'setting',
          'entityId': settingId,
          'metadata': {
            'key': settingData['key'],
            'oldValue': currentValue,
            'newValue': newValue,
            'scope': settingData['scope'],
          },
        });
      } catch (_) {
        // Audit log failure is non-fatal; setting was already saved
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setting "${settingData['key']}" updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update setting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: _isLoadingUser
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : _currentUser == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      const Text('Unable to load user information'),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _loadCurrentUser,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: _settingsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text('Error loading settings: ${snapshot.error}'),
                          ],
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.settings_outlined,
                              size: 64,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No settings found',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Settings will appear here once configured',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Group settings by scope for cleaner display
                    final shopSettings = docs
                        .map((d) => d.data() as Map<String, dynamic>)
                        .where((s) => s['scope'] == 'shop')
                        .toList();
                    final systemSettings = docs
                        .map((d) => d.data() as Map<String, dynamic>)
                        .where((s) => s['scope'] == 'system')
                        .toList();

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (shopSettings.isNotEmpty) ...[
                          _SectionHeader(
                            label: 'Shop Settings',
                            icon: Icons.store_outlined,
                            colorScheme: colorScheme,
                            theme: theme,
                          ),
                          const SizedBox(height: 8),
                          ...shopSettings.map(
                            (setting) => _SettingTile(
                              setting: setting,
                              onEdit: () =>
                                  _updateSetting(context, setting),
                            ),
                          ),
                        ],
                        if (systemSettings.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _SectionHeader(
                            label: 'System Settings',
                            icon: Icons.tune_outlined,
                            colorScheme: colorScheme,
                            theme: theme,
                          ),
                          const SizedBox(height: 8),
                          ...systemSettings.map(
                            (setting) => _SettingTile(
                              setting: setting,
                              onEdit: () =>
                                  _updateSetting(context, setting),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final Map<String, dynamic> setting;
  final VoidCallback onEdit;

  const _SettingTile({required this.setting, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final key = setting['key']?.toString() ?? '—';
    final value = setting['value']?.toString() ?? '—';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          key,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.outline,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
          onPressed: onEdit,
          tooltip: 'Edit setting',
        ),
      ),
    );
  }
}
