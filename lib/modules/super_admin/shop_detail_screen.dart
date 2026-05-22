import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firestore/firestore_rule_safe_update.dart';
import '../../data/models/shop_model.dart';

/// Super Admin: view and edit a single shop.
/// Allows editing name and toggling status (Active/Inactive).
class ShopDetailScreen extends StatefulWidget {
  final ShopModel shop;

  const ShopDetailScreen({
    super.key,
    required this.shop,
  });

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  late TextEditingController _nameController;
  bool _saving = false;
  String _status = 'Active';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shop.name);
    _status = widget.shop.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges(BuildContext pageContext) async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      if (pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          const SnackBar(content: Text('Shop name cannot be empty')),
        );
      }
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shop.shopId)
          .update(
            FirestoreRuleSafeUpdate.shop(
              widget.shop,
              changes: {'name': newName},
            ),
          );
      if (pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          const SnackBar(content: Text('Shop updated')),
        );
      }
    } catch (e) {
      if (pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _toggleStatus(BuildContext pageContext) async {
    final newStatus = _status == 'Active' ? 'Inactive' : 'Active';
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shop.shopId)
          .update(
            FirestoreRuleSafeUpdate.shop(
              widget.shop,
              changes: {'status': newStatus},
            ),
          );
      if (!mounted) return;
      setState(() {
        _status = newStatus;
      });
      if (pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          SnackBar(content: Text('Shop status set to $newStatus')),
        );
      }
    } catch (e) {
      if (pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = _status == 'Active';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Details'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : () => _saveChanges(context),
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Shop ID',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                widget.shop.shopId,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Shop Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status: $_status',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _saving ? null : () => _toggleStatus(context),
                    icon: Icon(
                      isActive ? Icons.block : Icons.check_circle,
                    ),
                    label: Text(isActive ? 'Disable Shop' : 'Activate Shop'),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          isActive ? colorScheme.error : colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Disabling a shop will prevent its Admins and Employees '
                'from operating according to Firestore/Cloud Function rules.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

