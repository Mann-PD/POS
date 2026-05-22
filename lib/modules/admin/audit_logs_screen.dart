import 'package:flutter/material.dart';
import '../../core/observability/error_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firestore/firestore_pagination.dart';
import '../../data/models/audit_log_model.dart';
import '../../data/models/user_model.dart';
import '../../routing/permission_gate.dart';
import '../../routing/screen_permission.dart';
import '../../widgets/firestore_paginated_list.dart';

/// Read-only Audit Logs screen for Admin (own shop) and Super Admin (all).
/// Logs are append-only and immutable per requirements.
class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
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
        final u = UserModel.tryFromDocument(doc);
        if (u == null) {
          setState(() => _loading = false);
          return;
        }
        final role = u.role.toLowerCase().replaceAll(RegExp(r'[_\s-]'), '');
        setState(() {
          _shopId = u.shopId;
          _isSuperAdmin = role == 'superadmin';
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e, st) {
      reportCatch(e, stackTrace: st, tag: 'AuditLogsScreen._load');
      setState(() => _loading = false);
    }
  }

  Query<Map<String, dynamic>> _buildQuery() {
    if (!_isSuperAdmin &&
        _shopId != null &&
        _shopId!.isNotEmpty) {
      return FirebaseFirestore.instance
          .collection('audit_logs')
          .where('shopId', isEqualTo: _shopId)
          .orderBy('timestamp', descending: true);
    }
    return FirebaseFirestore.instance
        .collection('audit_logs')
        .orderBy('timestamp', descending: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return PermissionGate(
        permission: ScreenPermission.auditLogs,
        child: Scaffold(
          appBar: AppBar(title: const Text('Audit Logs')),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final cacheKey = _isSuperAdmin
        ? 'audit_logs_all'
        : 'audit_logs_shop_${_shopId ?? ''}';

    return PermissionGate(
      permission: ScreenPermission.auditLogs,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isSuperAdmin ? 'Audit Logs (All shops)' : 'Audit Logs'),
        ),
        body: FirestorePaginatedList<AuditLogModel>(
          cacheKey: cacheKey,
          pageSize: FirestorePageSize.audit,
          queryBuilder: _buildQuery,
          parse: (data, id) {
            final log = AuditLogModel.tryFromMap(data);
            return log;
          },
          itemKey: (l) => l.logId,
          emptyBuilder: (_) => const Center(child: Text('No audit logs yet.')),
          itemBuilder: (context, log) => Card(
            elevation: 1,
            child: ListTile(
              title: Text(
                log.action,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('${log.entityType} • ${log.entityId}'),
                  Text(
                    '${log.role} • ${_formatDate(log.timestamp)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.8),
                    ),
                  ),
                  if (log.shopId.isNotEmpty)
                    Text(
                      'Shop: ${log.shopId}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
              isThreeLine: true,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
