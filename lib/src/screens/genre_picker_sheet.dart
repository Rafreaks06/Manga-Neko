import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangareader_flutter/src/models/genre_catalog.dart';
import 'package:mangareader_flutter/src/providers/app_providers.dart';
import 'package:mangareader_flutter/src/widgets/genre_visual_card.dart';

/// Bottom sheet berisi grid genre visual dengan interaksi multi-select.
/// Menampilkan genre sensitif hanya jika opsi konten dewasa aktif di Settings.
Future<void> showGenrePickerSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _GenrePickerSheet(),
  );
}

class _GenrePickerSheet extends ConsumerStatefulWidget {
  const _GenrePickerSheet();

  @override
  ConsumerState<_GenrePickerSheet> createState() => _GenrePickerSheetState();
}

class _GenrePickerSheetState extends ConsumerState<_GenrePickerSheet> {
  late Set<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = Set<String>.from(ref.read(selectedGenresProvider));
  }

  void _apply() {
    ref.read(selectedGenresProvider.notifier).setAll(_tempSelected);
    final source = ref.read(currentSourceProvider);
    ref.read(catalogProvider(source).notifier).refresh();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final showSensitive = ref.watch(showSensitiveGenresProvider);
    final genres = visibleGenres(showSensitive);
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Text(
              'Pilih Genre',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Ketuk untuk memilih, bisa lebih dari satu',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.05,
                ),
                itemCount: genres.length,
                itemBuilder: (context, index) {
                  final genre = genres[index];
                  return GenreVisualCard(
                    genre: genre,
                    selected: _tempSelected.contains(genre.slug),
                    height: double.infinity,
                    iconSize: 32,
                    fontSize: 12,
                    onTap: () {
                      setState(() {
                        if (_tempSelected.contains(genre.slug)) {
                          _tempSelected.remove(genre.slug);
                        } else {
                          _tempSelected.add(genre.slug);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_tempSelected.length} genre dipilih',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: _tempSelected.isEmpty
                          ? null
                          : () {
                              setState(() => _tempSelected.clear());
                            },
                      child: const Text('Reset'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _apply,
                      icon: const Icon(Icons.check),
                      label: const Text('Terapkan'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
