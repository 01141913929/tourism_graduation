import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../models/models.dart';
import '../../../models/sub_order_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/app_state.dart';
import '../../../repositories/order_repository.dart';
import '../../../repositories/sub_order_repository.dart';
import '../../../repositories/product_repository.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderRepository _orderRepository = OrderRepository();
  final SubOrderRepository _subOrderRepository = SubOrderRepository();

  List<Order> _allOrders = [];
  Map<String, List<SubOrder>> _subOrdersMap = {};
  bool _isLoading = true;

  List<Map<String, dynamic>> get _tabs {
    int processingCount = 0;
    int deliveredCount = 0;

    for (final subOrders in _subOrdersMap.values) {
      for (final sub in subOrders) {
        if (sub.status == SubOrderStatus.delivered) {
          deliveredCount++;
        } else if (sub.status != SubOrderStatus.rejected &&
            sub.status != SubOrderStatus.cancelled) {
          processingCount++;
        }
      }
    }

    return [
      {'label': 'الكل', 'count': _allOrders.length},
      {'label': 'قيد التنفيذ', 'count': processingCount},
      {'label': 'تم التسليم', 'count': deliveredCount},
      {'label': 'ملغي', 'count': 0},
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final authProvider = context.read<AuthProvider>();
      debugPrint(
          '📋 MyOrders: Loading orders for user: ${authProvider.userId}');

      if (authProvider.userId != null) {
        final orders =
            await _orderRepository.getUserOrders(authProvider.userId!);
        debugPrint('📋 MyOrders: Found ${orders.length} orders');

        // Load sub-orders for each order
        final Map<String, List<SubOrder>> subOrdersMap = {};
        for (final order in orders) {
          final subOrders = await _subOrderRepository.getSubOrdersByParent(
            order.id,
            customerId: authProvider.userId,
          );
          subOrdersMap[order.id] = subOrders;
          debugPrint(
              '📋 MyOrders: Order ${order.id} has ${subOrders.length} sub-orders');
        }

        if (mounted) {
          setState(() {
            _allOrders = orders;
            _subOrdersMap = subOrdersMap;
            _isLoading = false;
          });
        }
      } else {
        debugPrint('📋 MyOrders: No user ID, skipping load');
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e, stack) {
      debugPrint('❌ MyOrders Error: $e');
      debugPrint('📍 Stack: $stack');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
        title: const Text(
          'طلباتي',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: AppColors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.primaryOrange,
              indicatorWeight: 3,
              labelColor: AppColors.primaryOrange,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: _tabs
                  .map((tab) => Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tab['label']),
                            if (tab['count'] > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryOrange
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${tab['count']}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryOrange,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Orders List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList('all'),
                _buildOrdersList('processing'),
                _buildOrdersList('delivered'),
                _buildEmptyState(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String status) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange));
    }

    List<Order> filteredOrders = [];

    for (final order in _allOrders) {
      final subOrders = _subOrdersMap[order.id] ?? [];

      bool shouldInclude = false;
      switch (status) {
        case 'processing':
          shouldInclude = subOrders.any((s) =>
              s.status != SubOrderStatus.delivered &&
              s.status != SubOrderStatus.rejected &&
              s.status != SubOrderStatus.cancelled);
          break;
        case 'delivered':
          shouldInclude =
              subOrders.every((s) => s.status == SubOrderStatus.delivered);
          break;
        default:
          shouldInclude = true;
      }

      if (shouldInclude) {
        filteredOrders.add(order);
      }
    }

    if (filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        final subOrders = _subOrdersMap[order.id] ?? [];
        return _buildOrderCard(order, subOrders);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.textHint.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.box,
              size: 60,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد طلبات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ التسوق الآن!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, List<SubOrder> subOrders) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'ar');
    final allDelivered = subOrders.isNotEmpty &&
        subOrders.every((s) => s.status == SubOrderStatus.delivered);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: allDelivered
                  ? AppColors.success.withValues(alpha: 0.05)
                  : AppColors.primaryOrange.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Order info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.id}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(order.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Bazaar count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.shop,
                        size: 14,
                        color: AppColors.primaryGold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${subOrders.length} شحنة',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sub-orders (Shipments)
          ...subOrders.map((subOrder) => _buildSubOrderCard(subOrder)),

          // Total & Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الإجمالي',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${order.total.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(color: AppColors.divider),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Iconsax.message, size: 18),
                        label: const Text('المساعدة'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubOrderCard(SubOrder subOrder) {
    final isDelivered = subOrder.status == SubOrderStatus.delivered;
    final hasQR = subOrder.qrCode != null &&
        (subOrder.status == SubOrderStatus.accepted ||
            subOrder.status == SubOrderStatus.readyForPickup);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bazaar name and status
          Row(
            children: [
              Icon(
                Iconsax.shop,
                size: 16,
                color: AppColors.primaryGold,
              ),
              const SizedBox(width: 6),
              Text(
                subOrder.bazaarName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      _getStatusColor(subOrder.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  subOrder.statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(subOrder.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items
          ...subOrder.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        width: 45,
                        height: 45,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 45,
                          height: 45,
                          color: AppColors.background,
                          child: const Icon(Iconsax.box,
                              size: 20, color: AppColors.textHint),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'الكمية: ${item.quantity}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${item.totalPrice.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )),

          // Show QR button if available
          if (hasQR) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showQRCode(subOrder),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Iconsax.scan_barcode, size: 18),
                label: const Text('عرض رمز الاستلام'),
              ),
            ),
          ],

          // Show cancel button for pending orders
          if (subOrder.status == SubOrderStatus.pending) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showCancelDialog(subOrder),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Iconsax.close_circle, size: 18),
                label: const Text('إلغاء الطلب'),
              ),
            ),
          ],

          // Show reorder and rate buttons for delivered orders
          if (isDelivered) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRateDialog(subOrder),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      side: const BorderSide(color: AppColors.gold),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Iconsax.star1, size: 18),
                    label: const Text('تقييم'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _reorderItems(subOrder),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Iconsax.refresh, size: 18),
                    label: const Text('طلب مجدداً'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showRateDialog(SubOrder subOrder) {
    double rating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: StatefulBuilder(
            builder: (ctx, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'تقييم الطلب',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subOrder.bazaarName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () => setState(() => rating = index + 1.0),
                      icon: Icon(
                        index < rating ? Iconsax.star1 : Icons.star_border,
                        color: AppColors.gold,
                        size: 40,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'اكتب تعليقك هنا...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _submitReview(subOrder, rating, commentController.text);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('تم إرسال التقييم بنجاح!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('إرسال التقييم',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitReview(
      SubOrder subOrder, double rating, String comment) async {
    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userId == null) return;

      // Submit a review doc
      await FirebaseFirestore.instance.collection('reviews').add({
        'targetId': subOrder.bazaarId,
        'targetType': 'bazaar',
        'targetName': subOrder.bazaarName,
        'userId': authProvider.userId,
        'userName': authProvider.user?.name ?? 'مستخدم',
        'rating': rating,
        'comment': comment,
        'createdAt': DateTime.now().toIso8601String(),
        'orderId': subOrder.id,
      });
    } catch (e) {
      debugPrint('Error submitting review: $e');
    }
  }

  Color _getStatusColor(SubOrderStatus status) {
    switch (status) {
      case SubOrderStatus.pending:
        return Colors.orange;
      case SubOrderStatus.accepted:
        return Colors.blue;
      case SubOrderStatus.preparing:
        return Colors.purple;
      case SubOrderStatus.readyForPickup:
        return AppColors.primaryGold;
      case SubOrderStatus.shipping:
        return Colors.indigo;
      case SubOrderStatus.delivered:
        return AppColors.success;
      case SubOrderStatus.rejected:
      case SubOrderStatus.cancelled:
        return AppColors.error;
    }
  }

  void _showQRCode(SubOrder subOrder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '🎟️ رمز استلام الطلب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: QrImageView(
                data: subOrder.qrCode!,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: AppColors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoRow('البازار', subOrder.bazaarName),
            _buildInfoRow('رقم الطلب', '#${subOrder.id}'),
            _buildInfoRow(
                'الإجمالي', '${subOrder.subtotal.toStringAsFixed(0)} ج.م'),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.info_circle,
                    color: AppColors.primaryGold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'اعرض هذا الرمز عند الاستلام من البازار',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Show cancel confirmation dialog
  void _showCancelDialog(SubOrder subOrder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Iconsax.warning_2, color: Colors.orange),
            SizedBox(width: 8),
            Text('تأكيد الإلغاء'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('هل أنت متأكد من إلغاء هذا الطلب؟'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'البازار: ${subOrder.bazaarName}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'المبلغ: ${subOrder.subtotal.toStringAsFixed(0)} ج.م',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Iconsax.info_circle, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'يمكنك إلغاء الطلب فقط قبل موافقة البازار',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'لا، ابقاء الطلب',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelOrder(subOrder);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('نعم، إلغاء الطلب'),
          ),
        ],
      ),
    );
  }

  /// Cancel the order
  Future<void> _cancelOrder(SubOrder subOrder) async {
    try {
      final success = await _subOrderRepository.cancelSubOrder(subOrder.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء الطلب بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        // Reload orders
        _loadOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن إلغاء الطلب - تم قبوله من البازار'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Reorder items - add items to cart
  void _reorderItems(SubOrder subOrder) async {
    final appState = context.read<AppState>();

    // Add each item to cart
    for (final item in subOrder.items) {
      // Get product details
      final product = await ProductRepository().getProduct(item.productId);
      if (product != null) {
        appState.addToCart(product, item.selectedSize);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('تمت إضافة ${subOrder.items.length} منتجات للسلة'),
          ],
        ),
        backgroundColor: AppColors.success,
        action: SnackBarAction(
          label: 'عرض السلة',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pop(context);
            // Navigate to cart screen if needed
          },
        ),
      ),
    );
  }
}
