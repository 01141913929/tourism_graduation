import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

/// Service for managing images with compression and organized storage
class MediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Storage folder structure
  static const String _bazaarImagesFolder = 'bazaars';
  static const String _productImagesFolder = 'products';
  static const String _userAvatarsFolder = 'avatars';
  static const String _galleryFolder = 'gallery';

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery({int quality = 70}) async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: quality,
    );
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera({int quality = 70}) async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: quality,
    );
  }

  /// Pick multiple images from gallery
  Future<List<XFile>> pickMultipleImages({int quality = 70}) async {
    return await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: quality,
    );
  }

  /// Upload bazaar image
  Future<String> uploadBazaarImage({
    required String bazaarId,
    required XFile imageFile,
    bool isMain = false,
  }) async {
    final fileName = isMain
        ? 'main_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}'
        : 'gallery_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

    final ref =
        _storage.ref().child('$_bazaarImagesFolder/$bazaarId/$fileName');
    return await _uploadFile(ref, imageFile);
  }

  /// Upload product image
  Future<String> uploadProductImage({
    required String bazaarId,
    required String productId,
    required XFile imageFile,
    bool isMain = false,
  }) async {
    final fileName = isMain
        ? 'main_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}'
        : 'gallery_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

    final ref = _storage
        .ref()
        .child('$_productImagesFolder/$bazaarId/$productId/$fileName');
    return await _uploadFile(ref, imageFile);
  }

  /// Upload multiple product gallery images
  Future<List<String>> uploadProductGallery({
    required String bazaarId,
    required String productId,
    required List<XFile> images,
  }) async {
    final urls = <String>[];

    for (var i = 0; i < images.length; i++) {
      final fileName =
          'gallery_${i}_${DateTime.now().millisecondsSinceEpoch}${path.extension(images[i].path)}';
      final ref = _storage.ref().child(
          '$_productImagesFolder/$bazaarId/$productId/$_galleryFolder/$fileName');
      final url = await _uploadFile(ref, images[i]);
      urls.add(url);
    }

    return urls;
  }

  /// Upload user avatar
  Future<String> uploadUserAvatar({
    required String userId,
    required XFile imageFile,
  }) async {
    final fileName =
        'avatar_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
    final ref = _storage.ref().child('$_userAvatarsFolder/$userId/$fileName');
    return await _uploadFile(ref, imageFile);
  }

  /// Generic file upload with progress tracking
  Future<String> _uploadFile(Reference ref, XFile imageFile,
      {ValueChanged<double>? onProgress}) async {
    final bytes = await imageFile.readAsBytes();
    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(
        contentType:
            'image/${path.extension(imageFile.path).replaceFirst('.', '')}',
      ),
    );

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload with progress callback
  Future<String> uploadWithProgress({
    required String folder,
    required String subfolder,
    required XFile imageFile,
    required ValueChanged<double> onProgress,
  }) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
    final ref = _storage.ref().child('$folder/$subfolder/$fileName');
    return await _uploadFile(ref, imageFile, onProgress: onProgress);
  }

  /// Delete image by URL
  Future<void> deleteImageByUrl(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting image: $e');
      rethrow;
    }
  }

  /// Delete multiple images
  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      try {
        await deleteImageByUrl(url);
      } catch (e) {
        debugPrint('Error deleting image $url: $e');
      }
    }
  }

  /// Delete all images in a folder
  Future<void> deleteFolder(String folderPath) async {
    try {
      final ref = _storage.ref().child(folderPath);
      final result = await ref.listAll();

      for (var item in result.items) {
        await item.delete();
      }

      for (var prefix in result.prefixes) {
        await deleteFolder(prefix.fullPath);
      }
    } catch (e) {
      debugPrint('Error deleting folder $folderPath: $e');
    }
  }

  /// Delete all product images
  Future<void> deleteProductImages(String bazaarId, String productId) async {
    await deleteFolder('$_productImagesFolder/$bazaarId/$productId');
  }

  /// Delete all bazaar images
  Future<void> deleteBazaarImages(String bazaarId) async {
    await deleteFolder('$_bazaarImagesFolder/$bazaarId');
  }

  /// Get all images in a folder
  Future<List<String>> getImagesInFolder(String folderPath) async {
    try {
      final ref = _storage.ref().child(folderPath);
      final result = await ref.listAll();

      final urls = <String>[];
      for (var item in result.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      debugPrint('Error getting images: $e');
      return [];
    }
  }

  /// Get product gallery images
  Future<List<String>> getProductGallery(
      String bazaarId, String productId) async {
    return await getImagesInFolder(
        '$_productImagesFolder/$bazaarId/$productId/$_galleryFolder');
  }

  /// Get bazaar gallery images
  Future<List<String>> getBazaarGallery(String bazaarId) async {
    return await getImagesInFolder(
        '$_bazaarImagesFolder/$bazaarId/$_galleryFolder');
  }

  /// Get storage space usage (approximate)
  Future<int> getStorageUsage(String bazaarId) async {
    try {
      final ref = _storage.ref().child('$_bazaarImagesFolder/$bazaarId');
      final result = await ref.listAll();

      int totalSize = 0;
      for (var item in result.items) {
        final metadata = await item.getMetadata();
        totalSize += metadata.size ?? 0;
      }

      // Also check products
      final productsRef =
          _storage.ref().child('$_productImagesFolder/$bazaarId');
      try {
        final productsResult = await productsRef.listAll();
        for (var prefix in productsResult.prefixes) {
          final productItems = await prefix.listAll();
          for (var item in productItems.items) {
            final metadata = await item.getMetadata();
            totalSize += metadata.size ?? 0;
          }
        }
      } catch (_) {}

      return totalSize;
    } catch (e) {
      debugPrint('Error calculating storage: $e');
      return 0;
    }
  }

  /// Format bytes to human readable
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
