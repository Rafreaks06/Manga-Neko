import 'package:flutter/material.dart';
import 'package:mangareader_flutter/src/rust/api/models.dart';

class GenreCatalogItem {
  final String slug;
  final String label;
  final IconData icon;
  final List<Color> gradient;

  const GenreCatalogItem(this.slug, this.label, this.icon, this.gradient);
}

/// Urutan dan slug mengikuti genre yang dikenali Komiku/KomikIndo.
/// Gradien dipilih untuk merepresentasikan mood tiap genre
/// (contoh: gelap untuk Horror, hangat/aksi untuk Shonen).
const List<GenreCatalogItem> genreCatalog = [
  GenreCatalogItem('action', 'Action', Icons.sports_martial_arts, [Color(0xFFD32F2F), Color(0xFFFF6F00)]),
  GenreCatalogItem('adventure', 'Adventure', Icons.explore, [Color(0xFF2E7D32), Color(0xFF00897B)]),
  GenreCatalogItem('comedy', 'Comedy', Icons.sentiment_very_satisfied, [Color(0xFFF9A825), Color(0xFFFFD54F)]),
  GenreCatalogItem('drama', 'Drama', Icons.theater_comedy, [Color(0xFF6A1B9A), Color(0xFF4527A0)]),
  GenreCatalogItem('fantasy', 'Fantasy', Icons.auto_awesome, [Color(0xFF5E35B1), Color(0xFF7E57C2)]),
  GenreCatalogItem('horror', 'Horror', Icons.dark_mode, [Color(0xFF1A1A2E), Color(0xFF3E1F47)]),
  GenreCatalogItem('isekai', 'Isekai', Icons.door_sliding, [Color(0xFF1E88E5), Color(0xFF7B1FA2)]),
  GenreCatalogItem('mystery', 'Mystery', Icons.psychology_alt, [Color(0xFF37474F), Color(0xFF546E7A)]),
  GenreCatalogItem('psychological', 'Psychological', Icons.psychology, [Color(0xFF4E342E), Color(0xFF8D6E63)]),
  GenreCatalogItem('romance', 'Romance', Icons.favorite, [Color(0xFFEC407A), Color(0xFFF48FB1)]),
  GenreCatalogItem('school-life', 'School Life', Icons.school, [Color(0xFF00897B), Color(0xFF4DD0E1)]),
  GenreCatalogItem('sci-fi', 'Sci-Fi', Icons.rocket_launch, [Color(0xFF0277BD), Color(0xFF00ACC1)]),
  GenreCatalogItem('shounen', 'Shounen', Icons.bolt, [Color(0xFFEF6C00), Color(0xFFFFB300)]),
  GenreCatalogItem('shoujo', 'Shoujo', Icons.local_florist, [Color(0xFFF06292), Color(0xFFBA68C8)]),
  GenreCatalogItem('seinen', 'Seinen', Icons.shield, [Color(0xFF263238), Color(0xFF455A64)]),
  GenreCatalogItem('slice-of-life', 'Slice of Life', Icons.local_cafe, [Color(0xFF558B2F), Color(0xFF9CCC65)]),
  GenreCatalogItem('sports', 'Sports', Icons.sports_soccer, [Color(0xFF1565C0), Color(0xFF43A047)]),
  GenreCatalogItem('supernatural', 'Supernatural', Icons.auto_fix_high, [Color(0xFF311B92), Color(0xFF1A237E)]),
  GenreCatalogItem('magic', 'Magic', Icons.stars, [Color(0xFF8E24AA), Color(0xFFE91E63)]),
  GenreCatalogItem('mecha', 'Mecha', Icons.precision_manufacturing, [Color(0xFF455A64), Color(0xFF1976D2)]),
  GenreCatalogItem('historical', 'Historical', Icons.account_balance, [Color(0xFF6D4C41), Color(0xFFFFB74D)]),
  GenreCatalogItem('military', 'Military', Icons.military_tech, [Color(0xFF33691E), Color(0xFF5D4037)]),
  GenreCatalogItem('thriller', 'Thriller', Icons.local_police, [Color(0xFFB71C1C), Color(0xFF212121)]),
  GenreCatalogItem('music', 'Music', Icons.music_note, [Color(0xFFC2185B), Color(0xFF5E35B1)]),
  // Genre sensitif — disembunyikan secara default, muncul hanya jika
  // pengguna mengaktifkannya di Settings.
  GenreCatalogItem('ecchi', 'Ecchi', Icons.local_fire_department, [Color(0xFFAD1457), Color(0xFFFF5983)]),
  GenreCatalogItem('gore', 'Gore', Icons.bloodtype, [Color(0xFF7F0000), Color(0xFF212121)]),
  GenreCatalogItem('mature', 'Mature', Icons.eighteen_up_rating, [Color(0xFF37474F), Color(0xFF8E0000)]),
  GenreCatalogItem('hentai', 'Hentai', Icons.no_adult_content, [Color(0xFF4A148C), Color(0xFF880E4F)]),
];

/// Slug genre yang dianggap konten sensitif (dewasa/kekerasan grafis).
const Set<String> sensitiveGenres = {'ecchi', 'gore', 'mature', 'hentai', 'adult', 'smut', 'erotica'};

/// Kata kunci heuristik untuk menyaring judul/deskripsi konten sensitif
/// pada listing katalog & pencarian (listing tidak menyertakan data genre).
final List<Pattern> _sensitiveKeywords = [
  RegExp(r'\becchi\b', caseSensitive: false),
  RegExp(r'\bhentai\b', caseSensitive: false),
  RegExp(r'\bnsfw\b', caseSensitive: false),
  RegExp(r'\bsmut\b', caseSensitive: false),
  RegExp(r'\berotic', caseSensitive: false),
  RegExp(r'\badult\b', caseSensitive: false),
  RegExp(r'\b18\+', caseSensitive: false),
  RegExp(r'\br-?18\b', caseSensitive: false),
  RegExp(r'\bgore\b', caseSensitive: false),
];

bool isSensitiveManga(MangaSummary item) {
  final text = '${item.title} ${item.description} ${item.typeName}';
  return _sensitiveKeywords.any((kw) => text.contains(kw));
}

List<GenreCatalogItem> visibleGenres(bool showSensitive) {
  if (showSensitive) return genreCatalog;
  return genreCatalog.where((g) => !sensitiveGenres.contains(g.slug)).toList();
}

List<MangaSummary> filterSensitiveContent(List<MangaSummary> items, bool showSensitive) {
  if (showSensitive) return items;
  return items.where((item) => !isSensitiveManga(item)).toList();
}
