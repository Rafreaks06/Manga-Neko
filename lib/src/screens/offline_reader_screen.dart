import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangareader_flutter/src/models/app_settings.dart';
import 'package:mangareader_flutter/src/providers/app_providers.dart';
import 'package:mangareader_flutter/src/rust/api.dart' as rust_api;
import 'package:mangareader_flutter/src/rust/api/models.dart';
import 'package:mangareader_flutter/src/widgets/local_image_item.dart';

class OfflineReaderScreen extends ConsumerStatefulWidget {
  final DownloadedChapter chapter;
  final List<DownloadedChapter> allChapters;
  final int currentIndex;

  const OfflineReaderScreen({
    super.key,
    required this.chapter,
    this.allChapters = const [],
    this.currentIndex = 0,
  });

  @override
  ConsumerState<OfflineReaderScreen> createState() => _OfflineReaderScreenState();
}

class _OfflineReaderScreenState extends ConsumerState<OfflineReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  late PageController _pageController;
  bool _showControls = true;
  late ReaderMode _readerMode;
  bool _isRTL = false;
  Color _backgroundColor = Colors.black;
  double _screenDim = 0.0;
  int _currentPageIndex = 0;
  List<String> _imageFiles = [];
  bool _isLoading = true;
  late int _chapterIndex;

  @override
  void initState() {
    super.initState();
    _chapterIndex = widget.currentIndex;
    _readerMode = ref.read(readerModeProvider);
    _pageController = PageController(initialPage: 0);
    _loadLocalImages();
  }

  DownloadedChapter get _currentChapter {
    if (widget.allChapters.isNotEmpty && _chapterIndex < widget.allChapters.length) {
      return widget.allChapters[_chapterIndex];
    }
    return widget.chapter;
  }

  Future<void> _loadLocalImages() async {
    setState(() {
      _isLoading = true;
      _imageFiles = [];
    });

    try {
      final ch = _currentChapter;
      final dir = Directory(ch.localDir);
      if (await dir.exists()) {
        final list = dir
            .listSync()
            .whereType<File>()
            .map((f) => f.path)
            .where((path) {
              final pLower = path.toLowerCase();
              return pLower.endsWith('.jpg') ||
                  pLower.endsWith('.jpeg') ||
                  pLower.endsWith('.png') ||
                  pLower.endsWith('.webp');
            })
            .toList();
        list.sort((a, b) => a.compareTo(b));
        setState(() {
          _imageFiles = list;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading local images: $e');
      setState(() {
        _isLoading = false;
      });
    }

    _recordCurrentHistory();
  }

  void _recordCurrentHistory() {
    final ch = _currentChapter;
    rust_api.saveHistory(
      source: ch.source,
      mangaId: ch.mangaId,
      mangaTitle: ch.mangaTitle,
      chapterPath: ch.chapterPath,
      chapterTitle: ch.chapterTitle,
      thumbnail: ch.thumbnail,
      lastPage: _currentPageIndex + 1,
    ).then((_) {
      ref.invalidate(historyProvider);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _showReaderSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Opsi Tampilan Reader (Offline)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(),
                    const Text('Mode Baca',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepOrange)),
                    const SizedBox(height: 8),
                    SegmentedButton<ReaderMode>(
                      segments: const [
                        ButtonSegment(
                          value: ReaderMode.continuousVertical,
                          label: Text('Vertical (Webtoon)'),
                          icon: Icon(Icons.swap_vert),
                        ),
                        ButtonSegment(
                          value: ReaderMode.pageFlipHorizontal,
                          label: Text('Horizontal (Slide)'),
                          icon: Icon(Icons.swap_horiz),
                        ),
                      ],
                      selected: {_readerMode},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _readerMode = newSelection.first;
                        });
                        setModalState(() {});
                      },
                    ),
                    if (_readerMode == ReaderMode.pageFlipHorizontal) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Arah Baca Kanan-ke-Kiri (Manga RTL)', style: TextStyle(fontSize: 13)),
                          Switch(
                            value: _isRTL,
                            onChanged: (val) {
                              setState(() {
                                _isRTL = val;
                              });
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text('Warna Latar Belakang',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepOrange)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildBgColorChoice(Colors.black, 'Hitam', setModalState),
                        const SizedBox(width: 8),
                        _buildBgColorChoice(const Color(0xFF1E1E1E), 'Abu Gelap', setModalState),
                        const SizedBox(width: 8),
                        _buildBgColorChoice(const Color(0xFFFBF0D9), 'Sepia', setModalState),
                        const SizedBox(width: 8),
                        _buildBgColorChoice(Colors.white, 'Putih', setModalState),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.brightness_medium, size: 18),
                        const SizedBox(width: 8),
                        const Text('Redupkan Layar (Night Filter)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                        const Spacer(),
                        Text('${(_screenDim * 100).toInt()}%',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    Slider(
                      value: _screenDim,
                      min: 0.0,
                      max: 0.75,
                      divisions: 15,
                      onChanged: (val) {
                        setState(() {
                          _screenDim = val;
                        });
                        setModalState(() {});
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBgColorChoice(Color color, String label, StateSetter setModalState) {
    final isSelected = _backgroundColor == color;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _backgroundColor = color;
          });
          setModalState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.deepOrange : Colors.grey.shade700,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: color == Colors.white || color == const Color(0xFFFBF0D9) ? Colors.black : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ch = _currentChapter;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _showControls
          ? AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ch.chapterTitle, style: const TextStyle(fontSize: 16)),
                  Text('${ch.mangaTitle} (Offline)',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.display_settings),
                  tooltip: 'Tampilan Reader',
                  onPressed: _showReaderSettingsModal,
                ),
              ],
            )
          : null,
      bottomNavigationBar: _showControls && _imageFiles.isNotEmpty
          ? Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SafeArea(
                child: Row(
                  children: [
                    Text('Halaman ${_currentPageIndex + 1}/${_imageFiles.length}',
                        style: const TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: _currentPageIndex.toDouble().clamp(0.0, (_imageFiles.length - 1).toDouble()),
                        min: 0.0,
                        max: (_imageFiles.length - 1).toDouble(),
                        divisions: _imageFiles.length > 1 ? _imageFiles.length - 1 : 1,
                        onChanged: (val) {
                          final target = val.round();
                          setState(() {
                            _currentPageIndex = target;
                          });
                          if (_readerMode == ReaderMode.pageFlipHorizontal && _pageController.hasClients) {
                            final pageToJump = _isRTL ? (_imageFiles.length - 1 - target) : target;
                            _pageController.jumpToPage(pageToJump);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _imageFiles.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text(
                              'File gambar unduhan tidak ditemukan atau kosong.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              ch.localDir,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        setState(() {
                          _showControls = !_showControls;
                        });
                      },
                      child: _readerMode == ReaderMode.pageFlipHorizontal
                          ? PageView.builder(
                              controller: _pageController,
                              itemCount: _imageFiles.length,
                              onPageChanged: (idx) {
                                final actualIdx = _isRTL ? (_imageFiles.length - 1 - idx) : idx;
                                setState(() {
                                  _currentPageIndex = actualIdx;
                                });
                                _recordCurrentHistory();
                              },
                              itemBuilder: (context, index) {
                                final imgList = _isRTL ? _imageFiles.reversed.toList() : _imageFiles;
                                final actualIdx = _isRTL ? (_imageFiles.length - 1 - index) : index;
                                return InteractiveViewer(
                                  minScale: 1.0,
                                  maxScale: 3.5,
                                  child: Center(
                                    child: LocalImageItem(
                                      localPath: imgList[index],
                                      index: actualIdx,
                                      total: _imageFiles.length,
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: _imageFiles.length,
                              itemBuilder: (context, index) {
                                return LocalImageItem(
                                  localPath: _imageFiles[index],
                                  index: index,
                                  total: _imageFiles.length,
                                );
                              },
                            ),
                    ),
          if (_screenDim > 0.0)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(alpha: _screenDim),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
