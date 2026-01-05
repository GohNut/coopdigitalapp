import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Error types for image saving operations
enum ImageSaveError {
  /// Permission denied to access photo library/gallery
  permissionDenied,
  
  /// Network connection error (for web/server-side generation)
  networkError,
  
  /// File system error (e.g., disk full, write error)
  fileSystemError,
  
  /// Unknown or unclassified error
  unknownError,
}

/// Exception thrown when image saving fails
class ImageSaveException implements Exception {
  final ImageSaveError errorType;
  final String message;
  
  ImageSaveException(this.errorType, this.message);
  
  @override
  String toString() => 'ImageSaveException: $message (type: $errorType)';
}

/// Helper to get user-friendly error details
class ImageSaveErrorDetails {
  final String title;
  final String description;
  final String suggestion;
  final IconData icon;
  
  ImageSaveErrorDetails({
    required this.title,
    required this.description,
    required this.suggestion,
    required this.icon,
  });
  
  /// Get error details based on error type
  static ImageSaveErrorDetails fromException(ImageSaveException exception) {
    switch (exception.errorType) {
      case ImageSaveError.permissionDenied:
        return ImageSaveErrorDetails(
          title: 'ไม่สามารถเข้าถึงอัลบั้มรูปได้',
          description: 'แอปไม่ได้รับอนุญาตให้บันทึกรูปภาพลงในอัลบั้มของคุณ',
          suggestion: 'กรุณาไปที่การตั้งค่าเครื่อง → แอปนี้ → เปิดการอนุญาต "รูปภาพ" หรือ "สื่อ"',
          icon: Icons.lock_outline,
        );
      
      case ImageSaveError.networkError:
        return ImageSaveErrorDetails(
          title: 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้',
          description: 'การบันทึกรูปภาพต้องการการเชื่อมต่ออินเทอร์เน็ต',
          suggestion: 'กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ตของคุณ แล้วลองใหม่อีกครั้ง',
          icon: Icons.wifi_off,
        );
      
      case ImageSaveError.fileSystemError:
        return ImageSaveErrorDetails(
          title: 'พื้นที่จัดเก็บไม่เพียงพอ',
          description: 'เครื่องของคุณมีพื้นที่เหลือน้อยเกินไป ไม่สามารถบันทึกรูปภาพได้',
          suggestion: 'กรุณาลบไฟล์ที่ไม่จำเป็นออกเพื่อเพิ่มพื้นที่ว่าง แล้วลองใหม่อีกครั้ง',
          icon: Icons.storage,
        );
      
      case ImageSaveError.unknownError:
        return ImageSaveErrorDetails(
          title: 'เกิดข้อผิดพลาด',
          description: exception.message.isNotEmpty 
            ? exception.message 
            : 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ',
          suggestion: 'กรุณาลองใหม่อีกครั้ง หรือติดต่อเจ้าหน้าที่หากปัญหายังคงอยู่',
          icon: Icons.error_outline,
        );
    }
  }
}

/// Show error dialog when image saving fails
Future<bool?> showImageSaveErrorDialog(
  BuildContext context,
  ImageSaveException exception,
) async {
  final details = ImageSaveErrorDetails.fromException(exception);
  
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              details.icon,
              color: Colors.red.shade600,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          Text(
            details.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          // Description
          Text(
            details.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Suggestion (with light background)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    details.suggestion,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade900,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Close button
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'ปิด',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        
        // Retry button
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'ลองใหม่',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
