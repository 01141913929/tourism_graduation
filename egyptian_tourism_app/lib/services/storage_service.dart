import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service for handling file uploads via Cloudinary
class StorageService {
  // Cloudinary Config - Matching Owner App
  static const String _cloudName = 'dlkpme30u';
  static const String _uploadPreset = 'tourism';

  /// Upload a file and return the download URL
  /// [path] kept for compatibility but ignored by Cloudinary (uses preset folder)
  Future<String> uploadFile({
    required String path,
    required File file,
    String? contentType,
  }) async {
    try {
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'];
      } else {
        throw Exception('Cloudinary upload failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('فشل رفع الملف: $e');
    }
  }

  /// Upload user profile image
  Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    return uploadFile(
      path: 'users/$userId/profile.jpg', // Ignored by Cloudinary
      file: imageFile,
    );
  }

  /// Upload product image
  Future<String> uploadProductImage({
    required String productId,
    required File imageFile,
    required int index,
  }) async {
    return uploadFile(
      path: 'products/$productId/image_$index.jpg', // Ignored by Cloudinary
      file: imageFile,
    );
  }

  /// Get download URL (Stub for compatibility)
  /// Cloudinary URLs are public, so this just returns the path if it's already a URL
  Future<String> getDownloadUrl(String path) async {
    if (path.startsWith('http')) return path;
    throw Exception('Cloudinary requires full URLs');
  }

  /// Delete a file (Not implemented for unsigned clients)
  Future<void> deleteFile(String path) async {
    // Client-side delete is restricted for unsigned presets
    debugPrint('Delete skipped: Cloudinary unsigned preset limitation');
  }

  /// Delete file by URL (Not implemented for unsigned clients)
  Future<void> deleteFileByUrl(String url) async {
    // Client-side delete is restricted for unsigned presets
    debugPrint('Delete skipped: Cloudinary unsigned preset limitation');
  }

  /// Upload bytes (for web support)
  Future<String> uploadBytes({
    required String path,
    required List<int> bytes,
    String? contentType,
  }) async {
    try {
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(http.MultipartFile.fromBytes('file', bytes));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'];
      } else {
        throw Exception('Cloudinary upload failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('فشل رفع الملف: $e');
    }
  }
}
