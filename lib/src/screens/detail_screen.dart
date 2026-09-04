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

  const DetailScreen({
    super.key,
    required this.mangaId,
    required this.title,
    required this.source,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailParams = DetailParams(source: source, mangaId: mangaId);
    final detail = ref.watch(mangaDetailProvider(detailParams));
    final isBmAsync = ref.watch(isBookmarkedProvider(detailParams));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
                  title: currentDetail?.title ?? title,
                  thumbnail: currentDetail?.thumbnail ?? '',
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
