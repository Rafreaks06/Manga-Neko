import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mangareader_flutter/src/providers/app_providers.dart';
import 'package:mangareader_flutter/src/rust/api/models.dart';
import 'package:mangareader_flutter/src/screens/detail_screen.dart';

class MangaCard extends ConsumerWidget {
  final MangaSummary item;

  const MangaCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        final currentSource = ref.read(currentSourceProvider);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailScreen(
              mangaId: item.id,
              title: item.title,
              source: currentSource,
            ),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.thumbnail.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: item.thumbnail,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.black12),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                    )
                  else
                    Container(color: Colors.black26, child: const Icon(Icons.book)),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.typeName,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.latestChapter.isEmpty ? 'Baca' : item.latestChapter,
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
