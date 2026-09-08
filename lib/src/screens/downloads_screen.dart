import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mangareader_flutter/src/providers/app_providers.dart';
import 'package:mangareader_flutter/src/rust/api/models.dart';
import 'package:mangareader_flutter/src/screens/offline_reader_screen.dart';
import 'package:mangareader_flutter/src/services/download_service.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsAsync = ref.watch(downloadedChaptersProvider);
    final downloadState = ref.watch(downloadManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unduhan Offline'),
      ),
      body: downloadsAsync.when(
        data: (items) {
          if (items.isEmpty && downloadState.downloadingIds.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_for_offline_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada chapter yang diunduh untuk dibaca offline.'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              final isDownloading = downloadState.downloadingIds.contains(item.chapterPath);
              final progress = downloadState.progressMap[item.chapterPath] ?? 0.0;

              return ListTile(
                leading: item.thumbnail.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: item.thumbnail,
                          width: 44,
                          height: 60,
                          fit: BoxFit.cover,
                          httpHeaders: {
                            'Referer': item.source == MangaSource.komikindo ? 'https://komikindo.ch/' : 'https://komiku.org/',
                            'User-Agent':
                                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                          },
                          errorWidget: (context, url, error) => const Icon(Icons.book, size: 40),
                        ),
                      )
                    : const Icon(Icons.book, size: 40),
                title: Text(item.mangaTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${item.chapterTitle} • ${item.source.name.toUpperCase()}'),
                    if (isDownloading) ...[
                      const SizedBox(height: 4),
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 2),
                      Text('Mengunduh ${(progress * 100).toInt()}%',
                          style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.primary)),
                    ] else
                      Text('${item.pageCount} Halaman tersimpan',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: 'Hapus Unduhan',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Hapus Unduhan?'),
                        content: Text('Yakin ingin menghapus ${item.chapterTitle}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await DownloadService.deleteDownload(
                        source: item.source,
                        chapterPath: item.chapterPath,
                      );
                      ref.invalidate(downloadedChaptersProvider);
                    }
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OfflineReaderScreen(
                        chapter: item,
                        allChapters: items,
                        currentIndex: index,
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
