import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mangareader_flutter/src/providers/app_providers.dart';
import 'package:mangareader_flutter/src/rust/api.dart' as rust_api;
import 'package:mangareader_flutter/src/screens/reader_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Membaca'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus Semua Riwayat',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hapus Riwayat'),
                  content: const Text('Yakin ingin menghapus seluruh riwayat membaca?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await rust_api.clearHistory();
                ref.invalidate(historyProvider);
              }
            },
          ),
        ],
      ),
      body: historyAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada riwayat membaca.'),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: item.thumbnail.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: item.thumbnail,
                          width: 44,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.book, size: 40),
                title: Text(item.mangaTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${item.chapterTitle} • ${item.source.name.toUpperCase()}'),
                trailing: const Icon(Icons.play_arrow),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReaderScreen(
                        chapterPath: item.chapterPath,
                        chapterTitle: item.chapterTitle,
                        source: item.source,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
