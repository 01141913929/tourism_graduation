import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../core/constants/colors.dart';
import '../models/category_model.dart';
import '../services/product_service.dart';

/// شاشة إدارة الفئات
class CategoriesManagementScreen extends StatefulWidget {
  const CategoriesManagementScreen({super.key});

  @override
  State<CategoriesManagementScreen> createState() =>
      _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState
    extends State<CategoriesManagementScreen> {
  final ProductService _productService = ProductService();
  List<Category> _categories = [];
  Map<String, int> _productCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _categories = await _productService.getAllCategories();
      _productCounts = await _productService.getProductCountByCategory();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Categories List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _categories.isEmpty
                    ? _buildEmptyState()
                    : _buildCategoriesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.white,
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📁 إدارة الفئات',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'إدارة فئات المنتجات في المنصة',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Iconsax.refresh, size: 18),
            label: const Text('تحديث'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showCategoryDialog(),
            icon: const Icon(Iconsax.add, size: 18),
            label: const Text('إضافة فئة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.category,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد فئات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ابدأ بإضافة فئة جديدة',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCategoryDialog(),
            icon: const Icon(Iconsax.add),
            label: const Text('إضافة فئة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _categories.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryCard(category, index);
      },
    );
  }

  Widget _buildCategoryCard(Category category, int index) {
    final productCount = _productCounts[category.nameAr] ?? 0;

    return Container(
      key: ValueKey(category.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Icon(
                Iconsax.menu_1,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  category.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          category.nameAr,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category.nameEn.isNotEmpty)
              Text(
                category.nameEn,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              '$productCount منتج',
              style: TextStyle(
                color:
                    productCount > 0 ? AppColors.primary : AppColors.textHint,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: category.isActive
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category.isActive ? 'نشط' : 'معطل',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      category.isActive ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Edit
            IconButton(
              icon: const Icon(Iconsax.edit_2, size: 20),
              onPressed: () => _showCategoryDialog(category: category),
              color: AppColors.primary,
              tooltip: 'تعديل',
            ),
            // Delete
            IconButton(
              icon: const Icon(Iconsax.trash, size: 20),
              onPressed: productCount > 0
                  ? () => _showDeleteWarning(category, productCount)
                  : () => _deleteCategory(category),
              color: AppColors.error,
              tooltip: 'حذف',
            ),
          ],
        ),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, item);
    });

    // Update order in Firestore
    for (int i = 0; i < _categories.length; i++) {
      await _productService.updateCategory(
        _categories[i].id,
        {'order': i},
      );
    }
  }

  void _showCategoryDialog({Category? category}) {
    final isEditing = category != null;
    final nameArController =
        TextEditingController(text: category?.nameAr ?? '');
    final nameEnController =
        TextEditingController(text: category?.nameEn ?? '');
    String selectedIcon = category?.icon ?? '📦';
    bool isActive = category?.isActive ?? true;

    final icons = [
      '📦',
      '🗿',
      '💍',
      '👘',
      '🏺',
      '🖼️',
      '🎁',
      '📜',
      '🎨',
      '⚱️',
      '🪔',
      '🪭',
      '🎭',
      '🪬',
      '📿',
      '👑',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'تعديل الفئة' : 'إضافة فئة جديدة'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Selector
                const Text(
                  'الأيقونة',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: icons.map((icon) {
                    final isSelected = icon == selectedIcon;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => selectedIcon = icon);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.2)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: AppColors.primary, width: 2)
                              : null,
                        ),
                        child: Center(
                          child:
                              Text(icon, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Name AR
                TextField(
                  controller: nameArController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفئة (عربي) *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Name EN
                TextField(
                  controller: nameEnController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الفئة (إنجليزي)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Is Active
                SwitchListTile(
                  title: const Text('نشط'),
                  subtitle: const Text('يظهر للمستخدمين'),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameArController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال اسم الفئة')),
                  );
                  return;
                }

                Navigator.pop(context);

                if (isEditing) {
                  await _productService.updateCategory(category.id, {
                    'nameAr': nameArController.text,
                    'nameEn': nameEnController.text,
                    'icon': selectedIcon,
                    'isActive': isActive,
                  });
                } else {
                  await _productService.createCategory(
                    Category(
                      id: '',
                      nameAr: nameArController.text,
                      nameEn: nameEnController.text,
                      icon: selectedIcon,
                      order: _categories.length,
                      isActive: isActive,
                      createdAt: DateTime.now(),
                    ),
                  );
                }

                _loadData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(isEditing ? 'حفظ' : 'إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteWarning(Category category, int productCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ تحذير'),
        content: Text(
          'هذه الفئة تحتوي على $productCount منتج. حذفها سيؤثر على هذه المنتجات.\n\nهل أنت متأكد من الاستمرار؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(category);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    final success = await _productService.deleteCategory(category.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'تم حذف الفئة' : 'حدث خطأ'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      if (success) _loadData();
    }
  }
}
