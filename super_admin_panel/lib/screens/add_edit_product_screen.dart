import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import '../core/constants/colors.dart';
import '../providers/admin_data_provider.dart';
import '../models/product_model.dart';
import '../models/bazaar_model.dart';
import '../services/product_service.dart';

/// شاشة إضافة/تعديل منتج - Super Admin
class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();

  bool get isEditing => widget.product != null;

  // Form Controllers
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _descriptionArController = TextEditingController();
  final _descriptionEnController = TextEditingController();
  final _priceController = TextEditingController();
  final _oldPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _weightController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _materialController = TextEditingController();

  // Form State
  String _selectedCategory = 'أخرى';
  String? _selectedBazaarId;
  String _selectedBazaarName = '';
  bool _isNew = false;
  bool _isFeatured = false;
  bool _isInStock = true;
  bool _isActive = true;
  List<String> _selectedSizes = [];
  List<String> _galleryImages = [];

  // Upload State
  bool _isUploading = false;
  bool _isSaving = false;
  Uint8List? _selectedImageBytes;
  String? _selectedFileName;

  final List<String> _categories = [
    'تماثيل',
    'مجوهرات',
    'ملابس تقليدية',
    'أواني',
    'لوحات',
    'هدايا تذكارية',
    'بردي',
    'أخرى',
  ];

  final List<String> _availableSizes = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'صغير',
    'متوسط',
    'كبير',
  ];

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _populateForm();
    }
    _stockController.text = '100';
  }

  void _populateForm() {
    final p = widget.product!;
    _nameArController.text = p.nameAr;
    _nameEnController.text = p.nameEn;
    _descriptionArController.text = p.descriptionAr;
    _descriptionEnController.text = p.descriptionEn;
    _priceController.text = p.price.toString();
    _oldPriceController.text = p.oldPrice?.toString() ?? '';
    _stockController.text = p.stockQuantity.toString();
    _imageUrlController.text = p.imageUrl;
    _weightController.text = p.weight ?? '';
    _dimensionsController.text = p.dimensions ?? '';
    _materialController.text = p.material ?? '';

    // Ensure category exists in the list, if not add it
    if (!_categories.contains(p.category)) {
      _categories.insert(
          _categories.length - 1, p.category); // Add before "أخرى"
    }
    _selectedCategory = p.category;

    _selectedBazaarId = p.bazaarId;
    _selectedBazaarName = p.bazaarName;
    _isNew = p.isNew;
    _isFeatured = p.isFeatured;
    _isInStock = p.isInStock;
    _isActive = p.isActive;
    _selectedSizes = List.from(p.sizes);
    _galleryImages = List.from(p.galleryImages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل المنتج' : 'إضافة منتج جديد'),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_right_3),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isEditing && widget.product!.isActive != _isActive)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isActive
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isActive ? 'سيتم التفعيل' : 'سيتم الإيقاف',
                style: TextStyle(
                  fontSize: 12,
                  color: _isActive ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Form
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Info Section
                    _buildSectionCard(
                      title: 'المعلومات الأساسية',
                      icon: Iconsax.info_circle,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _nameArController,
                                label: 'اسم المنتج (عربي) *',
                                hint: 'مثال: تمثال أبو الهول',
                                validator: (v) =>
                                    v!.isEmpty ? 'هذا الحقل مطلوب' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _nameEnController,
                                label: 'اسم المنتج (إنجليزي)',
                                hint: 'Example: Sphinx Statue',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionArController,
                          label: 'الوصف (عربي) *',
                          hint: 'وصف تفصيلي للمنتج...',
                          maxLines: 4,
                          validator: (v) =>
                              v!.isEmpty ? 'هذا الحقل مطلوب' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionEnController,
                          label: 'الوصف (إنجليزي)',
                          hint: 'Detailed product description...',
                          maxLines: 4,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Pricing Section
                    _buildSectionCard(
                      title: 'التسعير والمخزون',
                      icon: Iconsax.money,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _priceController,
                                label: 'السعر (ج.م) *',
                                hint: '0',
                                keyboardType: TextInputType.number,
                                prefixIcon: Iconsax.money_2,
                                validator: (v) {
                                  if (v!.isEmpty) return 'هذا الحقل مطلوب';
                                  if (double.tryParse(v) == null) {
                                    return 'أدخل رقم صحيح';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _oldPriceController,
                                label: 'السعر القديم (للخصم)',
                                hint: 'اختياري',
                                keyboardType: TextInputType.number,
                                prefixIcon: Iconsax.discount_shape,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _stockController,
                                label: 'كمية المخزون',
                                hint: '100',
                                keyboardType: TextInputType.number,
                                prefixIcon: Iconsax.box_1,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSwitchTile(
                                title: 'متوفر في المخزون',
                                value: _isInStock,
                                onChanged: (v) =>
                                    setState(() => _isInStock = v),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Classification Section
                    _buildSectionCard(
                      title: 'التصنيف',
                      icon: Iconsax.category,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField(
                                label: 'الفئة *',
                                value: _selectedCategory,
                                items: _categories,
                                onChanged: (v) =>
                                    setState(() => _selectedCategory = v!),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Consumer<AdminDataProvider>(
                                builder: (context, provider, _) {
                                  return _buildBazaarDropdown(provider);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSizesSelector(),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Additional Details Section
                    _buildSectionCard(
                      title: 'تفاصيل إضافية',
                      icon: Iconsax.note_2,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _weightController,
                                label: 'الوزن',
                                hint: 'مثال: 500 جرام',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _dimensionsController,
                                label: 'الأبعاد',
                                hint: 'مثال: 20×10×5 سم',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _materialController,
                          label: 'المادة/الخامة',
                          hint: 'مثال: نحاس، خشب، حجر',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Flags Section
                    _buildSectionCard(
                      title: 'خيارات العرض',
                      icon: Iconsax.flag,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSwitchTile(
                                title: 'منتج جديد',
                                subtitle: 'يظهر شارة "جديد"',
                                value: _isNew,
                                onChanged: (v) => setState(() => _isNew = v),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSwitchTile(
                                title: 'منتج مميز',
                                subtitle: 'يظهر في القسم المميز',
                                value: _isFeatured,
                                onChanged: (v) =>
                                    setState(() => _isFeatured = v),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSwitchTile(
                                title: 'نشط',
                                subtitle: 'يظهر للعملاء',
                                value: _isActive,
                                onChanged: (v) => setState(() => _isActive = v),
                                activeColor: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Image & Gallery Sidebar
          Expanded(
            flex: 0,
            child: Container(
              width: 400,
              margin: const EdgeInsets.only(top: 24, left: 24, bottom: 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Image Section
                    _buildSectionCard(
                      title: 'الصورة الرئيسية',
                      icon: Iconsax.image,
                      children: [
                        _buildImageUploader(),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _imageUrlController,
                          label: 'رابط الصورة',
                          hint: 'https://...',
                          prefixIcon: Iconsax.link,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Gallery Section
                    _buildSectionCard(
                      title: 'معرض الصور',
                      icon: Iconsax.gallery,
                      children: [
                        _buildGallerySection(),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveProduct,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : Icon(isEditing ? Iconsax.edit : Iconsax.add),
                        label: Text(
                          _isSaving
                              ? 'جاري الحفظ...'
                              : (isEditing ? 'حفظ التغييرات' : 'إضافة المنتج'),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? prefixIcon,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBazaarDropdown(AdminDataProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'البازار *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: _selectedBazaarId == null
                ? Border.all(color: AppColors.error.withOpacity(0.5))
                : null,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedBazaarId,
              isExpanded: true,
              hint: const Text('اختر البازار'),
              items: provider.allBazaars.map((bazaar) {
                return DropdownMenuItem(
                  value: bazaar.id,
                  child: Text(bazaar.nameAr),
                );
              }).toList(),
              onChanged: (value) {
                final bazaar = provider.allBazaars.firstWhere(
                  (b) => b.id == value,
                );
                setState(() {
                  _selectedBazaarId = value;
                  _selectedBazaarName = bazaar.nameAr;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSizesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المقاسات المتاحة',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableSizes.map((size) {
            final isSelected = _selectedSizes.contains(size);
            return FilterChip(
              label: Text(size),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSizes.add(size);
                  } else {
                    _selectedSizes.remove(size);
                  }
                });
              },
              selectedColor: AppColors.primary,
              checkmarkColor: AppColors.white,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.white : AppColors.textPrimary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required void Function(bool) onChanged,
    Color activeColor = AppColors.primary,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploader() {
    return Column(
      children: [
        // Image Preview
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: _selectedImageBytes != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _selectedImageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedImageBytes = null;
                            _selectedFileName = null;
                          });
                        },
                        icon: const Icon(Icons.close, color: AppColors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                )
              : _imageUrlController.text.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: _imageUrlController.text,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(
                            Iconsax.image,
                            size: 48,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Iconsax.image,
                        size: 48,
                        color: AppColors.textHint,
                      ),
                    ),
        ),
        const SizedBox(height: 16),

        // Upload Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : _pickImage,
            icon: _isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Iconsax.gallery_add),
            label: Text(_isUploading ? 'جاري الرفع...' : 'اختيار صورة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGallerySection() {
    return Column(
      children: [
        // Add Gallery Image Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addGalleryImage,
            icon: const Icon(Iconsax.add_circle),
            label: const Text('إضافة صورة للمعرض'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Gallery Grid
        if (_galleryImages.isNotEmpty)
          SizedBox(
            height: 200,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _galleryImages.length,
              itemBuilder: (context, index) {
                final imageUrl = _galleryImages[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (_, __) => Container(
                          color: AppColors.background,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.background,
                          child: const Icon(Iconsax.image),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _galleryImages.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        else
          SizedBox(
            height: 100,
            child: const Center(
              child: Text(
                'لا توجد صور في المعرض',
                style: TextStyle(color: AppColors.textHint),
              ),
            ),
          ),
      ],
    );
  }

  // ============ Actions ============

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedImageBytes = result.files.single.bytes;
          _selectedFileName = result.files.single.name;
        });

        // Upload to Cloudinary
        await _uploadToCloudinary();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في اختيار الصورة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _uploadToCloudinary() async {
    if (_selectedImageBytes == null) return;

    setState(() => _isUploading = true);

    try {
      final imageUrl = await _productService.uploadImageToCloudinary(
        _selectedImageBytes!,
        _selectedFileName ?? 'product_image.jpg',
      );

      if (imageUrl != null) {
        setState(() {
          _imageUrlController.text = imageUrl;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم رفع الصورة بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل رفع الصورة - تأكد من إعدادات Cloudinary'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في رفع الصورة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isUploading = false);
  }

  Future<void> _addGalleryImage() async {
    final urlController = TextEditingController();

    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة صورة للمعرض'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'رابط الصورة',
            hintText: 'https://...',
            prefixIcon: Icon(Iconsax.link),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, urlController.text),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (url != null && url.isNotEmpty) {
      setState(() {
        _galleryImages.add(url);
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBazaarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار البازار'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_imageUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إضافة صورة للمنتج'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<AdminDataProvider>();

      final productData = Product(
        id: widget.product?.id ?? '',
        nameAr: _nameArController.text.trim(),
        nameEn: _nameEnController.text.trim(),
        descriptionAr: _descriptionArController.text.trim(),
        descriptionEn: _descriptionEnController.text.trim(),
        price: double.parse(_priceController.text),
        oldPrice: _oldPriceController.text.isNotEmpty
            ? double.parse(_oldPriceController.text)
            : null,
        imageUrl: _imageUrlController.text.trim(),
        galleryImages: _galleryImages,
        sizes: _selectedSizes,
        weight: _weightController.text.isNotEmpty
            ? _weightController.text.trim()
            : null,
        dimensions: _dimensionsController.text.isNotEmpty
            ? _dimensionsController.text.trim()
            : null,
        material: _materialController.text.isNotEmpty
            ? _materialController.text.trim()
            : null,
        category: _selectedCategory,
        bazaarId: _selectedBazaarId!,
        bazaarName: _selectedBazaarName,
        isNew: _isNew,
        isFeatured: _isFeatured,
        isInStock: _isInStock,
        isActive: _isActive,
        stockQuantity: int.tryParse(_stockController.text) ?? 100,
        rating: widget.product?.rating ?? 0.0,
        reviewCount: widget.product?.reviewCount ?? 0,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
      );

      bool success;
      if (isEditing) {
        success = await provider.updateProduct(
          widget.product!.id,
          productData.toJson(),
        );
      } else {
        success = await provider.createProduct(productData);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'تم تحديث المنتج بنجاح' : 'تم إضافة المنتج بنجاح',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء الحفظ'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _descriptionArController.dispose();
    _descriptionEnController.dispose();
    _priceController.dispose();
    _oldPriceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    _materialController.dispose();
    super.dispose();
  }
}
