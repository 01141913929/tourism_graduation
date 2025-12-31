import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';
import '../services/media_service.dart';

/// شاشة معرض صور البازار
class ImageGalleryScreen extends StatefulWidget {
  final String? productId;
  final String productName;
  final List<String> initialImages;
  final Function(List<String>) onImagesChanged;

  const ImageGalleryScreen({
    super.key,
    this.productId,
    required this.productName,
    required this.initialImages,
    required this.onImagesChanged,
  });

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  final MediaService _mediaService = MediaService();

  List<String> _images = [];
  bool _isLoading = false;
  double _uploadProgress = 0;
  String? _uploadingMessage;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages);
  }

  Future<void> _addImages() async {
    final images = await _mediaService.pickMultipleImages(quality: 80);
    if (images.isEmpty) return;

    final authProvider = context.read<BazaarAuthProvider>();
    final bazaarId = authProvider.user?.bazaarId;

    if (bazaarId == null) return;

    setState(() {
      _isLoading = true;
      _uploadingMessage = 'جاري رفع ${images.length} صورة...';
    });

    try {
      for (var i = 0; i < images.length; i++) {
        setState(() {
          _uploadingMessage = 'جاري رفع الصورة ${i + 1} من ${images.length}...';
          _uploadProgress = (i / images.length);
        });

        final url = await _mediaService.uploadProductImage(
          bazaarId: bazaarId,
          productId: widget.productId ??
              'temp_${DateTime.now().millisecondsSinceEpoch}',
          imageFile: images[i],
        );

        _images.add(url);
      }

      widget.onImagesChanged(_images);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم رفع ${images.length} صورة بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في رفع الصور: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
      _uploadingMessage = null;
      _uploadProgress = 0;
    });
  }

  Future<void> _deleteImage(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف الصورة', textAlign: TextAlign.center),
        content: const Text('هل أنت متأكد من حذف هذه الصورة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _mediaService.deleteImageByUrl(_images[index]);
      _images.removeAt(index);
      widget.onImagesChanged(_images);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف الصورة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _viewImage(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(
          images: _images,
          initialIndex: index,
          productName: widget.productName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('صور ${widget.productName}'),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_forward_ios, size: 20),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _addImages,
            icon: const Icon(Iconsax.add),
            label: const Text('إضافة'),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_images.isEmpty)
            Center(
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
                      Iconsax.gallery,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'لا توجد صور',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اضغط على "إضافة" لرفع صور للمنتج',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _addImages,
                    icon: const Icon(Iconsax.gallery_add),
                    label: const Text('إضافة صور'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _images.length,
              itemBuilder: (context, index) => _buildImageCard(index),
            ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_uploadProgress > 0)
                        CircularProgressIndicator(value: _uploadProgress)
                      else
                        const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _uploadingMessage ?? 'جاري التحميل...',
                        style: const TextStyle(fontWeight: FontWeight.w600),
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

  Widget _buildImageCard(int index) {
    return GestureDetector(
      onTap: () => _viewImage(index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.softShadow,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: _images[index],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.background,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.background,
                  child: const Icon(Iconsax.image,
                      size: 48, color: AppColors.textHint),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: () => _deleteImage(index),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Iconsax.trash,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
            if (index == 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'رئيسية',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 11,
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
}

/// Full screen image viewer with swipe
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String productName;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
    required this.productName,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.images[index],
                fit: BoxFit.contain,
                placeholder: (_, __) => const CircularProgressIndicator(),
                errorWidget: (_, __, ___) => const Icon(
                  Iconsax.image,
                  size: 64,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
