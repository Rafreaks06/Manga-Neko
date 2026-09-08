import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:mangareader_flutter/src/models/app_settings.dart';
import 'package:mangareader_flutter/src/providers/app_providers.dart';
import 'package:mangareader_flutter/src/rust/api.dart' as rust_api;
import 'package:mangareader_flutter/src/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showAccentColorDialog(BuildContext context, WidgetRef ref, Color current) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Warna Aksen'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: accentPresets.map((preset) {
              final isSelected = current.toARGB32() == preset.color.toARGB32();
              return GestureDetector(
                onTap: () {
                  ref.read(accentColorProvider.notifier).setAccentColor(preset.color);
                  Navigator.pop(ctx);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: preset.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(ctx).colorScheme.onSurface
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: preset.color.withValues(alpha: 0.6),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: preset.color.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 72,
                      child: Text(
                        preset.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final readerMode = ref.watch(readerModeProvider);
    final accentColor = ref.watch(accentColorProvider);
    final showSensitive = ref.watch(showSensitiveGenresProvider);
    final sectionStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Tampilan & Tema', style: sectionStyle),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
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
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Warna Aksen'),
            subtitle: const Text('Warna utama untuk tombol, switch, & sorotan'),
            trailing: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            onTap: () => _showAccentColorDialog(context, ref, accentColor),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Batasan Konten', style: sectionStyle),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.shield_outlined),
            title: const Text('Tampilkan Genre Dewasa'),
            subtitle: Text(
              showSensitive
                  ? 'Konten sensitif (Ecchi, Gore, dll.) DITAMPILKAN di Eksplorasi & Pencarian.'
                  : 'Konten sensitif (Ecchi, Gore, dll.) disembunyikan demi keamanan anak di bawah umur.',
            ),
            value: showSensitive,
            onChanged: (value) async {
              if (value) {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Tampilkan Konten Dewasa?'),
                    content: const Text(
                      'Konten sensitif seperti Ecchi dan Gore akan muncul di Eksplorasi dan Pencarian. '
                      'Fitur ini tidak disarankan jika perangkat digunakan anak di bawah umur.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Saya Mengerti'),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;
              }
              await ref.read(showSensitiveGenresProvider.notifier).setShowSensitive(value);
              final source = ref.read(currentSourceProvider);
              ref.invalidate(catalogProvider(source));
              ref.invalidate(searchResultsProvider);
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Preferensi Reader', style: sectionStyle),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Penyimpanan & Cache', style: sectionStyle),
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
                  'Manga Neko v1.1.0',
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
