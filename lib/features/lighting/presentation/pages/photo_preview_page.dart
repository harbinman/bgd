import 'package:flutter/material.dart';
import 'dart:io';

/// 照片预览页面
class PhotoPreviewPage extends StatelessWidget {
  final String photoPath;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const PhotoPreviewPage({
    super.key,
    required this.photoPath,
    this.onShare,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (onShare != null)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: onShare,
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: onDelete,
            ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(photoPath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
