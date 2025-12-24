import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;
  final bool isNetwork;
  final String? title;

  const FullScreenImageViewer({
    super.key,
    required this.imagePath,
    this.isNetwork = true,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title ?? 'ดูรูปภาพ', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: imagePath,
            child: _buildImage(),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (isNetwork) {
      return Image.network(
        imagePath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        },
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.imageOff, color: Colors.white, size: 48),
              SizedBox(height: 16),
              Text('ไม่สามารถโหลดรูปภาพได้', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    } else {
      if (kIsWeb) {
        // Fallback for web if someone tries to use file path
        return const Center(
          child: Text('Web ไม่รองรับการแสดงผลจาก File Path', style: TextStyle(color: Colors.white)),
        );
      }
      return Image.file(
        File(imagePath),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.imageOff, color: Colors.white, size: 48),
              SizedBox(height: 16),
              Text('ไฟล์รูปภาพไม่ถูกต้อง', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }
  }
}
