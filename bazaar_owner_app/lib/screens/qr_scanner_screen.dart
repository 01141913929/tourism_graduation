import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/order_provider.dart';
import '../core/constants/colors.dart';
import '../models/sub_order_model.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  SubOrder? _scannedOrder;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _processQRCode(String code) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final orderProvider = context.read<OrderProvider>();
      final order = await orderProvider.confirmPickupWithQR(code);

      setState(() {
        _scannedOrder = order;
        _isProcessing = false;
      });

      // Stop scanning
      cameraController.stop();
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'مسح رمز الاستلام',
          style: TextStyle(color: AppColors.white),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                return Icon(
                  state == TorchState.on ? Iconsax.flash_15 : Iconsax.flash_1,
                  color: AppColors.white,
                );
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera
          if (_scannedOrder == null)
            MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _processQRCode(barcode.rawValue!);
                    break;
                  }
                }
              },
            ),

          // Overlay
          if (_scannedOrder == null)
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

          // Instructions
          if (_scannedOrder == null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    'وجّه الكاميرا نحو رمز QR',
                    style: TextStyle(color: AppColors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الموجود على هاتف العميل',
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: AppColors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'جاري التحقق...',
                      style: TextStyle(color: AppColors.white),
                    ),
                  ],
                ),
              ),
            ),

          // Order details
          if (_scannedOrder != null) _buildOrderDetails(),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    final order = _scannedOrder!;

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Success icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.tick_circle5,
                    size: 48,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'تم التحقق بنجاح!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),

                // Order info
                _buildInfoRow('رقم الطلب', '#${order.id.substring(0, 8)}'),
                _buildInfoRow('اسم العميل', order.customerName),
                _buildInfoRow('رقم الهاتف', order.customerPhone),
                _buildInfoRow('عدد المنتجات', '${order.itemCount}'),
                _buildInfoRow(
                  'الإجمالي',
                  '${order.subtotal.toStringAsFixed(0)} ج.م',
                ),

                const SizedBox(height: 24),

                // Products list
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'المنتجات:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...order.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                '${item.quantity}x',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.productName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                '${item.totalPrice.toStringAsFixed(0)} ج.م',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Confirm delivery button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _confirmDelivery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Iconsax.tick_circle),
                    label: const Text(
                      'تأكيد التسليم',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _scannedOrder = null;
                    });
                    cameraController.start();
                  },
                  child: const Text('مسح رمز آخر'),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelivery() async {
    if (_scannedOrder == null) return;

    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.confirmDelivery(_scannedOrder!.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تأكيد التسليم بنجاح!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
