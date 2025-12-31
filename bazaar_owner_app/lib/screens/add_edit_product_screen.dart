import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';
import '../core/services/image_picker_service.dart';

// Alias for convenience
typedef BazaarColors = AppColors;

/// شاشة إضافة أو تعديل منتج
class AddEditProductScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _imagePicker = ImagePickerService();

  late TextEditingController _nameArController;
  late TextEditingController _nameEnController;
  late TextEditingController _descriptionArController;
  late TextEditingController _descriptionEnController;
  late TextEditingController _priceController;
  late TextEditingController _oldPriceController;
  late TextEditingController _weightController;
  late TextEditingController _dimensionsController;
  late TextEditingController _materialController;
  late TextEditingController _stockQuantityController;

  String _selectedCategory = 'تماثيل';
  List<String> _selectedSizes = [];
  bool _isNew = false;
  bool _isFeatured = false;
  bool _isInStock = true;
  bool _isLoading = false;

  // Media handling
  File? _selectedMainImageFile;
  String? _currentMainImageUrl;

  List<File> _selectedGalleryFiles = [];
  List<String> _currentGalleryUrls = [];
  List<String> _galleryUrlsToDelete = [];

  bool get isEditing => widget.product != null;

  final List<String> _categories = [
    'تماثيل',
    'مجوهرات',
    'ملابس تقليدية',
    'أواني',
    'لوحات',
    'هدايا تذكارية',
    'أخرى',
  ];

  final List<String> _allSizes = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'صغير',
    'وسط',
    'كبير',
    'مقاس واحد'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameArController = TextEditingController(text: p?['nameAr'] ?? '');
    _nameEnController = TextEditingController(text: p?['nameEn'] ?? '');
    _descriptionArController =
        TextEditingController(text: p?['descriptionAr'] ?? '');
    _descriptionEnController =
        TextEditingController(text: p?['descriptionEn'] ?? '');
    _priceController =
        TextEditingController(text: p?['price']?.toString() ?? '');
    _oldPriceController =
        TextEditingController(text: p?['oldPrice']?.toString() ?? '');

    // New fields
    _weightController = TextEditingController(text: p?['weight'] ?? '');
    _dimensionsController = TextEditingController(text: p?['dimensions'] ?? '');
    _materialController = TextEditingController(text: p?['material'] ?? '');
    _stockQuantityController = TextEditingController(
        text: p?['stockQuantity']?.toString() ?? '100');

    if (p != null) {
      _selectedCategory = p['category'] ?? 'تماثيل';
      _selectedSizes = List<String>.from(p['sizes'] ?? []);
      _isNew = p['isNew'] ?? false;
      _isFeatured = p['isFeatured'] ?? false;
      _isInStock = p['isInStock'] ?? true;
      _currentMainImageUrl = p['imageUrl'];
      _currentGalleryUrls = List<String>.from(p['galleryImages'] ?? []);
    }
  }

  Future<void> _pickMainImage() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _selectedMainImageFile = file;
      });
    }
  }

  Future<void> _pickGalleryImages() async {
    final files = await _imagePicker.pickMultiImage();
    if (files.isNotEmpty) {
      setState(() {
        _selectedGalleryFiles.addAll(files);
      });
    }
  }

  void _removeGalleryImage(int index, {bool isLocal = false}) {
    setState(() {
      if (isLocal) {
        _selectedGalleryFiles.removeAt(index);
      } else {
        final url = _currentGalleryUrls[index];
        _currentGalleryUrls.removeAt(index);
        _galleryUrlsToDelete.add(url);
      }
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMainImageFile == null && _currentMainImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى اختيار صورة رئيسية للمنتج'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = context.read<BazaarAuthProvider>();
      final bazaarId = auth.user?.bazaarId;
      if (bazaarId == null) throw Exception('لم يتم العثور على البازار');

      // Upload main image if changed
      String mainImageUrl = _currentMainImageUrl ?? '';
      if (_selectedMainImageFile != null) {
        final url = await _imagePicker.uploadImage(
            _selectedMainImageFile!, 'products/$bazaarId');
        if (url == null) throw Exception('فشل رفع الصورة الرئيسية');
        mainImageUrl = url;
      }

      // Upload new gallery images
      final newGalleryUrls = await _imagePicker.uploadImages(
          _selectedGalleryFiles, 'products/$bazaarId/gallery');

      final finalGalleryImages = [..._currentGalleryUrls, ...newGalleryUrls];

      final data = {
        'nameAr': _nameArController.text.trim(),
        'nameEn': _nameEnController.text.trim(),
        'descriptionAr': _descriptionArController.text.trim(),
        'descriptionEn': _descriptionEnController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0,
        'oldPrice': _oldPriceController.text.isNotEmpty
            ? double.tryParse(_oldPriceController.text)
            : null,
        'imageUrl': mainImageUrl,
        'galleryImages': finalGalleryImages,
        'category': _selectedCategory,
        'sizes': _selectedSizes,
        'weight': _weightController.text.trim(),
        'dimensions': _dimensionsController.text.trim(),
        'material': _materialController.text.trim(),
        'bazaarId': bazaarId,
        'bazaarName': auth.user?.name ?? '',
        'isNew': _isNew,
        'isFeatured': _isFeatured,
        'stockQuantity': int.tryParse(_stockQuantityController.text) ?? 100,
        'isInStock': _isInStock,
        'isActive': true,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (isEditing) {
        await _firestore
            .collection('products')
            .doc(widget.product!['id'])
            .update(data);
      } else {
        data['createdAt'] = DateTime.now().toIso8601String();
        data['rating'] = 0.0;
        data['reviewCount'] = 0;
        await _firestore.collection('products').add(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isEditing ? 'تم التحديث' : 'تم الإضافة'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل المنتج' : 'إضافة منتج'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Main Image
            _buildCard(
                'صورة المنتج الرئيسية',
                Iconsax.image,
                Column(
                  children: [
                    GestureDetector(
                      onTap: _pickMainImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!)),
                        child: _selectedMainImageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_selectedMainImageFile!,
                                    fit: BoxFit.cover),
                              )
                            : _currentMainImageUrl != null &&
                                    _currentMainImageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: _currentMainImageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (c, u) => const Center(
                                          child: CircularProgressIndicator()),
                                      errorWidget: (c, u, e) => const Icon(
                                          Iconsax.image,
                                          size: 50,
                                          color: Colors.grey),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Iconsax.gallery_add,
                                          size: 48, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text('اضغط لإضافة صورة',
                                          style: TextStyle(
                                              color: Colors.grey[600])),
                                    ],
                                  ),
                      ),
                    ),
                  ],
                )),
            const SizedBox(height: 16),

            // Gallery
            _buildCard(
                'معرض الصور',
                Iconsax.gallery,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Existing URL Images
                          ..._currentGalleryUrls.asMap().entries.map((entry) {
                            return _buildThumbnail(
                              isLocal: false,
                              imageUrl: entry.value,
                              onRemove: () => _removeGalleryImage(entry.key,
                                  isLocal: false),
                            );
                          }),
                          // New Local Images
                          ..._selectedGalleryFiles.asMap().entries.map((entry) {
                            return _buildThumbnail(
                              isLocal: true,
                              file: entry.value,
                              onRemove: () =>
                                  _removeGalleryImage(entry.key, isLocal: true),
                            );
                          }),
                          // Add Button
                          GestureDetector(
                            onTap: _pickGalleryImages,
                            child: Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!)),
                              child: const Icon(Iconsax.add,
                                  size: 32, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )),
            const SizedBox(height: 16),

            // Basic Info
            _buildCard(
                'المعلومات الأساسية',
                Iconsax.document_text,
                Column(children: [
                  TextFormField(
                      controller: _nameArController,
                      decoration: _inputDeco('اسم المنتج (عربي)', Iconsax.text),
                      validator: (v) => v?.isEmpty == true ? 'مطلوب' : null),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _nameEnController,
                      decoration:
                          _inputDeco('اسم المنتج (إنجليزي)', Iconsax.text)),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _descriptionArController,
                      maxLines: 3,
                      decoration: _inputDeco('الوصف (عربي)', Iconsax.note_text),
                      validator: (v) => v?.isEmpty == true ? 'مطلوب' : null),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _descriptionEnController,
                      maxLines: 3,
                      decoration:
                          _inputDeco('الوصف (إنجليزي)', Iconsax.note_text)),
                ])),
            const SizedBox(height: 16),

            // Category & Price
            _buildCard(
                'التصنيف والسعر',
                Iconsax.category,
                Column(children: [
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                    decoration: _inputDeco('الفئة', Iconsax.element_3),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDeco('السعر', Iconsax.money),
                            validator: (v) =>
                                v?.isEmpty == true ? 'مطلوب' : null)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: TextFormField(
                            controller: _oldPriceController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDeco(
                                'السعر القديم', Iconsax.discount_circle))),
                  ]),
                ])),
            const SizedBox(height: 16),

            // Product Details (New)
            _buildCard(
                'تفاصيل المنتج',
                Iconsax.info_circle,
                Column(
                  children: [
                    TextFormField(
                      controller: _weightController,
                      decoration:
                          _inputDeco('الوزن (مثال: 1 كجم)', Iconsax.weight),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dimensionsController,
                      decoration:
                          _inputDeco('الأبعاد (مثال: 20x30 سم)', Iconsax.ruler),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _materialController,
                      decoration:
                          _inputDeco('الخامة (مثال: نحاس)', Iconsax.layer),
                    ),
                  ],
                )),
            const SizedBox(height: 16),

            // Sizes
            _buildCard(
                'المقاسات المتاحة',
                Iconsax.ruler,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allSizes
                      .map((s) => FilterChip(
                            label: Text(s),
                            selected: _selectedSizes.contains(s),
                            onSelected: (sel) => setState(() => sel
                                ? _selectedSizes.add(s)
                                : _selectedSizes.remove(s)),
                            selectedColor:
                                BazaarColors.primary.withOpacity(0.2),
                          ))
                      .toList(),
                )),
            const SizedBox(height: 16),

            // Options
            _buildCard(
                'خيارات إضافية',
                Iconsax.setting_2,
                Column(children: [
                  SwitchListTile(
                      title: const Text('منتج جديد'),
                      subtitle: const Text('سيظهر في قسم "وصل حديثاً"'),
                      value: _isNew,
                      onChanged: (v) => setState(() => _isNew = v),
                      activeColor: BazaarColors.primary),
                  SwitchListTile(
                      title: const Text('منتج مميز'),
                      subtitle: const Text('سيظهر في الصفحة الرئيسية'),
                      value: _isFeatured,
                      onChanged: (v) => setState(() => _isFeatured = v),
                      activeColor: BazaarColors.primary),
                ])),
            const SizedBox(height: 16),

            // Stock Management
            _buildCard(
                'إدارة المخزون',
                Iconsax.box,
                Column(children: [
                  TextFormField(
                    controller: _stockQuantityController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco('الكمية المتاحة', Iconsax.box_1),
                    validator: (v) {
                      if (v?.isEmpty == true) return 'مطلوب';
                      final qty = int.tryParse(v!);
                      if (qty == null || qty < 0) return 'أدخل رقم صحيح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                      title: const Text('متوفر في المخزون'),
                      subtitle: const Text('إذا كان غير متوفر لن يظهر للشراء'),
                      value: _isInStock,
                      onChanged: (v) => setState(() => _isInStock = v),
                      activeColor: BazaarColors.primary),
                ])),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ]),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveProduct,
          style: ElevatedButton.styleFrom(
              backgroundColor: BazaarColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          child: _isLoading
              ? const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2)
              : Text(isEditing ? 'حفظ التغييرات' : 'إضافة المنتج',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildThumbnail(
      {bool isLocal = false,
      File? file,
      String? imageUrl,
      required VoidCallback onRemove}) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isLocal
                ? Image.file(file!, fit: BoxFit.cover)
                : CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (c, u) => Container(color: Colors.grey[100]),
                  ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(String title, IconData icon, Widget child) => Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Icon(icon, color: BazaarColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ])),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ]),
      );

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      );

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _descriptionArController.dispose();
    _descriptionEnController.dispose();
    _priceController.dispose();
    _oldPriceController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    _materialController.dispose();
    _stockQuantityController.dispose();
    super.dispose();
  }
}
