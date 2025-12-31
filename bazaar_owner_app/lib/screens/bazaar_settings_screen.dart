import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/colors.dart';
import '../core/constants/governorates.dart';
import '../providers/auth_provider.dart';
import '../core/services/image_picker_service.dart';

/// شاشة إعدادات البازار
class BazaarSettingsScreen extends StatefulWidget {
  const BazaarSettingsScreen({super.key});

  @override
  State<BazaarSettingsScreen> createState() => _BazaarSettingsScreenState();
}

class _BazaarSettingsScreenState extends State<BazaarSettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePickerService _imagePicker = ImagePickerService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameArController;
  late TextEditingController _nameEnController;
  late TextEditingController _descriptionArController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _workingHoursController;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isOpen = true;
  String? _bazaarId;
  String _selectedGovernorate = 'القاهرة'; // Default

  // Media
  File? _selectedMainImageFile;
  String? _currentMainImageUrl;

  List<File> _selectedGalleryFiles = [];
  List<String> _currentGalleryUrls = [];

  @override
  void initState() {
    super.initState();
    _nameArController = TextEditingController();
    _nameEnController = TextEditingController();
    _descriptionArController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _workingHoursController = TextEditingController();
    _loadBazaarData();
  }

  Future<void> _loadBazaarData() async {
    try {
      final authProvider = context.read<BazaarAuthProvider>();
      final bazaarId = authProvider.user?.bazaarId;

      if (bazaarId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final doc = await _firestore.collection('bazaars').doc(bazaarId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _bazaarId = bazaarId;

        _nameArController.text = data['nameAr'] ?? '';
        _nameEnController.text = data['nameEn'] ?? '';
        _descriptionArController.text = data['descriptionAr'] ?? '';
        _addressController.text = data['address'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _workingHoursController.text = data['workingHours'] ?? '';
        _isOpen = data['isOpen'] ?? true;

        _currentMainImageUrl = data['imageUrl'];

        if (data['galleryImages'] != null) {
          _currentGalleryUrls = List<String>.from(data['galleryImages']);
        }

        if (data['governorate'] != null &&
            EgyptianGovernorates.list.contains(data['governorate'])) {
          _selectedGovernorate = data['governorate'];
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading bazaar data: $e');
      setState(() => _isLoading = false);
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
        _currentGalleryUrls.removeAt(index);
      }
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate() || _bazaarId == null) return;

    setState(() => _isSaving = true);

    try {
      // 1. Upload Main Image if changed
      String mainImageUrl = _currentMainImageUrl ?? '';
      if (_selectedMainImageFile != null) {
        final url = await _imagePicker.uploadImage(
            _selectedMainImageFile!, 'bazaars/$_bazaarId/main');
        if (url != null) mainImageUrl = url;
      }

      // 2. Upload Gallery Images
      final newGalleryUrls = await _imagePicker.uploadImages(
          _selectedGalleryFiles, 'bazaars/$_bazaarId/gallery');

      final finalGalleryImages = [..._currentGalleryUrls, ...newGalleryUrls];

      await _firestore.collection('bazaars').doc(_bazaarId).update({
        'nameAr': _nameArController.text.trim(),
        'nameEn': _nameEnController.text.trim(),
        'descriptionAr': _descriptionArController.text.trim(),
        'address': _addressController.text.trim(),
        'governorate': _selectedGovernorate,
        'phone': _phoneController.text.trim(),
        'workingHours': _workingHoursController.text.trim(),
        'imageUrl': mainImageUrl,
        'galleryImages': finalGalleryImages,
        'isOpen': _isOpen,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Clear local selection after save
      setState(() {
        _selectedMainImageFile = null;
        _currentMainImageUrl = mainImageUrl;
        _selectedGalleryFiles.clear();
        _currentGalleryUrls = finalGalleryImages;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم حفظ الإعدادات بنجاح'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('إعدادات البازار'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveSettings,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('حفظ',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bazaarId == null
              ? _buildNoBazaarState()
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Status Toggle
                      _buildStatusCard(),
                      const SizedBox(height: 16),

                      // Image Selection
                      _buildSectionCard(
                          title: 'صورة الواجهة',
                          icon: Iconsax.image,
                          children: [
                            GestureDetector(
                              onTap: _pickMainImage,
                              child: Container(
                                height: 160,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey[300]!)),
                                child: _selectedMainImageFile != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                            _selectedMainImageFile!,
                                            fit: BoxFit.cover),
                                      )
                                    : _currentMainImageUrl != null &&
                                            _currentMainImageUrl!.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: CachedNetworkImage(
                                              imageUrl: _currentMainImageUrl!,
                                              fit: BoxFit.cover,
                                              placeholder: (c, u) => const Center(
                                                  child:
                                                      CircularProgressIndicator()),
                                              errorWidget: (c, u, e) =>
                                                  const Icon(Iconsax.image,
                                                      size: 40,
                                                      color: Colors.grey),
                                            ),
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Iconsax.gallery_add,
                                                  size: 40,
                                                  color: Colors.grey[400]),
                                              const SizedBox(height: 8),
                                              Text('اضغط لتغيير الصورة',
                                                  style: TextStyle(
                                                      color: Colors.grey[600])),
                                            ],
                                          ),
                              ),
                            )
                          ]),
                      const SizedBox(height: 16),

                      // Gallery
                      _buildSectionCard(
                          title: 'صور البازار',
                          icon: Iconsax.gallery,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ..._currentGalleryUrls.asMap().entries.map(
                                      (entry) => _buildThumbnail(
                                          imageUrl: entry.value,
                                          onRemove: () => _removeGalleryImage(
                                              entry.key,
                                              isLocal: false))),
                                  ..._selectedGalleryFiles.asMap().entries.map(
                                      (entry) => _buildThumbnail(
                                          file: entry.value,
                                          isLocal: true,
                                          onRemove: () => _removeGalleryImage(
                                              entry.key,
                                              isLocal: true))),
                                  GestureDetector(
                                    onTap: _pickGalleryImages,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      margin: const EdgeInsets.only(left: 8),
                                      decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.grey[300]!)),
                                      child: const Icon(Iconsax.add,
                                          color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ]),
                      const SizedBox(height: 16),

                      // Basic Info
                      _buildSectionCard(
                        title: 'المعلومات الأساسية',
                        icon: Iconsax.shop,
                        children: [
                          _buildTextField(_nameArController,
                              'اسم البازار (عربي)', Iconsax.text),
                          const SizedBox(height: 12),
                          _buildTextField(_nameEnController,
                              'اسم البازار (إنجليزي)', Iconsax.text),
                          const SizedBox(height: 12),
                          _buildTextField(_descriptionArController, 'الوصف',
                              Iconsax.note_text,
                              maxLines: 3),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Contact Info
                      _buildSectionCard(
                        title: 'معلومات التواصل',
                        icon: Iconsax.location,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedGovernorate,
                            decoration: InputDecoration(
                              labelText: 'المحافظة',
                              prefixIcon: const Icon(Iconsax.map, size: 20),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: EgyptianGovernorates.list
                                .map((g) =>
                                    DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedGovernorate = v!),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(_addressController,
                              'العنوان بالتفصيل', Iconsax.location),
                          const SizedBox(height: 12),
                          _buildTextField(
                              _phoneController, 'رقم الهاتف', Iconsax.call,
                              keyboardType: TextInputType.phone),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Working Hours
                      _buildSectionCard(
                        title: 'ساعات العمل',
                        icon: Iconsax.clock,
                        children: [
                          _buildTextField(_workingHoursController,
                              'مثال: 9:00 ص - 10:00 م', Iconsax.clock),
                        ],
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }

  Widget _buildThumbnail(
      {File? file,
      String? imageUrl,
      bool isLocal = false,
      required VoidCallback onRemove}) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
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
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 10, color: Colors.white),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildNoBazaarState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.shop_remove, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('لم يتم العثور على بازار',
              style: TextStyle(color: Colors.grey[600])),
        ],
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
              : [Colors.grey, Colors.grey.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isOpen ? AppColors.success : Colors.grey).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
            child: Icon(_isOpen ? Iconsax.shop : Iconsax.shop_remove,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOpen ? 'البازار مفتوح' : 'البازار مغلق',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  _isOpen
                      ? 'يمكن للعملاء رؤية منتجاتك وطلبها'
                      : 'لن تظهر المنتجات للعملاء',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9), fontSize: 13),
                ),
              ],
            ),
          ),
          Switch(
            value: _isOpen,
            onChanged: (value) => setState(() => _isOpen = value),
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withOpacity(0.4),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _descriptionArController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _workingHoursController.dispose();
    super.dispose();
  }
}
