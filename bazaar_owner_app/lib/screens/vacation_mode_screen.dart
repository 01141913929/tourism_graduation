import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';

/// شاشة وضع الإجازة/الإغلاق المؤقت
class VacationModeScreen extends StatefulWidget {
  const VacationModeScreen({super.key});

  @override
  State<VacationModeScreen> createState() => _VacationModeScreenState();
}

class _VacationModeScreenState extends State<VacationModeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();

  bool _isOpen = true;
  bool _isLoading = true;
  bool _isSaving = false;
  DateTime? _vacationEndDate;
  String _vacationMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final authProvider = context.read<BazaarAuthProvider>();
    final bazaarId = authProvider.user?.bazaarId;

    if (bazaarId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await _firestore.collection('bazaars').doc(bazaarId).get();
      final data = doc.data();

      if (data != null) {
        setState(() {
          _isOpen = data['isOpen'] as bool? ?? true;
          _vacationMessage = data['vacationMessage'] as String? ?? '';
          _messageController.text = _vacationMessage;

          final endDateStr = data['vacationEndDate'] as String?;
          if (endDateStr != null) {
            _vacationEndDate = DateTime.tryParse(endDateStr);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading vacation settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final authProvider = context.read<BazaarAuthProvider>();
    final bazaarId = authProvider.user?.bazaarId;

    if (bazaarId == null) return;

    setState(() => _isSaving = true);

    try {
      await _firestore.collection('bazaars').doc(bazaarId).update({
        'isOpen': _isOpen,
        'vacationMessage': _messageController.text.trim(),
        'vacationEndDate': _vacationEndDate?.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(_isOpen ? 'البازار مفتوح الآن' : 'تم تفعيل وضع الإجازة'),
            ],
          ),
          backgroundColor:
              _isOpen ? AppColors.success : AppColors.warning,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _vacationEndDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
    );

    if (date != null) {
      setState(() => _vacationEndDate = date);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('وضع الإجازة'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status card
                  _buildStatusCard(),
                  const SizedBox(height: 24),

                  // Toggle switch
                  _buildToggleCard(),
                  const SizedBox(height: 24),

                  // Vacation settings (only show when closed)
                  if (!_isOpen) ...[
                    _buildVacationSettings(),
                    const SizedBox(height: 24),
                  ],

                  // Preview
                  _buildPreviewCard(),
                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'حفظ التغييرات',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isOpen
              ? [AppColors.success, AppColors.success.withOpacity(0.8)]
              : [Colors.orange, Colors.orange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isOpen ? AppColors.success : Colors.orange)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isOpen ? Iconsax.shop : Iconsax.moon,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOpen ? 'البازار مفتوح' : 'البازار مغلق',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isOpen
                      ? 'يمكن للعملاء الطلب الآن'
                      : 'العملاء لا يمكنهم الطلب',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _isOpen ? Iconsax.unlock : Iconsax.lock,
            color: _isOpen ? AppColors.success : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'حالة البازار',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'اضغط للتبديل بين مفتوح/مغلق',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isOpen,
            onChanged: (value) => setState(() => _isOpen = value),
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildVacationSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.calendar_1, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'إعدادات الإجازة',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // End date
          InkWell(
            onTap: _selectEndDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.calendar, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Text(
                    _vacationEndDate != null
                        ? 'تاريخ العودة: ${DateFormat('dd MMMM yyyy', 'ar').format(_vacationEndDate!)}'
                        : 'اختر تاريخ العودة (اختياري)',
                    style: TextStyle(
                      color: _vacationEndDate != null
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (_vacationEndDate != null)
                    IconButton(
                      icon: const Icon(Iconsax.close_circle, size: 20),
                      onPressed: () => setState(() => _vacationEndDate = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Vacation message
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'رسالة للعملاء',
              hintText: 'مثال: سنعود قريباً! نحن في إجازة قصيرة...',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Iconsax.message_text),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.eye, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'معاينة ما سيراه العملاء',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isOpen
                  ? AppColors.success.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isOpen
                    ? AppColors.success.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isOpen ? Iconsax.shop : Iconsax.info_circle,
                      color: _isOpen ? AppColors.success : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isOpen ? 'متاح للطلب' : 'مغلق مؤقتاً',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _isOpen ? AppColors.success : Colors.orange,
                      ),
                    ),
                  ],
                ),
                if (!_isOpen && _messageController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _messageController.text,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
                if (!_isOpen && _vacationEndDate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'نعود في: ${DateFormat('dd MMMM', 'ar').format(_vacationEndDate!)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
