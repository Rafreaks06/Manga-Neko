import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mangareader_flutter/src/providers/app_providers.dart';
import 'package:mangareader_flutter/src/rust/api.dart' as rust_api;
import 'package:mangareader_flutter/src/rust/api/models.dart';
import 'package:mangareader_flutter/src/screens/reader_screen.dart';

class DetailScreen extends ConsumerWidget {
  final String mangaId;
  final String title;
  final MangaSource source;
  final String? thumbnail;

  const DetailScreen({
    super.key,
    required this.mangaId,
    required this.title,
    required this.source,
    this.thumbnail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailParams = DetailParams(source: source, mangaId: mangaId);
    final detail = ref.watch(mangaDetailProvider(detailParams));
    final isBmAsync = ref.watch(isBookmarkedProvider(detailParams));

    final effectiveThumbnail = detail.value?.thumbnail ?? thumbnail ?? '';
    final effectiveTitle = detail.value?.title ?? title;

    return Scaffold(
      appBar: AppBar(
        title: Text(effectiveTitle),
        actions: [
          IconButton(
            icon: Icon(
              isBmAsync.value == true ? Icons.bookmark : Icons.bookmark_border,
              color: isBmAsync.value == true ? Colors.amber : null,
            ),
            onPressed: () async {
              final isBm = isBmAsync.value ?? false;
              if (isBm) {
                await rust_api.removeBookmark(source: source, mangaId: mangaId);
              } else {
                final currentDetail = detail.value;
                await rust_api.addBookmark(
                  source: source,
                  mangaId: mangaId,
                  title: currentDetail?.title ?? effectiveTitle,
                  thumbnail: currentDetail?.thumbnail ?? effectiveThumbnail,
                );
              }
              ref.invalidate(isBookmarkedProvider(detailParams));
              ref.invalidate(bookmarksProvider);
            },
          ),
        ],
      ),
      body: detail.when(
        data: (data) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data.thumbnail.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: data.thumbnail,
                                width: 110,
                                height: 160,
                                fit: BoxFit.cover,
                                httpHeaders: {
                                  'Referer': source == MangaSource.komikindo ? 'https://komikindo.ch/' : 'https://komiku.org/',
                                  'User-Agent':
                                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                                },
                              ),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.title,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                if (data.author.isNotEmpty)
                                  Text('Author: ${data.author}', style: const TextStyle(fontSize: 12)),
                                if (data.status.isNotEmpty)
                                  Text('Status: ${data.status}', style: const TextStyle(fontSize: 12)),
                                if (data.rating.isNotEmpty)
                                  Text('Rating: ${data.rating}', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: data.genres
                            .map((g) => Chip(
                                  label: Text(g, style: const TextStyle(fontSize: 11)),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text('Sinopsis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(data.synopsis, style: const TextStyle(fontSize: 13, height: 1.4)),
                      const Divider(height: 32),
                      Text(
                        'Daftar Chapter (${data.chapters.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ch = data.chapters[index];

                    return ListTile(
                      title: Text(ch.title, style: const TextStyle(fontSize: 14)),
                      subtitle: ch.releaseDate.isNotEmpty
                          ? Text(ch.releaseDate, style: const TextStyle(fontSize: 11))
                          : null,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        rust_api.saveHistory(
                          source: source,
                          mangaId: mangaId,
                          mangaTitle: data.title,
                          chapterPath: ch.urlPath,
                          chapterTitle: ch.title,
                          thumbnail: data.thumbnail,
                          lastPage: 1,
                        ).then((_) {
                          ref.invalidate(historyProvider);
                        });

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReaderScreen(
                              mangaId: mangaId,
                              mangaTitle: data.title,
                              thumbnail: data.thumbnail,
                              chapters: data.chapters,
                              currentChapterIndex: index,
                              source: source,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  childCount: data.chapters.length,
                ),
              ),
            ],
          );
        },
        loading: () {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (effectiveThumbnail.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: effectiveThumbnail,
                                width: 110,
                                height: 160,
                                fit: BoxFit.cover,
                                httpHeaders: {
                                  'Referer': source == MangaSource.komikindo ? 'https://komikindo.ch/' : 'https://komiku.org/',
                                  'User-Agent':
                                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                                },
                              ),
                            )
                          else
                            Container(
                              width: 110,
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  effectiveTitle,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                const LinearProgressIndicator(),
                                const SizedBox(height: 8),
                                const Text('Memuat detail & chapter...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      const Text(
                        'Daftar Chapter',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return ListTile(
                      leading: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      title: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  },
                  childCount: 6,
                ),
              ),
            ],
          );
        },
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text('Gagal memuat detail manga: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(mangaDetailProvider(detailParams));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
