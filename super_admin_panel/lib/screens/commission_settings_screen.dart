import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import '../core/constants/colors.dart';

/// شاشة إعدادات العمولات
class CommissionSettingsScreen extends StatefulWidget {
  const CommissionSettingsScreen({super.key});

  @override
  State<CommissionSettingsScreen> createState() =>
      _CommissionSettingsScreenState();
}

class _CommissionSettingsScreenState extends State<CommissionSettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double _defaultCommission = 10.0;
  Map<String, double> _categoryCommissions = {};
  Map<String, Map<String, dynamic>> _bazaarCommissions = {};
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _bazaars = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load settings
      final settingsDoc =
          await _firestore.collection('settings').doc('commissions').get();
      if (settingsDoc.exists) {
        final data = settingsDoc.data()!;
        _defaultCommission = (data['defaultRate'] as num?)?.toDouble() ?? 10.0;
        _categoryCommissions = Map<String, double>.from(
          (data['categories'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, (v as num).toDouble()),
              ) ??
              {},
        );
        _bazaarCommissions = {};
        final bazaarRates = data['bazaars'] as Map<String, dynamic>? ?? {};
        bazaarRates.forEach((key, value) {
          _bazaarCommissions[key] = Map<String, dynamic>.from(value as Map);
        });
      }

      // Load categories
      final categoriesSnapshot =
          await _firestore.collection('categories').get();
      _categories = categoriesSnapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();

      // Load bazaars
      final bazaarsSnapshot = await _firestore
          .collection('bazaars')
          .where('isVerified', isEqualTo: true)
          .get();
      _bazaars = bazaarsSnapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await _firestore.collection('settings').doc('commissions').set({
        'defaultRate': _defaultCommission,
        'categories': _categoryCommissions,
        'bazaars': _bazaarCommissions,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ إعدادات العمولات'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showCategoryCommissionDialog(Map<String, dynamic> category) {
    final controller = TextEditingController(
      text: (_categoryCommissions[category['id']] ?? _defaultCommission)
          .toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('عمولة "${category['nameAr']}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'نسبة العمولة (%)',
                suffixText: '%',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'العمولة الافتراضية: $_defaultCommission%',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _categoryCommissions.remove(category['id']));
              Navigator.pop(context);
            },
            child: const Text('استخدام الافتراضي'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value >= 0 && value <= 100) {
                setState(() => _categoryCommissions[category['id']] = value);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showBazaarCommissionDialog(Map<String, dynamic> bazaar) {
    final rateController = TextEditingController(
      text: (_bazaarCommissions[bazaar['id']]?['rate'] ?? _defaultCommission)
          .toString(),
    );
    final noteController = TextEditingController(
      text: _bazaarCommissions[bazaar['id']]?['note'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('عمولة "${bazaar['nameAr']}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'نسبة العمولة (%)',
                suffixText: '%',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'ملاحظة (اختياري)',
                hintText: 'سبب التعديل...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _bazaarCommissions.remove(bazaar['id']));
              Navigator.pop(context);
            },
            child: const Text('استخدام الافتراضي'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(rateController.text);
              if (value != null && value >= 0 && value <= 100) {
                setState(() {
                  _bazaarCommissions[bazaar['id']] = {
                    'rate': value,
                    'note': noteController.text,
                    'updatedAt': DateTime.now().toIso8601String(),
                  };
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إعدادات العمولات'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Iconsax.tick_circle),
            label: const Text('حفظ'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Default commission
                  _buildSection(
                    title: 'العمولة الافتراضية',
                    icon: Iconsax.percentage_circle,
                    child: _buildDefaultCommissionCard(),
                  ),
                  const SizedBox(height: 24),

                  // Category commissions
                  _buildSection(
                    title: 'عمولات حسب الفئة',
                    icon: Iconsax.category,
                    child: _buildCategoryCommissions(),
                  ),
                  const SizedBox(height: 24),

                  // Bazaar commissions
                  _buildSection(
                    title: 'عمولات مخصصة للبازارات',
                    icon: Iconsax.shop,
                    child: _buildBazaarCommissions(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildDefaultCommissionCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.percentage_circle,
                  color: AppColors.primary, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'نسبة العمولة الافتراضية',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'تُطبق على جميع البازارات ما لم يُحدد غير ذلك',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 100,
              child: TextField(
                controller:
                    TextEditingController(text: _defaultCommission.toString()),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  suffixText: '%',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) {
                  final value = double.tryParse(v);
                  if (value != null) setState(() => _defaultCommission = value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCommissions() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          if (_categories.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('لا توجد فئات',
                  style: TextStyle(color: Colors.grey[600])),
            )
          else
            ...List.generate(_categories.length, (index) {
              final category = _categories[index];
              final hasCustomRate =
                  _categoryCommissions.containsKey(category['id']);
              final rate =
                  _categoryCommissions[category['id']] ?? _defaultCommission;

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasCustomRate
                        ? AppColors.secondary.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Iconsax.category,
                    color: hasCustomRate ? AppColors.secondary : Colors.grey,
                    size: 20,
                  ),
                ),
                title: Text(category['nameAr'] ?? 'فئة'),
                subtitle: hasCustomRate
                    ? const Text('عمولة مخصصة',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.secondary))
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$rate%',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color:
                            hasCustomRate ? AppColors.secondary : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Iconsax.edit_2, size: 18),
                      onPressed: () => _showCategoryCommissionDialog(category),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBazaarCommissions() {
    final customBazaars =
        _bazaars.where((b) => _bazaarCommissions.containsKey(b['id'])).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Add button
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Iconsax.add, color: AppColors.primary, size: 20),
            ),
            title: const Text('إضافة عمولة مخصصة'),
            onTap: () => _showSelectBazaarDialog(),
          ),
          if (customBazaars.isNotEmpty) const Divider(),

          // Custom bazaar commissions
          ...customBazaars.map((bazaar) {
            final commission = _bazaarCommissions[bazaar['id']]!;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.secondary.withOpacity(0.1),
                child: Text(
                  (bazaar['nameAr'] ?? 'B')[0],
                  style: const TextStyle(color: AppColors.secondary),
                ),
              ),
              title: Text(bazaar['nameAr'] ?? 'بازار'),
              subtitle: commission['note']?.isNotEmpty == true
                  ? Text(commission['note'],
                      style: const TextStyle(fontSize: 11))
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${commission['rate']}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.edit_2, size: 18),
                    onPressed: () => _showBazaarCommissionDialog(bazaar),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showSelectBazaarDialog() {
    final availableBazaars = _bazaars
        .where((b) => !_bazaarCommissions.containsKey(b['id']))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('اختر بازار'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: availableBazaars.isEmpty
              ? Center(
                  child: Text(
                    'جميع البازارات لديها عمولات مخصصة',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  itemCount: availableBazaars.length,
                  itemBuilder: (context, index) {
                    final bazaar = availableBazaars[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          (bazaar['nameAr'] ?? 'B')[0],
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ),
                      title: Text(bazaar['nameAr'] ?? 'بازار'),
                      onTap: () {
                        Navigator.pop(context);
                        _showBazaarCommissionDialog(bazaar);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }
}
