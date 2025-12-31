import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';

/// شاشة جميع الطلبات
class AllOrdersScreen extends StatefulWidget {
  const AllOrdersScreen({super.key});

  @override
  State<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<AllOrdersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filterStatus = 'all';
  List<Map<String, dynamic>> _orders = [];
  Map<String, List<Map<String, dynamic>>> _subOrdersMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final ordersSnapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final orders = ordersSnapshot.docs.map((doc) {
        return {...doc.data(), 'id': doc.id};
      }).toList();

      // Load sub-orders for each order
      final Map<String, List<Map<String, dynamic>>> subOrdersMap = {};
      for (final order in orders) {
        if (!mounted) return;
        final subOrdersSnapshot = await _firestore
            .collection('subOrders')
            .where('parentOrderId', isEqualTo: order['id'])
            .get();

        subOrdersMap[order['id']] = subOrdersSnapshot.docs.map((doc) {
          return {...doc.data(), 'id': doc.id};
        }).toList();
      }

      if (mounted) {
        setState(() {
          _orders = orders;
          _subOrdersMap = subOrdersMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: AppColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📦 جميع الطلبات',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'عرض وتتبع جميع الطلبات في المنصة',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _loadOrders,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                      icon: const Icon(Iconsax.refresh, size: 18),
                      label: const Text('تحديث'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'الكل'),
                      const SizedBox(width: 8),
                      _buildFilterChip('pending', 'قيد الانتظار'),
                      const SizedBox(width: 8),
                      _buildFilterChip('accepted', 'تمت الموافقة'),
                      const SizedBox(width: 8),
                      _buildFilterChip('preparing', 'قيد التحضير'),
                      const SizedBox(width: 8),
                      _buildFilterChip('shipping', 'قيد الشحن'),
                      const SizedBox(width: 8),
                      _buildFilterChip('delivered', 'تم التسليم'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Orders list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _orders.isEmpty
                    ? _buildEmptyState()
                    : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterStatus == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterStatus = value),
      backgroundColor: AppColors.white,
      selectedColor: AppColors.primary.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.divider,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.box, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text(
            'لا توجد طلبات',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    var filteredOrders = _orders;

    if (_filterStatus != 'all') {
      filteredOrders = _orders.where((order) {
        final subOrders = _subOrdersMap[order['id']] ?? [];
        return subOrders.any((sub) => sub['status'] == _filterStatus);
      }).toList();
    }

    if (filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        final subOrders = _subOrdersMap[order['id']] ?? [];
        return _buildOrderCard(order, subOrders);
      },
    );
  }

  Widget _buildOrderCard(
    Map<String, dynamic> order,
    List<Map<String, dynamic>> subOrders,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'ar');
    DateTime? createdAt;
    try {
      createdAt = DateTime.parse(order['createdAt'] as String);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Iconsax.box, color: AppColors.primary),
        ),
        title: Row(
          children: [
            Text(
              '#${order['id']?.toString().substring(0, 8) ?? 'N/A'}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${subOrders.length} شحنة',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              order['userName'] ?? 'مستخدم',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            if (createdAt != null)
              Text(
                dateFormat.format(createdAt),
                style: const TextStyle(color: AppColors.textHint, fontSize: 12),
              ),
          ],
        ),
        trailing: Text(
          '${(order['total'] as num?)?.toStringAsFixed(0) ?? '0'} ج.م',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        children: [
          if (subOrders.isEmpty)
            const Text('لا توجد شحنات')
          else
            ...subOrders.map((sub) => _buildSubOrderItem(sub)),
        ],
      ),
    );
  }

  Widget _buildSubOrderItem(Map<String, dynamic> subOrder) {
    final status = subOrder['status'] as String? ?? 'pending';
    final statusInfo = _getStatusInfo(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Iconsax.shop, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subOrder['bazaarName'] ?? 'بازار',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(subOrder['subtotal'] as num?)?.toStringAsFixed(0) ?? '0'} ج.م',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusInfo['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusInfo['label'],
              style: TextStyle(
                color: statusInfo['color'],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return {'label': 'قيد الانتظار', 'color': AppColors.warning};
      case 'accepted':
        return {'label': 'تمت الموافقة', 'color': AppColors.info};
      case 'preparing':
        return {'label': 'قيد التحضير', 'color': Colors.purple};
      case 'readyForPickup':
        return {'label': 'جاهز للاستلام', 'color': AppColors.secondary};
      case 'shipping':
        return {'label': 'قيد الشحن', 'color': Colors.indigo};
      case 'delivered':
        return {'label': 'تم التسليم', 'color': AppColors.success};
      case 'rejected':
        return {'label': 'مرفوض', 'color': AppColors.error};
      case 'cancelled':
        return {'label': 'ملغي', 'color': AppColors.error};
      default:
        return {'label': 'غير معروف', 'color': AppColors.textHint};
    }
  }
}
