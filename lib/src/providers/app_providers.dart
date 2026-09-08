import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mangareader_flutter/src/models/app_settings.dart';
import 'package:mangareader_flutter/src/rust/api.dart' as rust_api;
import 'package:mangareader_flutter/src/rust/api/models.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  static const _key = 'app_theme_mode';

  ThemeModeNotifier(this._prefs) : super(_loadThemeMode(_prefs));

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final val = prefs.getString(_key);
    if (val == 'light') return ThemeMode.light;
    if (val == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_key, mode.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

class ReaderModeNotifier extends StateNotifier<ReaderMode> {
  final SharedPreferences _prefs;
  static const _key = 'app_reader_mode';

  ReaderModeNotifier(this._prefs) : super(_loadReaderMode(_prefs));

  static ReaderMode _loadReaderMode(SharedPreferences prefs) {
    final val = prefs.getString(_key);
    if (val == 'pageFlipHorizontal') return ReaderMode.pageFlipHorizontal;
    return ReaderMode.continuousVertical;
  }

  Future<void> setReaderMode(ReaderMode mode) async {
    state = mode;
    await _prefs.setString(_key, mode.name);
  }
}

final readerModeProvider = StateNotifierProvider<ReaderModeNotifier, ReaderMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ReaderModeNotifier(prefs);
});

class AccentColorNotifier extends StateNotifier<Color> {
  final SharedPreferences _prefs;
  static const _key = 'app_accent_color';
  static const defaultColor = Color(0xFFFF5722);

  AccentColorNotifier(this._prefs)
      : super(Color(_prefs.getInt(_key) ?? defaultColor.toARGB32()));

  Future<void> setAccentColor(Color color) async {
    state = color;
    await _prefs.setInt(_key, color.toARGB32());
  }
}

final accentColorProvider = StateNotifierProvider<AccentColorNotifier, Color>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AccentColorNotifier(prefs);
});

/// Batasan konten sensitif: `false` (default) berarti genre dewasa
/// (Ecchi, Gore, dll.) disembunyikan dari Eksplorasi & Pencarian.
class ShowSensitiveGenresNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _key = 'show_sensitive_genres';

  ShowSensitiveGenresNotifier(this._prefs)
      : super(_prefs.getBool(_key) ?? false);

  Future<void> setShowSensitive(bool value) async {
    state = value;
    await _prefs.setBool(_key, value);
  }
}

final showSensitiveGenresProvider =
    StateNotifierProvider<ShowSensitiveGenresNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ShowSensitiveGenresNotifier(prefs);
});

class SelectedGenresNotifier extends StateNotifier<Set<String>> {
  SelectedGenresNotifier() : super({});

  void setAll(Set<String> genres) {
    state = Set<String>.from(genres);
  }

  void clear() {
    state = {};
  }
}

final selectedGenresProvider =
    StateNotifierProvider<SelectedGenresNotifier, Set<String>>((ref) {
  return SelectedGenresNotifier();
});

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

/// Mengambil halaman [page] untuk satu genre.
Future<List<MangaSummary>> _fetchGenrePage(MangaSource source, String genre, int page) {
  return rust_api.getMangaByGenre(source: source, genre: genre, page: page);
}

/// Multi-genre: gabungkan (union) hasil tiap genre dengan dedupe berdasarkan id,
/// karena backend Rust hanya menyediakan filter satu genre per permintaan.
Future<List<MangaSummary>> _fetchMergedGenrePages(
    MangaSource source, Set<String> genres, int page) async {
  final results = await Future.wait(
    genres.map((g) => _fetchGenrePage(source, g, page)),
  );
  final seen = <String>{};
  final merged = <MangaSummary>[];
  for (final list in results) {
    for (final item in list) {
      final key = '${item.source.name}:${item.id}';
      if (seen.add(key)) merged.add(item);
    }
  }
  return merged;
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
      final selectedGenres = ref.read(selectedGenresProvider);
      final List<MangaSummary> list;
      if (selectedGenres.isEmpty) {
        list = await rust_api.getLatestManga(source: source, page: 1);
      } else if (selectedGenres.length == 1) {
        list = await _fetchGenrePage(source, selectedGenres.first, 1);
      } else {
        list = await _fetchMergedGenrePages(source, selectedGenres, 1);
      }
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
      final selectedGenres = ref.read(selectedGenresProvider);
      final List<MangaSummary> newItems;
      if (selectedGenres.isEmpty) {
        newItems = await rust_api.getLatestManga(source: source, page: nextPage);
      } else if (selectedGenres.length == 1) {
        newItems = await _fetchGenrePage(source, selectedGenres.first, nextPage);
      } else {
        newItems = await _fetchMergedGenrePages(source, selectedGenres, nextPage);
      }

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

final isBookmarkedProvider = FutureProvider.family<bool, DetailParams>((ref, params) async {
  return rust_api.isBookmarked(source: params.source, mangaId: params.mangaId);
});

final mangaDetailProvider = FutureProvider.family<MangaDetail, DetailParams>((ref, params) async {
  return rust_api.getMangaDetail(source: params.source, mangaId: params.mangaId);
});

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

final downloadedChaptersProvider = FutureProvider<List<DownloadedChapter>>((ref) async {
  return rust_api.getDownloadedChapters();
});

class DownloadProgressState {
  final Map<String, double> progressMap;
  final Set<String> downloadingIds;

  DownloadProgressState({
    this.progressMap = const {},
    this.downloadingIds = const {},
  });

  DownloadProgressState copyWith({
    Map<String, double>? progressMap,
    Set<String>? downloadingIds,
  }) {
    return DownloadProgressState(
      progressMap: progressMap ?? this.progressMap,
      downloadingIds: downloadingIds ?? this.downloadingIds,
    );
  }
}

class DownloadManagerNotifier extends StateNotifier<DownloadProgressState> {
  final Ref ref;

  DownloadManagerNotifier(this.ref) : super(DownloadProgressState());

  void setProgress(String chapterPath, double progress) {
    final nextMap = Map<String, double>.from(state.progressMap);
    nextMap[chapterPath] = progress;
    final nextDownloading = Set<String>.from(state.downloadingIds)..add(chapterPath);
    state = state.copyWith(progressMap: nextMap, downloadingIds: nextDownloading);
  }

  void completeDownload(String chapterPath) {
    final nextMap = Map<String, double>.from(state.progressMap);
    nextMap.remove(chapterPath);
    final nextDownloading = Set<String>.from(state.downloadingIds)..remove(chapterPath);
    state = state.copyWith(progressMap: nextMap, downloadingIds: nextDownloading);
    ref.invalidate(downloadedChaptersProvider);
  }

  void failDownload(String chapterPath) {
    final nextMap = Map<String, double>.from(state.progressMap);
    nextMap.remove(chapterPath);
    final nextDownloading = Set<String>.from(state.downloadingIds)..remove(chapterPath);
    state = state.copyWith(progressMap: nextMap, downloadingIds: nextDownloading);
  }
}

final downloadManagerProvider = StateNotifierProvider<DownloadManagerNotifier, DownloadProgressState>((ref) {
  return DownloadManagerNotifier(ref);
});

