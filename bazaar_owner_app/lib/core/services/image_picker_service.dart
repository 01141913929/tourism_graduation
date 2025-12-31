import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  // Cloudinary Config
  static const String _cloudName = 'dlkpme30u';
  static const String _uploadPreset = 'tourism';

  /// Pick a single image
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Pick multiple images
  Future<List<File>> pickMultiImage() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return images.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return [];
    }
  }

  /// Upload image to Cloudinary and return URL
  /// [path] parameter is kept for backward compatibility but unused in Cloudinary (uses folders in preset if configured)
  Future<String?> uploadImage(File file, String path) async {
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
        debugPrint('Cloudinary upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading image to Cloudinary: $e');
      return null;
    }
  }

  /// Upload multiple images
  Future<List<String>> uploadImages(List<File> files, String folderPath) async {
    final List<String> urls = [];
    for (final file in files) {
      final url = await uploadImage(file, folderPath);
      if (url != null) {
        urls.add(url);
      }
    }
    return urls;
  }
}
