import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/setting_model.dart';
import '../../data/models/user_model.dart';
import '../../core/rbac/role_constants.dart';

/// Settings screen: Shop-level (Admin) or System-level (Super Admin).
/// Read/write per Firestore rules; future-only application per requirements.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _shopId;
  bool _isSuperAdmin = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final u = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        setState(() {
          _shopId = u.shopId;
          _isSuperAdmin = u.role == RoleConstants.superAdmin;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Query _buildQuery() {
    if (_isSuperAdmin) {
      return FirebaseFirestore.instance
          .collection('settings')
          .where('scope', isEqualTo: 'system')
          .orderBy('key');
    }
    final shopId = _shopId ?? '';
    return FirebaseFirestore.instance
        .collection('settings')
        .where('scope', isEqualTo: 'shop')
        .where('shopId', isEqualTo: shopId)
        .orderBy('key');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSuperAdmin ? 'System Settings' : 'Shop Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addOrEditSetting(context, null),
            tooltip: 'Add setting',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _buildQuery().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          final settings = docs
              .map((d) => SettingModel.fromMap(
                  {...d.data() as Map<String, dynamic>, 'settingId': d.id}))
              .toList();
          if (settings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No settings yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _addOrEditSetting(context, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Add setting'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: settings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final s = settings[index];
              return Card(
                child: ListTile(
                  title: Text(s.key),
                  subtitle: Text(_valueDisplay(s.value)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _addOrEditSetting(context, s),
                      ),
                      if (_isSuperAdmin)
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteSetting(context, s),
                        ),
                    ],
                  ),
                  onTap: () => _addOrEditSetting(context, s),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _valueDisplay(dynamic value) {
    if (value == null) return '—';
    if (value is num) return value.toString();
    if (value is bool) return value ? 'Yes' : 'No';
    return value.toString();
  }

  Future<void> _addOrEditSetting(BuildContext context, SettingModel? existing) async {
    final keyController = TextEditingController(text: existing?.key ?? '');
    final valueController = TextEditingController(
      text: existing?.value?.toString() ?? '',
    );
    final isNew = existing == null;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isNew ? 'Add setting' : 'Edit setting'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: 'Key',
                  hintText: 'e.g. low_stock_threshold',
                ),
                enabled: isNew,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(
                  labelText: 'Value',
                  hintText: 'e.g. 10',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final key = keyController.text.trim();
              final valueStr = valueController.text.trim();
              if (key.isEmpty) return;
              num? valueNum = num.tryParse(valueStr);
              Navigator.pop(context, {
                'key': key,
                'value': valueNum ?? valueStr,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null || !context.mounted) return;

    final key = result['key'] as String;
    final value = result['value'];

    try {
      final db = FirebaseFirestore.instance;
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      if (isNew) {
        final settingId = _isSuperAdmin
            ? 'system_$key'
            : 'shop_${_shopId}_$key';
        final doc = <String, dynamic>{
          'settingId': settingId,
          'scope': _isSuperAdmin ? 'system' : 'shop',
          'key': key,
          'value': value,
          'updatedAt': timestamp,
        };
        if (!_isSuperAdmin && _shopId != null) {
          doc['shopId'] = _shopId;
        }
        await db.collection('settings').doc(settingId).set(doc);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Setting added')),
          );
        }
      } else {
        await db.collection('settings').doc(existing.settingId).update({
          'value': value,
          'updatedAt': timestamp,
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Setting updated')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteSetting(BuildContext context, SettingModel s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete setting?'),
        content: Text('Delete "${s.key}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc(s.settingId)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setting deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
