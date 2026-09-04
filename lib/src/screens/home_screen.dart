import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangareader_flutter/src/providers/app_providers.dart';
import 'package:mangareader_flutter/src/rust/api/models.dart';
import 'package:mangareader_flutter/src/widgets/manga_card.dart';

const popularGenres = [
  'action',
  'adventure',
  'comedy',
  'drama',
  'ecchi',
  'fantasy',
  'isekai',
  'romance',
  'school-life',
  'sci-fi',
  'slice-of-life',
  'supernatural',
];

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
    final selectedGenre = ref.watch(selectedGenreProvider);
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Flexible(
                    child: Text(
                      'Manga Reader',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
              ref.read(catalogProvider(selected).notifier).refresh();
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
      body: Column(
        children: [
          if (!isSearchMode)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('Semua'),
                      selected: selectedGenre == null,
                      onSelected: (val) {
                        ref.read(selectedGenreProvider.notifier).state = null;
                        ref.read(catalogProvider(currentSource).notifier).refresh();
                      },
                    ),
                  ),
                  ...popularGenres.map((g) {
                    final isSel = selectedGenre == g;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(g[0].toUpperCase() + g.substring(1)),
                        selected: isSel,
                        onSelected: (val) {
                          ref.read(selectedGenreProvider.notifier).state = val ? g : null;
                          ref.read(catalogProvider(currentSource).notifier).refresh();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          Expanded(
            child: isSearchMode ? const SearchResultView() : const LatestMangaView(),
          ),
        ],
      ),
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
