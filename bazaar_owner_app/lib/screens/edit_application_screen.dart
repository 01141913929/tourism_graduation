import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';

/// شاشة تعديل وإعادة تقديم طلب البازار المرفوض
class EditApplicationScreen extends StatefulWidget {
  const EditApplicationScreen({super.key});

  @override
  State<EditApplicationScreen> createState() => _EditApplicationScreenState();
}

class _EditApplicationScreenState extends State<EditApplicationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _bazaarNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  String _selectedGovernorate = 'القاهرة';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _applicationId;
  String? _rejectionReason;

  final List<String> _governorates = [
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'الأقصر',
    'أسوان',
    'الغردقة',
    'شرم الشيخ',
    'بورسعيد',
    'الإسماعيلية',
    'السويس',
    'دمياط',
    'المنصورة',
    'طنطا',
    'أخرى',
  ];

  @override
  void initState() {
    super.initState();
    _bazaarNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _loadExistingApplication();
  }

  Future<void> _loadExistingApplication() async {
    final authProvider = context.read<BazaarAuthProvider>();
    final userId = authProvider.userId;

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('bazaarApplications')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          _applicationId = snapshot.docs.first.id;
          _bazaarNameController.text = data['bazaarName'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _addressController.text = data['address'] ?? '';
          _phoneController.text = data['ownerPhone'] ?? '';
          _selectedGovernorate = data['governorate'] ?? 'القاهرة';
          _rejectionReason = data['rejectionReason'];
        });
      }
    } catch (e) {
      debugPrint('Error loading application: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resubmitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_applicationId == null) return;

    final authProvider = context.read<BazaarAuthProvider>();

    setState(() => _isSaving = true);

    try {
      // Update application
      await _firestore
          .collection('bazaarApplications')
          .doc(_applicationId)
          .update({
        'bazaarName': _bazaarNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'ownerPhone': _phoneController.text.trim(),
        'governorate': _selectedGovernorate,
        'status': 'pending',
        'rejectionReason': null,
        'resubmittedAt': DateTime.now().toIso8601String(),
      });

      // Update user status
      await _firestore.collection('users').doc(authProvider.userId).update({
        'applicationStatus': 'pending',
        'applicationRejectionReason': null,
      });

      // Refresh user data
      await authProvider.refreshUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إعادة تقديم الطلب بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _bazaarNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('تعديل طلب البازار'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Rejection reason banner
                  if (_rejectionReason != null && _rejectionReason!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Iconsax.warning_2,
                                  color: AppColors.error, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'سبب الرفض',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _rejectionReason!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'يرجى تعديل المعلومات وإعادة التقديم',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),

                  // Form fields
                  _buildSectionTitle('معلومات البازار'),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _bazaarNameController,
                    label: 'اسم البازار',
                    icon: Iconsax.shop,
                    validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _descriptionController,
                    label: 'وصف البازار',
                    icon: Iconsax.document_text,
                    maxLines: 3,
                    validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                    hint: 'وصف قصير عن منتجاتك وخدماتك...',
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle('الموقع'),
                  const SizedBox(height: 12),

                  _buildDropdown(),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _addressController,
                    label: 'العنوان التفصيلي',
                    icon: Iconsax.location,
                    maxLines: 2,
                    validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle('معلومات الاتصال'),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _phoneController,
                    label: 'رقم الهاتف',
                    icon: Iconsax.call,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _resubmitApplication,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Iconsax.send_2),
                      label: Text(
                          _isSaving ? 'جاري الإرسال...' : 'إعادة تقديم الطلب'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding:
              EdgeInsets.only(bottom: maxLines > 1 ? (maxLines - 1) * 24.0 : 0),
          child: Icon(icon),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGovernorate,
      items: _governorates
          .map((gov) => DropdownMenuItem(
                value: gov,
                child: Text(gov),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedGovernorate = value!),
      decoration: InputDecoration(
        labelText: 'المحافظة',
        prefixIcon: const Icon(Iconsax.map),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }
}
