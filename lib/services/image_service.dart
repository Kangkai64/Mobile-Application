import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../config/supabase_config.dart';

class ImageService {
  static const String _bucketName = SupabaseConfig.storageBucket;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Compress image to reduce file size to less than 1MB
  Future<File> compressImage(File imageFile, {int maxSizeKB = 1000}) async {
    try {
      // Read the image
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate target dimensions to achieve desired file size
      int quality = 85;
      int targetWidth = image.width;
      int targetHeight = image.height;
      
      // Start with original dimensions and reduce if needed
      while (true) {
        final resizedImage = img.copyResize(
          image,
          width: targetWidth,
          height: targetHeight,
        );
        
        final compressedBytes = img.encodeJpg(resizedImage, quality: quality);
        final sizeKB = compressedBytes.length / 1024;
        
        if (sizeKB <= maxSizeKB || quality <= 20) {
          // Save compressed image to temporary file
          final tempDir = await getTemporaryDirectory();
          final compressedFile = File(path.join(
            tempDir.path,
            'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg'
          ));
          
          await compressedFile.writeAsBytes(compressedBytes);
          return compressedFile;
        }
        
        // Reduce quality and dimensions for next iteration
        if (quality > 20) {
          quality -= 10;
        } else {
          targetWidth = (targetWidth * 0.8).round();
          targetHeight = (targetHeight * 0.8).round();
          quality = 85; // Reset quality when reducing dimensions
        }
        
        // Prevent infinite loop
        if (targetWidth < 100 || targetHeight < 100) {
          break;
        }
      }
      
      // If we get here, use the last attempt
      final resizedImage = img.copyResize(image, width: targetWidth, height: targetHeight);
      final compressedBytes = img.encodeJpg(resizedImage, quality: quality);
      
      final tempDir = await getTemporaryDirectory();
      final compressedFile = File(path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg'
      ));
      
      await compressedFile.writeAsBytes(compressedBytes);
      return compressedFile;
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }

  /// Upload image to Supabase bucket
  Future<String> uploadImage(File imageFile, String folder) async {
    try {
      // Compress the image first
      final compressedFile = await compressImage(imageFile);
      
      // Generate unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(compressedFile.path)}';
      final filePath = '$folder/$fileName';
      
      // Read compressed file bytes
      final bytes = await compressedFile.readAsBytes();
      
      // Upload to Supabase Storage
      await _supabase.storage
          .from(_bucketName)
          .uploadBinary(filePath, bytes);
      
      // Get public URL
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(filePath);
      
      // Clean up temporary file
      await compressedFile.delete();
      
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload profile image
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    return await uploadImage(imageFile, 'profiles/$userId');
  }

  /// Upload work order image
  Future<String> uploadWorkOrderImage(File imageFile, String workOrderId) async {
    return await uploadImage(imageFile, 'work-orders/$workOrderId');
  }

  /// Upload general workshop image
  Future<String> uploadWorkshopImage(File imageFile) async {
    return await uploadImage(imageFile, 'workshop');
  }

  /// Delete image from Supabase bucket
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the bucket name and file path
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        throw Exception('Invalid image URL');
      }
      
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      
      await _supabase.storage
          .from(_bucketName)
          .remove([filePath]);
      
      return true;
    } catch (e) {
      print('Failed to delete image: $e');
      return false;
    }
  }

  /// Get image size in KB
  Future<double> getImageSizeKB(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return bytes.length / 1024;
  }

  /// Check if image needs compression (larger than 1MB)
  Future<bool> needsCompression(File imageFile) async {
    final sizeKB = await getImageSizeKB(imageFile);
    return sizeKB > 1000; // 1MB = 1000KB
  }
}
