import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangareader_flutter/src/models/app_settings.dart';
import 'package:mangareader_flutter/src/providers/app_providers.dart';
import 'package:mangareader_flutter/src/rust/api.dart' as rust_api;
import 'package:mangareader_flutter/src/rust/api/models.dart';
import 'package:mangareader_flutter/src/screens/offline_reader_screen.dart';
import 'package:mangareader_flutter/src/widgets/reader_image_item.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String? mangaId;
  final String? mangaTitle;
  final String? thumbnail;
  final List<ChapterItem> chapters;
  final int currentChapterIndex;
  final String? chapterPath;
  final String? chapterTitle;
  final MangaSource source;

  const ReaderScreen({
    super.key,
    this.mangaId,
    this.mangaTitle,
    this.thumbnail,
    this.chapters = const [],
    this.currentChapterIndex = 0,
    this.chapterPath,
    this.chapterTitle,
    required this.source,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late int _currentIndex;
  final ScrollController _scrollController = ScrollController();
  late PageController _pageController;
  bool _showControls = true;

  late ReaderMode _readerMode;
  bool _isRTL = false;
  Color _backgroundColor = Colors.black;
  double _screenDim = 0.0;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentChapterIndex;
    _readerMode = ref.read(readerModeProvider);
    _pageController = PageController(initialPage: 0);
    _recordCurrentHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String get _currentPath {
    if (widget.chapters.isNotEmpty && _currentIndex < widget.chapters.length) {
      return widget.chapters[_currentIndex].urlPath;
    }
    return widget.chapterPath ?? '';
  }

  String get _currentTitle {
    if (widget.chapters.isNotEmpty && _currentIndex < widget.chapters.length) {
      return widget.chapters[_currentIndex].title;
    }
    return widget.chapterTitle ?? 'Reader';
  }

  bool get _hasPrev => widget.chapters.isNotEmpty && _currentIndex < widget.chapters.length - 1;
  bool get _hasNext => widget.chapters.isNotEmpty && _currentIndex > 0;

  void _recordCurrentHistory() {
    if (widget.mangaId != null) {
      rust_api.saveHistory(
        source: widget.source,
        mangaId: widget.mangaId!,
        mangaTitle: widget.mangaTitle ?? '',
        chapterPath: _currentPath,
        chapterTitle: _currentTitle,
        thumbnail: widget.thumbnail ?? '',
        lastPage: _currentPageIndex + 1,
      ).then((_) {
        ref.invalidate(historyProvider);
      });
    }
  }

  void _goToChapter(int index) {
    if (index >= 0 && index < widget.chapters.length) {
      setState(() {
        _currentIndex = index;
        _currentPageIndex = 0;
      });
      _recordCurrentHistory();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
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
                          'Opsi Tampilan Reader',
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

  void _showChapterSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pilih Chapter (${widget.chapters.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.chapters.length,
                  itemBuilder: (context, idx) {
                    final ch = widget.chapters[idx];
                    final isCurrent = idx == _currentIndex;
                    return ListTile(
                      selected: isCurrent,
                      selectedTileColor: Colors.deepOrange.withValues(alpha: 0.15),
                      leading: Icon(
                        isCurrent ? Icons.play_circle_filled : Icons.bookmark_border,
                        color: isCurrent ? Colors.deepOrange : Colors.grey,
                      ),
                      title: Text(
                        ch.title,
                        style: TextStyle(
                          color: isCurrent ? Colors.deepOrange : Colors.white,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: ch.releaseDate.isNotEmpty
                          ? Text(ch.releaseDate, style: const TextStyle(fontSize: 11))
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        _goToChapter(idx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloadedListAsync = ref.watch(downloadedChaptersProvider);
    final downloadedMatch = downloadedListAsync.value?.where(
      (d) => d.source == widget.source && d.chapterPath == _currentPath,
    ).firstOrNull;

    final pages = ref.watch(chapterPagesProvider(ChapterParams(source: widget.source, chapterPath: _currentPath)));
    final referer = widget.source == MangaSource.komiku ? 'https://komiku.org/' : 'https://komikindo.ch/';

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _showControls
          ? AppBar(
              title: Text(_currentTitle, style: const TextStyle(fontSize: 16)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.display_settings),
                  tooltip: 'Tampilan Reader',
                  onPressed: _showReaderSettingsModal,
                ),
                if (widget.chapters.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.list_alt),
                    tooltip: 'Daftar Chapter',
                    onPressed: _showChapterSelectionModal,
                  ),
              ],
            )
          : null,
      bottomNavigationBar: _showControls && widget.chapters.isNotEmpty
          ? Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    pages.maybeWhen(
                      data: (data) {
                        if (data.images.isEmpty) return const SizedBox.shrink();
                        return Row(
                          children: [
                            Text('Halaman ${_currentPageIndex + 1}/${data.images.length}',
                                style: const TextStyle(fontSize: 12)),
                            Expanded(
                              child: Slider(
                                value: _currentPageIndex.toDouble().clamp(0.0, (data.images.length - 1).toDouble()),
                                min: 0.0,
                                max: (data.images.length - 1).toDouble(),
                                divisions: data.images.length > 1 ? data.images.length - 1 : 1,
                                onChanged: (val) {
                                  final target = val.round();
                                  setState(() {
                                    _currentPageIndex = target;
                                  });
                                  if (_readerMode == ReaderMode.pageFlipHorizontal && _pageController.hasClients) {
                                    final pageToJump = _isRTL ? (data.images.length - 1 - target) : target;
                                    _pageController.jumpToPage(pageToJump);
                                  }
                                },
                              ),
                            ),
                          ],
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _hasPrev ? () => _goToChapter(_currentIndex + 1) : null,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Prev'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _showChapterSelectionModal,
                          icon: const Icon(Icons.menu_book, size: 18),
                          label: Text(
                            'Ch. ${widget.chapters.length - _currentIndex}/${widget.chapters.length}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _hasNext ? () => _goToChapter(_currentIndex - 1) : null,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            child: pages.when(
              data: (data) {
                if (data.images.isEmpty) {
                  return const Center(child: Text('Gambar tidak ditemukan pada chapter ini.'));
                }

                if (_readerMode == ReaderMode.pageFlipHorizontal) {
                  final imgList = _isRTL ? data.images.reversed.toList() : data.images;
                  return PageView.builder(
                    controller: _pageController,
                    itemCount: imgList.length,
                    onPageChanged: (idx) {
                      final actualIdx = _isRTL ? (imgList.length - 1 - idx) : idx;
                      setState(() {
                        _currentPageIndex = actualIdx;
                      });
                      _recordCurrentHistory();
                    },
                    itemBuilder: (context, index) {
                      final actualIdx = _isRTL ? (imgList.length - 1 - index) : index;
                      return InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 3.5,
                        child: Center(
                          child: ReaderImageItem(
                            imageUrl: imgList[index],
                            index: actualIdx,
                            total: data.images.length,
                            referer: referer,
                          ),
                        ),
                      );
                    },
                  );
                }

                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 3.5,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: data.images.length + (widget.chapters.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == data.images.length) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                          child: Column(
                            children: [
                              const Divider(),
                              const SizedBox(height: 12),
                              Text('Akhir dari $_currentTitle', style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_hasPrev)
                                    OutlinedButton.icon(
                                      onPressed: () => _goToChapter(_currentIndex + 1),
                                      icon: const Icon(Icons.arrow_back),
                                      label: const Text('Chapter Sebelumnya'),
                                    ),
                                  if (_hasPrev && _hasNext) const SizedBox(width: 12),
                                  if (_hasNext)
                                    ElevatedButton.icon(
                                      onPressed: () => _goToChapter(_currentIndex - 1),
                                      icon: const Icon(Icons.arrow_forward),
                                      label: const Text('Chapter Selanjutnya'),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        );
                      }

                      return ReaderImageItem(
                        imageUrl: data.images[index],
                        index: index,
                        total: data.images.length,
                        referer: referer,
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) {
                if (downloadedMatch != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Offline: Chapter tersimpan di perangkat'),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OfflineReaderScreen(chapter: downloadedMatch),
                              ),
                            );
                          },
                          icon: const Icon(Icons.offline_pin),
                          label: const Text('Buka Offline'),
                        ),
                      ],
                    ),
                  );
                }
                return Center(child: Text('Error: $err'));
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
