import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../models/models.dart';
import '../../../models/sub_order_model.dart';
import '../../../models/user_model.dart';
import '../../../models/coupon_model.dart';
import '../../../providers/app_state.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/order_service.dart';
import '../../../repositories/user_repository.dart';
import 'order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'card';
  bool _showConfirmation = false;
  bool _isProcessing = false;
  String? _selectedAddressId;
  Order? _createdOrder;
  final OrderService _orderService = OrderService();
  final UserRepository _userRepository = UserRepository();
  final CouponRepository _couponRepository = CouponRepository();
  final TextEditingController _couponController = TextEditingController();
  PaymentMethod? _defaultCard;
  bool _isValidatingCoupon = false;
  String? _couponError;

  @override
  void initState() {
    super.initState();
    // Select default address and load payment methods
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null &&
          authProvider.user!.addresses.isNotEmpty) {
        final defaultAddress = authProvider.user!.addresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => authProvider.user!.addresses.first,
        );
        setState(() {
          _selectedAddressId = defaultAddress.id;
        });
      }
      _loadDefaultPaymentMethod();
    });
  }

  Future<void> _loadDefaultPaymentMethod() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.userId != null) {
      try {
        final methods =
            await _userRepository.getPaymentMethods(authProvider.userId!);
        if (methods.isNotEmpty && mounted) {
          final defaultMethod = methods.firstWhere(
            (m) => m.isDefault,
            orElse: () => methods.first,
          );
          setState(() {
            _defaultCard = defaultMethod;
          });
        }
      } catch (e) {
        debugPrint('Error loading payment methods: $e');
      }
    }
  }

  Future<void> _processOrder() async {
    final appState = context.read<AppState>();
    final authProvider = context.read<AuthProvider>();

    if (appState.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('السلة فارغة')),
      );
      return;
    }

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')),
      );
      return;
    }

    // Get selected address
    String addressText = 'الاستلام من المحل';
    if (_selectedAddressId != null && authProvider.user!.addresses.isNotEmpty) {
      final address = authProvider.user!.addresses.firstWhere(
        (a) => a.id == _selectedAddressId,
        orElse: () => authProvider.user!.addresses.first,
      );
      addressText = '${address.label}: ${address.addressLine}, ${address.city}';
    }

    // Determine payment status
    PaymentStatus paymentStatus;
    if (_selectedPaymentMethod == 'cash') {
      paymentStatus = PaymentStatus.payOnPickup;
    } else {
      // For card/applepay, we assume payment is processed
      paymentStatus = PaymentStatus.paid;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Create order with split sub-orders using OrderService
      final order = await _orderService.createOrderWithSubOrders(
        userId: authProvider.userId!,
        userEmail: authProvider.user!.email,
        userName: authProvider.user!.name,
        userPhone: authProvider.user!.phone ?? '',
        cartItems: appState.cartItems.toList(),
        address: addressText,
        paymentMethod: _getPaymentMethodLabel(_selectedPaymentMethod),
        paymentStatus: paymentStatus,
        discount: appState.cartDiscount,
      );

      debugPrint('✅ Order created with ID: ${order.id}');
      debugPrint('📦 SubOrders: ${order.subOrderIds.join(', ')}');

      // Clear cart after successful order
      await appState.clearCart();

      setState(() {
        _createdOrder = order;
        _showConfirmation = true;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'card':
        return 'بطاقة ائتمان';
      case 'cash':
        return 'نقدي عند الاستلام';
      case 'applepay':
        return 'Apple Pay';
      default:
        return method;
    }
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
          'تأكيد الطلب',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Stack(
        children: [
          Consumer2<AppState, AuthProvider>(
            builder: (context, appState, authProvider, child) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order items preview
                    _buildOrderItemsSection(appState),
                    const SizedBox(height: 16),

                    // Delivery address
                    _buildAddressSection(authProvider),
                    const SizedBox(height: 16),

                    // Payment methods
                    _buildPaymentMethodsSection(),
                    const SizedBox(height: 16),

                    // Coupon section
                    _buildCouponSection(appState),
                    const SizedBox(height: 16),

                    // Order summary
                    _buildOrderSummary(appState),

                    const SizedBox(height: 100),
                  ],
                ),
              );
            },
          ),

          // Confirmation modal
          if (_showConfirmation) _buildConfirmationModal(),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: const Color.fromRGBO(0, 0, 0, 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryOrange,
                ),
              ),
            ),
        ],
      ),
      bottomSheet: _showConfirmation || _isProcessing
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _processOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'تأكيد الطلب',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildOrderItemsSection(AppState appState) {
    if (appState.cartItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'السلة فارغة',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '(${appState.cartItems.length})',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'المنتجات',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.primaryOrange,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...appState.cartItems.map((item) => _buildCartItemRow(item)),
        ],
      ),
    );
  }

  Widget _buildCartItemRow(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.product.hasDiscount)
                Text(
                  '\$${(item.product.oldPrice! / 50).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                '\$${(item.product.price / 50).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Product info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.nameAr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'القياس: ${item.selectedSize} • الكمية: ${item.quantity}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.product.imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryTeal,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(AuthProvider authProvider) {
    final addresses = authProvider.user?.addresses ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  // Navigate to add address screen
                  Navigator.pushNamed(context, '/addresses');
                },
                child: const Text(
                  'إضافة عنوان',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'عنوان التوصيل',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.local_shipping_outlined,
                    color: AppColors.primaryOrange,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (addresses.isEmpty)
            _buildPickupOption()
          else
            Column(
              children: [
                ...addresses.map((address) => _buildAddressOption(address)),
                const SizedBox(height: 8),
                _buildPickupOption(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAddressOption(Address address) {
    final isSelected = _selectedAddressId == address.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAddressId = address.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromRGBO(232, 122, 43, 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primaryOrange : AppColors.textHint,
              size: 20,
            ),
            const Spacer(),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${address.addressLine}, ${address.city}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.location_on_outlined,
              color: AppColors.textHint,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupOption() {
    final isSelected = _selectedAddressId == null;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAddressId = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromRGBO(232, 122, 43, 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primaryOrange : AppColors.textHint,
              size: 20,
            ),
            const Spacer(),
            const Text(
              'الاستلام من المحل',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.store_outlined,
              color: AppColors.textHint,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'وسائل الدفع',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildPaymentOption('ApplePay', 'applepay', Icons.apple),
              const SizedBox(width: 8),
              _buildPaymentOption('نقدي', 'cash', Icons.money),
              const SizedBox(width: 8),
              _buildPaymentOption('البطاقة', 'card', Icons.credit_card),
            ],
          ),
          if (_selectedPaymentMethod == 'card') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _defaultCard != null
                        ? '****${_defaultCard!.last4}'
                        : 'لا توجد بطاقة',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.credit_card,
                    color: _defaultCard != null
                        ? AppColors.pharaohBlue
                        : AppColors.textHint,
                    size: 24,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCouponSection(AppState appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              Text(
                'كود الخصم',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.local_offer_outlined,
                color: AppColors.primaryOrange,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (appState.appliedCoupon != null)
            // Show applied coupon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(76, 175, 80, 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color.fromRGBO(76, 175, 80, 0.3)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      appState.removeCoupon();
                      setState(() {
                        _couponController.clear();
                        _couponError = null;
                      });
                    },
                    icon: const Icon(Icons.close, size: 18),
                    color: AppColors.error,
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appState.appliedCoupon!.nameAr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'خصم ${appState.appliedCoupon!.discountText}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 24,
                  ),
                ],
              ),
            )
          else
            // Show coupon input
            Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isValidatingCoupon
                        ? null
                        : () => _applyCoupon(appState),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isValidatingCoupon
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Text(
                            'تطبيق',
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    textAlign: TextAlign.start,
                    
                    decoration: InputDecoration(
                      hintText: 'أدخل كود الخصم',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      errorText: _couponError,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _applyCoupon(AppState appState) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      setState(() => _couponError = 'يرجى إدخال كود الخصم');
      return;
    }

    setState(() {
      _isValidatingCoupon = true;
      _couponError = null;
    });

    try {
      final coupon = await _couponRepository.getCouponByCode(code);
      if (coupon == null) {
        setState(() => _couponError = 'كود الخصم غير صحيح');
      } else if (!coupon.isValid) {
        setState(() => _couponError = 'كود الخصم منتهي الصلاحية');
      } else if (coupon.minOrderAmount != null &&
          appState.cartSubtotal < coupon.minOrderAmount!) {
        setState(() => _couponError =
            'الحد الأدنى للطلب ${coupon.minOrderAmount!.toStringAsFixed(0)} ج.م');
      } else {
        appState.applyCoupon(coupon);
        setState(() => _couponError = null);
      }
    } catch (e) {
      setState(() => _couponError = 'حدث خطأ، يرجى المحاولة لاحقاً');
    } finally {
      setState(() => _isValidatingCoupon = false);
    }
  }

  Widget _buildOrderSummary(AppState appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSummaryRow('المجموع الفرعي',
              '\$${(appState.cartSubtotal / 50).toStringAsFixed(2)}'),
          _buildSummaryRow(
              'الضرائب', '\$${(appState.cartTaxes / 50).toStringAsFixed(2)}'),
          _buildSummaryRow(
              'الشحن', '\$${(appState.cartShipping / 50).toStringAsFixed(2)}'),
          if (appState.cartDiscount > 0)
            _buildSummaryRow('الخصم',
                '-\$${(appState.cartDiscount / 50).toStringAsFixed(2)}',
                isDiscount: true),
          const Divider(height: 24),
          _buildSummaryRow('إجمالي الطلب',
              '\$${(appState.cartTotal / 50).toStringAsFixed(2)}',
              isTotal: true),
        ],
      ),
    );
  }

  Widget _buildConfirmationModal() {
    return Container(
      color: const Color.fromRGBO(0, 0, 0, 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(76, 175, 80, 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'تم تأكيد الطلب بنجاح!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (_createdOrder != null)
                Text(
                  'رقم الطلب: ${_createdOrder!.id}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              const SizedBox(height: 8),
              if (_createdOrder != null)
                Text(
                  '\$${(_createdOrder!.total / 50).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryOrange,
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (_createdOrder != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderTrackingScreen(
                            orderId: _createdOrder!.id,
                          ),
                        ),
                      );
                    } else {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'تتبع الطلب',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text(
                  'العودة للرئيسية',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String label, String value, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.white : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isDiscount ? AppColors.success : AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
              color: isDiscount ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
