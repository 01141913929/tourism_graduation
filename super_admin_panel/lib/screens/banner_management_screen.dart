import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';

/// شاشة إدارة البانرات والمحتوى الإعلاني
class BannerManagementScreen extends StatefulWidget {
  const BannerManagementScreen({super.key});

  @override
  State<BannerManagementScreen> createState() => _BannerManagementScreenState();
}

class _BannerManagementScreenState extends State<BannerManagementScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  List<Map<String, dynamic>> _banners = [];
  List<Map<String, dynamic>> _featuredProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load banners
      final bannersSnapshot =
          await _firestore.collection('banners').orderBy('order').get();

      _banners = bannersSnapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();

      // Load featured products
      final featuredSnapshot = await _firestore
          .collection('products')
          .where('isFeatured', isEqualTo: true)
          .limit(20)
          .get();

      _featuredProducts = featuredSnapshot.docs
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

  void _showAddBannerDialog() {
    final titleController = TextEditingController();
    final imageUrlController = TextEditingController();
    final linkController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    bool isActive = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Iconsax.image, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('إضافة بانر جديد'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'عنوان البانر',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'رابط الصورة',
                      hintText: 'https://...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: linkController,
                    decoration: InputDecoration(
                      labelText: 'رابط الإجراء (اختياري)',
                      hintText: 'رابط المنتج أو الصفحة',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dates row
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker(
                          label: 'تاريخ البداية',
                          date: startDate,
                          onSelect: (d) => setDialogState(() => startDate = d),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDatePicker(
                          label: 'تاريخ النهاية',
                          date: endDate,
                          onSelect: (d) => setDialogState(() => endDate = d),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    value: isActive,
                    onChanged: (v) => setDialogState(() => isActive = v),
                    title: const Text('نشط'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    imageUrlController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى ملء الحقول المطلوبة')),
                  );
                  return;
                }
                Navigator.pop(context);
                await _addBanner(
                  title: titleController.text,
                  imageUrl: imageUrlController.text,
                  link: linkController.text,
                  startDate: startDate,
                  endDate: endDate,
                  isActive: isActive,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    DateTime? date,
    required Function(DateTime) onSelect,
  }) {
    return InkWell(
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (selected != null) onSelect(selected);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Iconsax.calendar, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              date != null ? DateFormat('dd/MM').format(date) : label,
              style: TextStyle(
                color: date != null ? Colors.black87 : Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addBanner({
    required String title,
    required String imageUrl,
    String? link,
    DateTime? startDate,
    DateTime? endDate,
    required bool isActive,
  }) async {
    try {
      await _firestore.collection('banners').add({
        'title': title,
        'imageUrl': imageUrl,
        'link': link,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'isActive': isActive,
        'order': _banners.length,
        'createdAt': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تمت إضافة البانر'),
            backgroundColor: AppColors.success),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _toggleBanner(String id, bool isActive) async {
    try {
      await _firestore
          .collection('banners')
          .doc(id)
          .update({'isActive': isActive});
      _loadData();
    } catch (e) {
      debugPrint('Error toggling banner: $e');
    }
  }

  Future<void> _deleteBanner(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف البانر'),
        content: const Text('هل أنت متأكد من حذف هذا البانر؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestore.collection('banners').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم حذف البانر'), backgroundColor: AppColors.success),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _toggleFeaturedProduct(String id, bool isFeatured) async {
    try {
      await _firestore
          .collection('products')
          .doc(id)
          .update({'isFeatured': isFeatured});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFeatured ? 'تم تمييز المنتج' : 'تم إلغاء التمييز'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadData();
    } catch (e) {
      debugPrint('Error toggling featured: $e');
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
        title: const Text('إدارة المحتوى الإعلاني'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Iconsax.refresh), onPressed: _loadData),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Iconsax.gallery, size: 18),
              const SizedBox(width: 6),
              Text('البانرات (${_banners.length})'),
            ])),
            Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Iconsax.star, size: 18),
              const SizedBox(width: 6),
              Text('منتجات مميزة (${_featuredProducts.length})'),
            ])),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBannerDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: const Text('بانر جديد', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBannersTab(),
                _buildFeaturedProductsTab(),
              ],
            ),
    );
  }

  Widget _buildBannersTab() {
    if (_banners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.gallery, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('لا توجد بانرات', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _banners.length,
      onReorder: _reorderBanners,
      itemBuilder: (context, index) {
        final banner = _banners[index];
        return _buildBannerCard(banner, key: ValueKey(banner['id']));
      },
    );
  }

  Future<void> _reorderBanners(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final item = _banners.removeAt(oldIndex);
    _banners.insert(newIndex, item);
    setState(() {});

    // Update order in Firestore
    final batch = _firestore.batch();
    for (int i = 0; i < _banners.length; i++) {
      batch.update(
        _firestore.collection('banners').doc(_banners[i]['id']),
        {'order': i},
      );
    }
    await batch.commit();
  }

  Widget _buildBannerCard(Map<String, dynamic> banner, {required Key key}) {
    final isActive = banner['isActive'] ?? false;

    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Drag handle
            const Icon(Iconsax.menu, color: Colors.grey),
            const SizedBox(width: 12),

            // Banner image preview
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: banner['imageUrl'] != null
                  ? Image.network(
                      banner['imageUrl'],
                      width: 100,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner['title'] ?? 'بانر',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (banner['endDate'] != null)
                    Text(
                      'ينتهي: ${DateFormat('dd/MM').format(DateTime.parse(banner['endDate']))}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),

            // Toggle
            Switch(
              value: isActive,
              onChanged: (v) => _toggleBanner(banner['id'], v),
              activeColor: AppColors.success,
            ),

            // Delete
            IconButton(
              icon: const Icon(Iconsax.trash, color: AppColors.error),
              onPressed: () => _deleteBanner(banner['id']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 100,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Iconsax.image, color: Colors.grey[400]),
    );
  }

  Widget _buildFeaturedProductsTab() {
    if (_featuredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.star, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('لا توجد منتجات مميزة',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              'يمكنك تمييز المنتجات من شاشة إدارة المنتجات',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _featuredProducts.length,
      itemBuilder: (context, index) {
        final product = _featuredProducts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product['imageUrl'] != null
                  ? Image.network(product['imageUrl'],
                      width: 60, height: 60, fit: BoxFit.cover)
                  : _buildPlaceholder(),
            ),
            title: Text(product['nameAr'] ?? 'منتج',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${(product['price'] ?? 0).toStringAsFixed(0)} ج.م'),
            trailing: IconButton(
              icon: const Icon(Iconsax.star_slash, color: AppColors.warning),
              onPressed: () => _toggleFeaturedProduct(product['id'], false),
              tooltip: 'إلغاء التمييز',
            ),
          ),
        );
      },
    );
  }
}
