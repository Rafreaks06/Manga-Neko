import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangareader_flutter/src/models/genre_catalog.dart';
import 'package:mangareader_flutter/src/providers/app_providers.dart';
import 'package:mangareader_flutter/src/rust/api/models.dart';
import 'package:mangareader_flutter/src/screens/genre_picker_sheet.dart';
import 'package:mangareader_flutter/src/widgets/genre_visual_card.dart';
import 'package:mangareader_flutter/src/widgets/manga_card.dart';

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
    final selectedGenres = ref.watch(selectedGenresProvider);
    final showSensitive = ref.watch(showSensitiveGenresProvider);
    final isSearchMode = _isSearching && query.trim().isNotEmpty;
    final quickGenres = visibleGenres(showSensitive).take(8).toList();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onSubmitted: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
                decoration: InputDecoration(
                  hintText: 'Cari di ${currentSource.name.toUpperCase()}...',
                  border: InputBorder.none,
                  filled: false,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Flexible(
                    child: Text(
                      'Manga Neko',
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
      floatingActionButton: isSearchMode
          ? null
          : FloatingActionButton.extended(
              heroTag: 'genre_fab',
              onPressed: () => showGenrePickerSheet(context),
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('Genre'),
            ),
      body: Column(
        children: [
          if (!isSearchMode)
            SizedBox(
              height: 104,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                children: [
                  _AllGenresCard(
                    selected: selectedGenres.isEmpty,
                    onTap: () {
                      ref.read(selectedGenresProvider.notifier).clear();
                      ref.read(catalogProvider(currentSource).notifier).refresh();
                    },
                  ),
                  ...quickGenres.map((g) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      // Lebar tetap: ListView horizontal memberi lebar tak
                      // terbatas, dan Stack di dalam kartu butuh constraint
                      // finit agar tidak melempar layout exception.
                      child: SizedBox(
                        width: 92,
                        child: GenreVisualCard(
                          genre: g,
                          height: 84,
                          onTap: () {
                            ref.read(selectedGenresProvider.notifier).setAll({g.slug});
                            ref.read(catalogProvider(currentSource).notifier).refresh();
                          },
                          selected: selectedGenres.contains(g.slug),
                        ),
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _MoreGenresCard(
                      onTap: () => showGenrePickerSheet(context),
                    ),
                  ),
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

class _AllGenresCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _AllGenresCard({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 92,
        height: 84,
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apps_rounded,
              size: 30,
              color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              'Semua',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreGenresCard extends StatelessWidget {
  final VoidCallback onTap;

  const _MoreGenresCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        height: 84,
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grid_view_rounded, size: 30, color: scheme.onSecondaryContainer),
            const SizedBox(height: 6),
            Text(
              'Semua Genre',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
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
    final showSensitive = ref.watch(showSensitiveGenresProvider);
    final catalogAsync = ref.watch(catalogProvider(source));

    return catalogAsync.when(
      data: (paginated) {
        final items = filterSensitiveContent(paginated.items, showSensitive);
        if (items.isEmpty) {
          return const Center(child: Text('Tidak ada manga ditemukan.'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.read(catalogProvider(source).notifier).refresh(),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
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
    final showSensitive = ref.watch(showSensitiveGenresProvider);

    return searchResults.when(
      data: (items) {
        final visibleItems = filterSensitiveContent(items, showSensitive);
        if (visibleItems.isEmpty) {
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
          itemCount: visibleItems.length,
          itemBuilder: (context, index) {
            final item = visibleItems[index];
            return MangaCard(item: item);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}
