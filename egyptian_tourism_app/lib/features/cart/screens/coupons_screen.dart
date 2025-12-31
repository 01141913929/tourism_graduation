import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../models/coupon_model.dart';

/// شاشة كوبونات الخصم
class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final CouponRepository _couponRepository = CouponRepository();
  final TextEditingController _codeController = TextEditingController();

  List<Coupon> _coupons = [];
  bool _isLoading = true;
  bool _isValidating = false;
  String? _validationMessage;
  bool _isValidCode = false;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() => _isLoading = true);
    try {
      final coupons = await _couponRepository.getActiveCoupons();
      setState(() {
        _coupons = coupons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _validateCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidating = true;
      _validationMessage = null;
    });

    try {
      final coupon = await _couponRepository.getCouponByCode(code);

      if (coupon == null) {
        setState(() {
          _validationMessage = 'كود الخصم غير صالح';
          _isValidCode = false;
        });
      } else if (!coupon.isValid) {
        setState(() {
          _validationMessage = 'كود الخصم منتهي الصلاحية';
          _isValidCode = false;
        });
      } else {
        setState(() {
          _validationMessage = 'كود صالح! خصم ${coupon.discountText}';
          _isValidCode = true;
        });
      }
    } catch (e) {
      setState(() {
        _validationMessage = 'حدث خطأ أثناء التحقق';
        _isValidCode = false;
      });
    }

    setState(() => _isValidating = false);
  }

  void _copyCouponCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم نسخ الكود'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.gold,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('كوبونات الخصم'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Code input section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('أدخل كود الخصم',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'مثال: SAVE20',
                          prefixIcon:
                              const Icon(Iconsax.ticket_discount, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        onChanged: (_) {
                          if (_validationMessage != null) {
                            setState(() => _validationMessage = null);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isValidating ? null : _validateCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isValidating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('تحقق'),
                    ),
                  ],
                ),
                if (_validationMessage != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        _isValidCode
                            ? Iconsax.tick_circle
                            : Iconsax.close_circle,
                        size: 18,
                        color: _isValidCode ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _validationMessage!,
                        style: TextStyle(
                          color: _isValidCode ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Coupons list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _coupons.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadCoupons,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _coupons.length,
                          itemBuilder: (context, index) =>
                              _buildCouponCard(_coupons[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.ticket_discount, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('لا توجد كوبونات متاحة حالياً'),
          const SizedBox(height: 8),
          Text('تابعنا للحصول على عروض حصرية',
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildCouponCard(Coupon coupon) {
    final daysLeft = coupon.endDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            left: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Discount badge
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.gold, AppColors.gold.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        coupon.type == CouponType.percentage
                            ? '${coupon.value.toStringAsFixed(0)}%'
                            : '${coupon.value.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        coupon.type == CouponType.percentage
                            ? 'خصم'
                            : 'ج.م خصم',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(coupon.nameAr,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 4),
                      if (coupon.descriptionAr != null)
                        Text(
                          coupon.descriptionAr!,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Iconsax.clock,
                              size: 14,
                              color:
                                  daysLeft < 3 ? Colors.red : Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            daysLeft <= 0
                                ? 'ينتهي اليوم'
                                : 'ينتهي خلال $daysLeft يوم',
                            style: TextStyle(
                              color:
                                  daysLeft < 3 ? Colors.red : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          if (coupon.minOrderAmount != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              'حد أدنى: ${coupon.minOrderAmount!.toStringAsFixed(0)} ج.م',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.grey[300]!,
                                  style: BorderStyle.solid),
                            ),
                            child: Text(
                              coupon.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _copyCouponCode(coupon.code),
                            icon: Icon(Iconsax.copy,
                                size: 20, color: AppColors.gold),
                            tooltip: 'نسخ',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.gold.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
