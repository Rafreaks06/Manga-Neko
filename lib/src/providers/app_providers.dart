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

final selectedGenreProvider = StateProvider<String?>((ref) => null);

class CatalogNotifier extends StateNotifier<AsyncValue<PaginatedMangaState>> {
  final Ref ref;
  final MangaSource source;

  CatalogNotifier(this.ref, this.source) : super(const AsyncValue.loading()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = const AsyncValue.loading();
    try {
      final selectedGenre = ref.read(selectedGenreProvider);
      final List<MangaSummary> list;
      if (selectedGenre != null && selectedGenre.isNotEmpty) {
        list = await rust_api.getMangaByGenre(source: source, genre: selectedGenre, page: 1);
      } else {
        list = await rust_api.getLatestManga(source: source, page: 1);
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
      final selectedGenre = ref.read(selectedGenreProvider);
      final List<MangaSummary> newItems;
      if (selectedGenre != null && selectedGenre.isNotEmpty) {
        newItems = await rust_api.getMangaByGenre(source: source, genre: selectedGenre, page: nextPage);
      } else {
        newItems = await rust_api.getLatestManga(source: source, page: nextPage);
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

