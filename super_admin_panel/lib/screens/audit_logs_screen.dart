import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../models/audit_log_model.dart';
import '../services/audit_service.dart';

/// شاشة سجل العمليات
class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final AuditService _auditService = AuditService();

  List<AuditLog> _logs = [];
  bool _isLoading = true;
  AuditActionType? _filterType;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);

    try {
      _logs = await _auditService.getAuditLogs(
        limit: 100,
        filterByType: _filterType,
      );
    } catch (e) {
      debugPrint('Error loading audit logs: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      appBar: AppBar(
        title: const Text('سجل العمليات'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          PopupMenuButton<AuditActionType?>(
            icon: const Icon(Iconsax.filter),
            onSelected: (type) {
              setState(() => _filterType = type);
              _loadLogs();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('الكل'),
              ),
              const PopupMenuItem(
                value: AuditActionType.applicationApproved,
                child: Text('قبول طلبات'),
              ),
              const PopupMenuItem(
                value: AuditActionType.applicationRejected,
                child: Text('رفض طلبات'),
              ),
              const PopupMenuItem(
                value: AuditActionType.bazaarVerified,
                child: Text('تفعيل بازارات'),
              ),
              const PopupMenuItem(
                value: AuditActionType.userRoleChanged,
                child: Text('تغيير صلاحيات'),
              ),
              const PopupMenuItem(
                value: AuditActionType.adminLogin,
                child: Text('تسجيل دخول'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.document_text,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد سجلات',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLogs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return _buildLogCard(log, colorScheme);
                    },
                  ),
                ),
    );
  }

  Widget _buildLogCard(AuditLog log, ColorScheme colorScheme) {
    final dateFormat = DateFormat('dd MMM yyyy - HH:mm', 'ar');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getActionColor(log.actionType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getActionIcon(log.actionType),
            color: _getActionColor(log.actionType),
            size: 20,
          ),
        ),
        title: Text(
          log.actionTypeArabic,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          textAlign: TextAlign.right,
        ),
        subtitle: Text(
          '${log.performedByName} • ${dateFormat.format(log.createdAt)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.right,
        ),
        trailing: Icon(
          Icons.expand_more,
          color: Colors.grey[400],
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          // Details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildDetailRow('الوصف', log.actionDescription),
                if (log.targetName != null)
                  _buildDetailRow('الهدف', log.targetName!),
                if (log.targetType != null)
                  _buildDetailRow(
                      'النوع', _getTargetTypeArabic(log.targetType!)),
                _buildDetailRow('بواسطة', log.performedByName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(AuditActionType type) {
    switch (type) {
      case AuditActionType.userCreated:
      case AuditActionType.userUpdated:
      case AuditActionType.userDeleted:
      case AuditActionType.userRoleChanged:
        return Iconsax.user;
      case AuditActionType.bazaarCreated:
      case AuditActionType.bazaarUpdated:
      case AuditActionType.bazaarVerified:
      case AuditActionType.bazaarUnverified:
      case AuditActionType.bazaarDeleted:
        return Iconsax.shop;
      case AuditActionType.applicationApproved:
        return Iconsax.tick_circle;
      case AuditActionType.applicationRejected:
        return Iconsax.close_circle;
      case AuditActionType.orderCreated:
      case AuditActionType.orderStatusChanged:
      case AuditActionType.orderCancelled:
        return Iconsax.receipt_item;
      case AuditActionType.productCreated:
      case AuditActionType.productUpdated:
      case AuditActionType.productDeleted:
        return Iconsax.box;
      case AuditActionType.couponCreated:
      case AuditActionType.couponUpdated:
      case AuditActionType.couponDeleted:
        return Iconsax.ticket_discount;
      case AuditActionType.adminLogin:
        return Iconsax.login;
      case AuditActionType.adminLogout:
        return Iconsax.logout;
      case AuditActionType.other:
        return Iconsax.document;
    }
  }

  Color _getActionColor(AuditActionType type) {
    switch (type) {
      case AuditActionType.applicationApproved:
      case AuditActionType.bazaarVerified:
      case AuditActionType.adminLogin:
        return Colors.green;
      case AuditActionType.applicationRejected:
      case AuditActionType.bazaarUnverified:
      case AuditActionType.userDeleted:
      case AuditActionType.bazaarDeleted:
      case AuditActionType.productDeleted:
      case AuditActionType.couponDeleted:
      case AuditActionType.orderCancelled:
        return Colors.red;
      case AuditActionType.userUpdated:
      case AuditActionType.bazaarUpdated:
      case AuditActionType.productUpdated:
      case AuditActionType.couponUpdated:
      case AuditActionType.orderStatusChanged:
        return Colors.orange;
      case AuditActionType.userRoleChanged:
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _getTargetTypeArabic(String type) {
    switch (type) {
      case 'user':
        return 'مستخدم';
      case 'bazaar':
        return 'بازار';
      case 'application':
        return 'طلب بازار';
      case 'order':
        return 'طلب';
      case 'product':
        return 'منتج';
      case 'coupon':
        return 'كوبون';
      default:
        return type;
    }
  }
}
