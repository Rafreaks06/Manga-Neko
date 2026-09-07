# Manga Neko (Flutter + Rust Core)

Aplikasi Manga & Manhwa Reader multi-platform berbasis **Flutter** dengan backend engine berkekuatan tinggi menggunakan **Rust** via `flutter_rust_bridge` v2.

---

## Download APK Android (Release)

Versi rilis APK siap install di HP Android:

- **Download Direct**: [manga-neko-v1.0.1.apk (GitHub Release)](https://github.com/Rafreaks06/Manga-Neko/releases/download/v1.0.1/manga-neko-v1.0.1.apk)
- **Download Lokal**: [manga-neko-v1.0.1.apk](./releases/manga-neko-v1.0.1.apk)
- **Semua Versi**: [GitHub Releases](https://github.com/Rafreaks06/Manga-Neko/releases)
- **Versi**: `v1.0.1`
- **Arsitektur**: Universal (`arm64-v8a` + `armeabi-v7a` 32-bit)
- **Ukuran File**: `~53 MB`
- **Min Android SDK**: Android 5.0 (Lollipop) / Rekomendasi Android 10+

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
  - Filter Chips horizontal dinamis (Action, Romance, Isekai, Fantasy, School Life, Supernatural, dll).
  - Pagination katalog otomatis mengikuti filter genre yang aktif.
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
