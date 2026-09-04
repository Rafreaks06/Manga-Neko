import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:mangareader_flutter/src/models/app_settings.dart';
import 'package:mangareader_flutter/src/providers/app_providers.dart';
import 'package:mangareader_flutter/src/rust/api.dart' as rust_api;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final readerMode = ref.watch(readerModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Tampilan & Tema',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Tema Aplikasi'),
            subtitle: Text(
              themeMode == ThemeMode.system
                  ? 'Ikuti Sistem'
                  : themeMode == ThemeMode.dark
                      ? 'Mode Gelap (Dark)'
                      : 'Mode Terang (Light)',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Pilih Tema'),
                  content: RadioGroup<ThemeMode>(
                    groupValue: themeMode,
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(themeModeProvider.notifier).setThemeMode(val);
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<ThemeMode>(
                          title: Text('Ikuti Sistem'),
                          value: ThemeMode.system,
                        ),
                        RadioListTile<ThemeMode>(
                          title: Text('Mode Terang'),
                          value: ThemeMode.light,
                        ),
                        RadioListTile<ThemeMode>(
                          title: Text('Mode Gelap'),
                          value: ThemeMode.dark,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Preferensi Reader',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chrome_reader_mode_outlined),
            title: const Text('Mode Baca Default'),
            subtitle: Text(
              readerMode == ReaderMode.continuousVertical
                  ? 'Vertical (Webtoon Scroll)'
                  : 'Horizontal (Slide Page / Flip)',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Pilih Mode Baca Default'),
                  content: RadioGroup<ReaderMode>(
                    groupValue: readerMode,
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(readerModeProvider.notifier).setReaderMode(val);
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<ReaderMode>(
                          title: Text('Vertical (Webtoon Scroll)'),
                          subtitle: Text('Scroll atas-bawah tanpa putus'),
                          value: ReaderMode.continuousVertical,
                        ),
                        RadioListTile<ReaderMode>(
                          title: Text('Horizontal (Slide Page)'),
                          subtitle: Text('Geser per lembar halaman'),
                          value: ReaderMode.pageFlipHorizontal,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Penyimpanan & Cache',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Bersihkan Cache Gambar'),
            subtitle: const Text('Menghapus cache gambar yang diunduh untuk hemat memori'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Bersihkan Cache?'),
                  content: const Text('Cache gambar yang disimpan di disk akan dikosongkan.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Bersihkan'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await DefaultCacheManager().emptyCache();
                PaintingBinding.instance.imageCache.clear();
                PaintingBinding.instance.imageCache.clearLiveImages();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache gambar berhasil dibersihkan!')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
            title: const Text('Hapus Seluruh Riwayat Baca', style: TextStyle(color: Colors.redAccent)),
            subtitle: const Text('Menghapus semua data chapter yang pernah dibaca'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus Riwayat?'),
                  content: const Text('Semua riwayat membaca akan dihapus permanen.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await rust_api.clearHistory();
                ref.invalidate(historyProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Riwayat membaca berhasil dikosongkan!')),
                  );
                }
              }
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Manga Reader v1.0.0',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'Flutter 3 + Rust High-Performance Engine',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
