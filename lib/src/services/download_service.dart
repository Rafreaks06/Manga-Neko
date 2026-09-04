import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:mangareader_flutter/src/rust/api.dart' as rust_api;
import 'package:mangareader_flutter/src/rust/api/models.dart';

class DownloadService {
  static Future<void> downloadChapter({
    required MangaSource source,
    required String mangaId,
    required String mangaTitle,
    required String chapterTitle,
    required String chapterPath,
    required String thumbnail,
    required void Function(double progress) onProgress,
  }) async {
    final pagesData = await rust_api.getChapterPages(source: source, chapterPath: chapterPath);
    final images = pagesData.images;
    if (images.isEmpty) {
      throw Exception('Chapter tidak memiliki gambar');
    }

    final docDir = await getApplicationDocumentsDirectory();
    final sanitizedMangaId = mangaId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final sanitizedChapter = chapterPath.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final chapterDir = Directory(p.join(docDir.path, 'downloads', source.name, sanitizedMangaId, sanitizedChapter));

    if (!await chapterDir.exists()) {
      await chapterDir.create(recursive: true);
    }

    final referer = source == MangaSource.komiku ? 'https://komiku.org/' : 'https://komikindo.ch/';
    final client = http.Client();
    int downloadedCount = 0;

    try {
      for (int i = 0; i < images.length; i++) {
        final imgUrl = images[i];
        final ext = p.extension(Uri.parse(imgUrl).path);
        final fileExt = ext.isNotEmpty ? ext : '.jpg';
        final fileName = '${i.toString().padLeft(3, '0')}$fileExt';
        final targetFile = File(p.join(chapterDir.path, fileName));

        if (await targetFile.exists() && await targetFile.length() > 0) {
          downloadedCount++;
        } else {
          final resp = await client.get(
            Uri.parse(imgUrl),
            headers: {
              'Referer': referer,
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            },
          );
          if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
            await targetFile.writeAsBytes(resp.bodyBytes);
            downloadedCount++;
          } else {
            debugPrint('Failed to download image $imgUrl (status ${resp.statusCode})');
          }
        }
        onProgress((i + 1) / images.length);
      }

      if (downloadedCount == 0) {
        throw Exception('Gagal mengunduh gambar chapter (semua file gagal diunduh)');
      }

      final downloadedChapter = DownloadedChapter(
        chapterId: chapterPath,
        mangaId: mangaId,
        source: source,
        mangaTitle: mangaTitle,
        chapterTitle: chapterTitle,
        chapterPath: chapterPath,
        thumbnail: thumbnail,
        localDir: chapterDir.path,
        pageCount: downloadedCount,
        downloadedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      await rust_api.saveDownloadedChapter(chapter: downloadedChapter);
    } finally {
      client.close();
    }
  }

  static Future<void> deleteDownload({
    required MangaSource source,
    required String chapterPath,
  }) async {
    final localDir = await rust_api.deleteDownloadedChapter(source: source, chapterId: chapterPath);
    if (localDir.isNotEmpty) {
      final dir = Directory(localDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
  }
}
