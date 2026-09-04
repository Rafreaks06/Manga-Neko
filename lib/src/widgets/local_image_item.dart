import 'dart:io';
import 'package:flutter/material.dart';

class LocalImageItem extends StatelessWidget {
  final String localPath;
  final int index;
  final int total;

  const LocalImageItem({
    super.key,
    required this.localPath,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(localPath);

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Image.file(
          file,
          width: double.infinity,
          fit: BoxFit.fitWidth,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 220,
            color: Colors.black26,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.broken_image, size: 36, color: Colors.grey),
                  const SizedBox(height: 6),
                  Text(
                    'Gagal memuat: ${file.path.split('/').last}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${index + 1}/$total',
              style: const TextStyle(
                  fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

