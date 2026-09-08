# Manga Neko (Flutter + Rust Core)

Aplikasi Manga & Manhwa Reader multi-platform berbasis **Flutter** dengan backend engine berkekuatan tinggi menggunakan **Rust** via `flutter_rust_bridge` v2.

---

## Download APK Android (Release)

Versi rilis APK siap install di HP Android:

- **Download Direct**: [manga-neko-v1.1.0.apk (GitHub Release)](https://github.com/Rafreaks06/Manga-Neko/releases/download/v1.1.0/manga-neko-v1.1.0.apk)
- **Download Lokal**: [manga-neko-v1.1.0.apk](./releases/manga-neko-v1.1.0.apk)
- **Semua Versi**: [GitHub Releases](https://github.com/Rafreaks06/Manga-Neko/releases)
- **Versi**: `v1.1.0`
- **Arsitektur**: Universal (`arm64-v8a` + `armeabi-v7a` 32-bit)
- **Ukuran File**: `~72 MB`
- **Min Android SDK**: Android 5.0 (Lollipop) / Rekomendasi Android 10+

---

## Apa yang Baru di v1.1.0

- **Modernisasi UI Material 3 (Material You)**:
  - Dynamic color tokens dari seed color via `ColorScheme.fromSeed` — seluruh komponen adaptif terhadap tema.
  - Rounded corners lebih lembut: kartu (16px), dialog & bottom sheet (28px), FAB (20px), chip & tombol (12-16px).
  - Navigation Bar bawah & FAB extended modern dengan indikator `primaryContainer`.
- **Kustomisasi Warna Aksen (Dynamic Theme Selection)**:
  - 8 preset warna aksen (Manga Orange, Neko Blue, Sakura Pink, Violet, Emerald, Sunset Red, Amber, Cyan).
  - Warna aksen diterapkan pada button, active state, switch, progress bar, dan teks sorotan.
  - Adaptif penuh untuk Light Mode & Dark Mode; pilihan tersimpan permanen.
- **Filter Konten Sensitif (Content Restriction)**:
  - Genre dewasa (Ecchi, Gore, Mature, dll.) disembunyikan secara default dari Eksplorasi & Pencarian demi keamanan pengguna anak di bawah umur.
  - Opsi "Tampilkan Genre Dewasa" tersedia di Settings dengan dialog konfirmasi.
- **Redesain UX Pemilihan Genre**:
  - Genre kini tampil sebagai grid kartu visual dengan gradien mood per genre (gelap untuk Horror, aksi untuk Shounen, dll) + ikon.
  - Multi-select responsif dengan indikator border menyala + badge checklist animasi.
  - Bottom sheet "Pilih Genre" (drag-expandable) + baris genre cepat & FAB "Genre" di Home.
  - Katalog mendukung filter beberapa genre sekaligus (hasil digabung otomatis).

---

## Apa yang Baru di v1.0.1

- **Universal Multi-ABI Support**:
  - Kompatibel penuh untuk arsitektur 64-bit (`arm64-v8a`) dan 32-bit (`armeabi-v7a`).
  - Mengatasi crash force-close saat startup pada perangkat lawas / low-RAM (mis. Samsung Galaxy J4).
  - Penambahan `android:largeHeap="true"` untuk stabilitas memori.
- **Optimasi Rust Scraper & Ketahanan Jaringan**:
  - Static shared connection pool (TCP Keep-Alive 60s, idle timeout 90s, connect timeout 10s, request timeout 15s).
  - Injeksi header anti-bot `Referer` dan `User-Agent` untuk menghindari blokir request gambar/chapter.
- **Transisi UI Instan (Zero Latency)**:
  - Render cover thumbnail dan judul seketika (0ms) saat masuk ke detail manga.
  - Skeleton loader beranimasi saat memuat daftar chapter di latar belakang.
- **Optimasi Memori Reader**:
  - Pembatasan resolusi decoding gambar reader (`memCacheWidth: 1080`) untuk mencegah kehabisan memori (OOM).
- **Branding Baru**:
  - App icon launcher resmi baru dengan proporsi logo terpusat (centered canvas).

---

## Screenshot Aplikasi

<p align="center">
  <img src="docs/screenshots/home.png" width="30%" alt="Katalog Home" />
  <img src="docs/screenshots/detail.png" width="30%" alt="Detail Manga" />
  <img src="docs/screenshots/reader.png" width="30%" alt="Reader" />
</p>

---

## Fitur Utama

- **Rust High-Performance Engine**:
  - Scraping & parsing HTML langsung di layer Rust native via `reqwest` & `scraper`.
  - Embedded local database SQLite via `rusqlite` bundled di Rust.
  - Bridge FFI cepat tanpa overhead serialisasi JSON runtime berlebih.
- **Multi-Source Provider**:
  - **Komiku** (`api.komiku.org`)
  - **KomikIndo** (`komikindo.ch`)
  - Switcher provider instan di AppBar.
- **Filter Genre & Kategori**:
  - Grid genre visual multi-select dengan kartu gradien mood + ikon per genre.
  - Dukungan filter beberapa genre sekaligus (union hasil + dedupe otomatis).
  - Baris genre cepat di Home & bottom sheet "Pilih Genre" via FAB.
- **Batasan Konten Sensitif**:
  - Genre dewasa (Ecchi, Gore, dll.) tersembunyi default; dapat diaktifkan dari Settings.
- **Katalog & Pencarian Cepat**:
  - Infinite scroll / Pagination katalog otomatis.
  - Live search filter per provider.
- **Bookmark & Riwayat Baca**:
  - Simpan manga favorit ke database lokal.
  - Catat riwayat chapter terakhir dibaca secara otomatis.
- **Offline Chapter Downloader & Reader**:
  - Download batch seluruh halaman chapter langsung ke storage disk lokal.
  - Tracking persentase unduhan real-time via Riverpod StateNotifier.
  - Offline reader bawaan untuk membaca tanpa koneksi internet langsung dari SQLite & disk.
- **Optimized Reader UX & Customization**:
  - Pilihan mode baca: **Vertical Continuous** (Webtoon) & **Horizontal Slide** (Page-by-page).
  - Mode **Manga RTL** (Right-to-Left) untuk komik Jepang.
  - Background color picker (Hitam, Abu Gelap, Sepia, Putih).
  - Night Mode Dim slider (redup layar pembaca 0% - 75%).
  - Page Scrubber slider & floating page counter.
  - Pinch-to-zoom gesture (`InteractiveViewer`).
  - Error fallback per halaman dengan tombol retry individual.
  - Navigasi chapter cepat: Prev / Next toolbar & modal list chapter.
- **Pengaturan & Manajemen Cache**:
  - Pilihan Tema: Sistem, Terang, Gelap.
  - Kustomisasi Warna Aksen (8 preset warna, adaptif Light/Dark).
  - Batasan konten sensitif (sembunyikan genre dewasa).
  - Preferensi default mode baca.
  - Pembersih cache gambar (memory & disk).
  - Manajemen riwayat database SQLite.
- **Branding & Android Support**:
  - App Icon launcher resmi Manga Neko.
  - Custom native Comic-panel Splash Screen.
  - Siap build APK Android Release (`arm64-v8a`, `armeabi-v7a`, `x86_64`).

---

## Arsitektur Teknis

```
mangareader_flutter/
├── lib/
│   ├── main.dart            # Main app entrypoint (~30 lines)
│   └── src/
│       ├── models/          # App settings & Dart models
│       ├── providers/       # State management (Riverpod)
│       ├── screens/         # Modular Screens (Home, Detail, Reader, Settings, etc)
│       ├── services/        # Download Service & File Manager
│       ├── widgets/         # Reusable UI components & Reader items
│       └── rust/            # Auto-generated Dart-Rust Bridge Bindings
├── rust/                    # Rust Core Backend
│   ├── src/
│   │   ├── api/
│   │   │   ├── models.rs    # Data structs & Source Enums
│   │   │   ├── komiku.rs    # Scraper & genre parser provider Komiku
│   │   │   ├── komikindo.rs # Scraper & genre parser provider KomikIndo
│   │   │   ├── db.rs        # SQLite Local Database (Bookmarks & History)
│   │   │   └── mod.rs       # Public FFI endpoints
│   │   └── lib.rs
│   └── tests/               # Unit & integration tests Rust
├── android/                 # Android Native Runner & Native jniLibs
└── pubspec.yaml
```

---

## Prasyarat Lingkungan

- **Flutter SDK**: `>= 3.13.2`
- **Rust Toolchain**: `cargo`, `rustc` (edition 2021)
- **Rust Android Targets**: `aarch64-linux-android`, `armv7-linux-androideabi`, `x86_64-linux-android`
- **Android SDK & NDK**: Android SDK 36, NDK r28c / r26d
- **flutter_rust_bridge_codegen**: `v2.13.0`
- **cargo-ndk**: `v4.1.2`

---

## Cara Menjalankan Project

1. **Clone repository**:
   ```bash
   git clone https://github.com/Rafreaks06/Manga-Neko.git
   cd Manga-Neko
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate Code Bridge (jika mengubah Rust code)**:
   ```bash
   flutter_rust_bridge_codegen generate
   ```

4. **Jalankan Unit Test Rust**:
   ```bash
   cd rust
   cargo test
   cd ..
   ```

5. **Jalankan Aplikasi**:
   ```bash
   # Di Linux Desktop
   flutter run -d linux

   # Di Android Device / Emulator
   flutter run -d android
   ```

6. **Build Release APK Android**:
   ```bash
   # Build APK Release Universal (32-bit & 64-bit)
   flutter build apk --release --target-platform android-arm,android-arm64
   ```

---

## Lisensi
MIT License.
