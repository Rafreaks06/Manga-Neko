import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:mangareader_flutter/src/rust/api.dart' as rust_api;
import 'package:mangareader_flutter/src/rust/api/models.dart';
import 'package:mangareader_flutter/src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  
  final docDir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(docDir.path, 'mangareader.db');
  await rust_api.initDatabase(dbPath: dbPath);

  runApp(const ProviderScope(child: MangaApp()));
}

final currentSourceProvider = StateProvider<MangaSource>((ref) => MangaSource.komiku);

class PaginatedMangaState {
  final List<MangaSummary> items;
  final int currentPage;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  PaginatedMangaState({
    required this.items,
    required this.currentPage,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  PaginatedMangaState copyWith({
    List<MangaSummary>? items,
    int? currentPage,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return PaginatedMangaState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class CatalogNotifier extends StateNotifier<AsyncValue<PaginatedMangaState>> {
  final Ref ref;
  final MangaSource source;

  CatalogNotifier(this.ref, this.source) : super(const AsyncValue.loading()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = const AsyncValue.loading();
    try {
      final list = await rust_api.getLatestManga(source: source, page: 1);
      state = AsyncValue.data(PaginatedMangaState(
        items: list,
        currentPage: 1,
        hasMore: list.isNotEmpty,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadNextPage() async {
    final currentState = state.value;
    if (currentState == null || currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));
    try {
      final nextPage = currentState.currentPage + 1;
      final newItems = await rust_api.getLatestManga(source: source, page: nextPage);
      if (newItems.isEmpty) {
        state = AsyncValue.data(currentState.copyWith(isLoadingMore: false, hasMore: false));
      } else {
        state = AsyncValue.data(currentState.copyWith(
          items: [...currentState.items, ...newItems],
          currentPage: nextPage,
          isLoadingMore: false,
          hasMore: true,
        ));
      }
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: false, error: e.toString()));
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }
}

final catalogProvider = StateNotifierProvider.family<CatalogNotifier, AsyncValue<PaginatedMangaState>, MangaSource>((ref, source) {
  return CatalogNotifier(ref, source);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<MangaSummary>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  final source = ref.watch(currentSourceProvider);
  return rust_api.searchManga(source: source, query: query);
});

final bookmarksProvider = FutureProvider<List<BookmarkItem>>((ref) async {
  return rust_api.getBookmarks();
});

final historyProvider = FutureProvider<List<HistoryItem>>((ref) async {
  return rust_api.getHistory();
});

final isBookmarkedProvider = FutureProvider.family<bool, DetailParams>((ref, params) async {
  return rust_api.isBookmarked(source: params.source, mangaId: params.mangaId);
});

class MangaApp extends StatelessWidget {
  const MangaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manga Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    BookmarksScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Katalog',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Bookmark',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final currentSource = ref.watch(currentSourceProvider);
    final isSearchMode = _isSearching && query.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cari di ${currentSource.name.toUpperCase()}...',
                  border: InputBorder.none,
                ),
                onSubmitted: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
              )
            : Row(
                children: [
                  const Text('Manga Reader'),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      currentSource.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
        actions: [
          PopupMenuButton<MangaSource>(
            icon: const Icon(Icons.tune),
            tooltip: 'Pilih Sumber Manga',
            initialValue: currentSource,
            onSelected: (MangaSource selected) {
              ref.read(currentSourceProvider.notifier).state = selected;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: MangaSource.komiku,
                child: Row(
                  children: [
                    Icon(Icons.public, size: 18),
                    SizedBox(width: 8),
                    Text('Komiku (komiku.org)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: MangaSource.komikindo,
                child: Row(
                  children: [
                    Icon(Icons.language, size: 18),
                    SizedBox(width: 8),
                    Text('KomikIndo (komikindo.ch)'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: isSearchMode ? const SearchResultView() : const LatestMangaView(),
    );
  }
}

class LatestMangaView extends ConsumerStatefulWidget {
  const LatestMangaView({super.key});

  @override
  ConsumerState<LatestMangaView> createState() => _LatestMangaViewState();
}

class _LatestMangaViewState extends ConsumerState<LatestMangaView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      final source = ref.read(currentSourceProvider);
      ref.read(catalogProvider(source).notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(currentSourceProvider);
    final catalogAsync = ref.watch(catalogProvider(source));

    return catalogAsync.when(
      data: (paginated) {
        final items = paginated.items;
        if (items.isEmpty) {
          return const Center(child: Text('Tidak ada manga ditemukan.'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.read(catalogProvider(source).notifier).refresh(),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return MangaCard(item: item);
                    },
                    childCount: items.length,
                  ),
                ),
              ),
              if (paginated.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              if (!paginated.hasMore && items.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text('Sudah mencapai akhir katalog.', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gagal memuat data: $err', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(catalogProvider(source).notifier).refresh(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchResultView extends ConsumerWidget {
  const SearchResultView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(searchResultsProvider);

    return searchResults.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('Hasil pencarian kosong.'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return MangaCard(item: item);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

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

class DetailParams {
  final MangaSource source;
  final String mangaId;

  DetailParams({required this.source, required this.mangaId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetailParams &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          mangaId == other.mangaId;

  @override
  int get hashCode => source.hashCode ^ mangaId.hashCode;
}

final mangaDetailProvider = FutureProvider.family<MangaDetail, DetailParams>((ref, params) async {
  return rust_api.getMangaDetail(source: params.source, mangaId: params.mangaId);
});

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
                      subtitle: ch.releaseDate.isNotEmpty ? Text(ch.releaseDate, style: const TextStyle(fontSize: 11)) : null,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        // Save history
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

class ChapterParams {
  final MangaSource source;
  final String chapterPath;

  ChapterParams({required this.source, required this.chapterPath});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterParams &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          chapterPath == other.chapterPath;

  @override
  int get hashCode => source.hashCode ^ chapterPath.hashCode;
}

final chapterPagesProvider = FutureProvider.family<ChapterPages, ChapterParams>((ref, params) async {
  return rust_api.getChapterPages(source: params.source, chapterPath: params.chapterPath);
});

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
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentChapterIndex;
    _recordCurrentHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  bool get _hasPrev => widget.chapters.isNotEmpty && _currentIndex < widget.chapters.length - 1; // Chapters descending order
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
        lastPage: 1,
      ).then((_) {
        ref.invalidate(historyProvider);
      });
    }
  }

  void _goToChapter(int index) {
    if (index >= 0 && index < widget.chapters.length) {
      setState(() {
        _currentIndex = index;
      });
      _recordCurrentHistory();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
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
                      subtitle: ch.releaseDate.isNotEmpty ? Text(ch.releaseDate, style: const TextStyle(fontSize: 11)) : null,
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
    final pages = ref.watch(chapterPagesProvider(ChapterParams(source: widget.source, chapterPath: _currentPath)));
    final referer = widget.source == MangaSource.komiku ? 'https://komiku.org/' : 'https://komikindo.ch/';

    return Scaffold(
      appBar: _showControls
          ? AppBar(
              title: Text(_currentTitle, style: const TextStyle(fontSize: 16)),
              actions: [
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SafeArea(
                child: Row(
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
              ),
            )
          : null,
      body: GestureDetector(
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
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

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
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
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

  class BookmarksScreen extends ConsumerWidget {
    const BookmarksScreen({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final bookmarksAsync = ref.watch(bookmarksProvider);

      return Scaffold(
        appBar: AppBar(
          title: const Text('Koleksi Bookmark'),
        ),
        body: bookmarksAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Belum ada manga yang dibookmark.'),
                  ],
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(
                          mangaId: item.mangaId,
                          title: item.title,
                          source: item.source,
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
                                    item.source.name.toUpperCase(),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
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
