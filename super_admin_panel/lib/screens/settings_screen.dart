import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/colors.dart';
import '../services/product_service.dart';

/// شاشة إعدادات المنصة
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cloudinary Settings
  final _cloudNameController = TextEditingController();
  final _uploadPresetController = TextEditingController();

  // Platform Settings
  final _commissionController = TextEditingController(text: '10');
  final _shippingFeeController = TextEditingController(text: '25');
  final _taxRateController = TextEditingController(text: '14');
  final _minOrderController = TextEditingController(text: '50');

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final doc = await _firestore.collection('settings').doc('platform').get();

      if (doc.exists) {
        final data = doc.data()!;
        _cloudNameController.text = data['cloudinaryCloudName'] ?? '';
        _uploadPresetController.text = data['cloudinaryUploadPreset'] ?? '';
        _commissionController.text = (data['commissionRate'] ?? 10).toString();
        _shippingFeeController.text = (data['shippingFee'] ?? 25).toString();
        _taxRateController.text = (data['taxRate'] ?? 14).toString();
        _minOrderController.text = (data['minOrderAmount'] ?? 50).toString();

        // Apply Cloudinary settings
        ProductService.configureCloudinary(
          cloudName: _cloudNameController.text,
          uploadPreset: _uploadPresetController.text,
        );
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      await _firestore.collection('settings').doc('platform').set({
        'cloudinaryCloudName': _cloudNameController.text,
        'cloudinaryUploadPreset': _uploadPresetController.text,
        'commissionRate': double.tryParse(_commissionController.text) ?? 10,
        'shippingFee': double.tryParse(_shippingFeeController.text) ?? 25,
        'taxRate': double.tryParse(_taxRateController.text) ?? 14,
        'minOrderAmount': double.tryParse(_minOrderController.text) ?? 50,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      // Apply Cloudinary settings
      ProductService.configureCloudinary(
        cloudName: _cloudNameController.text,
        uploadPreset: _uploadPresetController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعدادات بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ الإعدادات: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    '⚙️ إعدادات المنصة',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'إدارة إعدادات المنصة والتكامل مع الخدمات الخارجية',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Cloudinary Settings
                  _buildSettingsCard(
                    title: 'إعدادات Cloudinary',
                    subtitle: 'لرفع وإدارة الصور',
                    icon: Iconsax.image,
                    children: [
                      _buildTextField(
                        controller: _cloudNameController,
                        label: 'Cloud Name',
                        hint: 'your-cloud-name',
                        prefixIcon: Iconsax.cloud,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _uploadPresetController,
                        label: 'Upload Preset',
                        hint: 'your-upload-preset',
                        prefixIcon: Iconsax.key,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Iconsax.info_circle,
                                color: AppColors.info, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'يمكنك الحصول على هذه المعلومات من لوحة تحكم Cloudinary الخاصة بك.',
                                style: TextStyle(
                                  color: AppColors.info.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Financial Settings
                  _buildSettingsCard(
                    title: 'الإعدادات المالية',
                    subtitle: 'العمولات والرسوم',
                    icon: Iconsax.money,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _commissionController,
                              label: 'نسبة العمولة (%)',
                              hint: '10',
                              keyboardType: TextInputType.number,
                              prefixIcon: Iconsax.percentage_circle,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _taxRateController,
                              label: 'نسبة الضريبة (%)',
                              hint: '14',
                              keyboardType: TextInputType.number,
                              prefixIcon: Iconsax.receipt,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _shippingFeeController,
                              label: 'رسوم الشحن (ج.م)',
                              hint: '25',
                              keyboardType: TextInputType.number,
                              prefixIcon: Iconsax.truck,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _minOrderController,
                              label: 'الحد الأدنى للطلب (ج.م)',
                              hint: '50',
                              keyboardType: TextInputType.number,
                              prefixIcon: Iconsax.wallet_2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // System Info
                  _buildSettingsCard(
                    title: 'معلومات النظام',
                    subtitle: 'معلومات عامة عن المنصة',
                    icon: Iconsax.info_circle,
                    children: [
                      _buildInfoRow('إصدار التطبيق', '1.0.0'),
                      const Divider(),
                      _buildInfoRow('بيئة العمل', 'Production'),
                      const Divider(),
                      _buildInfoRow('Firebase Project', 'Egyptian Tourism App'),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveSettings,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Icon(Iconsax.tick_circle),
                      label: Text(
                        _isSaving ? 'جاري الحفظ...' : 'حفظ الإعدادات',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
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

  @override
  void dispose() {
    _cloudNameController.dispose();
    _uploadPresetController.dispose();
    _commissionController.dispose();
    _shippingFeeController.dispose();
    _taxRateController.dispose();
    _minOrderController.dispose();
    super.dispose();
  }
}
