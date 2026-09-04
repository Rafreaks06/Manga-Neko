import 'package:flutter/material.dart';

class ReaderImageItem extends StatefulWidget {
  final String imageUrl;
  final int index;
  final int total;
  final String referer;

  const ReaderImageItem({
    super.key,
    required this.imageUrl,
    required this.index,
    required this.total,
    required this.referer,
  });

  @override
  State<ReaderImageItem> createState() => _ReaderImageItemState();
}

class _ReaderImageItemState extends State<ReaderImageItem> {
  int _retryKey = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Image.network(
          widget.imageUrl,
          key: ValueKey('${widget.imageUrl}_$_retryKey'),
          fit: BoxFit.fitWidth,
          headers: {
            'Referer': widget.referer,
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 350,
              color: Colors.black12,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Memuat Halaman ${widget.index + 1}/${widget.total}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
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
                    'Gagal memuat Halaman ${widget.index + 1}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _retryKey++;
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Coba Lagi', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
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
              '${widget.index + 1}/${widget.total}',
              style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
