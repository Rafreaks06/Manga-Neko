# Manga Neko (Flutter + Rust Core)

Aplikasi Manga & Manhwa Reader multi-platform berbasis **Flutter** dengan backend engine berkekuatan tinggi menggunakan **Rust** via `flutter_rust_bridge` v2.

---

## Download APK Android (Release)

Versi rilis APK siap install di HP Android:

- **Download**: [manga-neko-v1.0.0.apk](./releases/manga-neko-v1.0.0.apk) (atau cek di tab [GitHub Releases](https://github.com/Rafreaks06/Manga-Neko/releases))
- **Versi**: `v1.0.0`
- **Arsitektur**: `ARM64` (`arm64-v8a`)
- **Ukuran File**: `~38 MB`
- **Min Android SDK**: Android 5.0 (Lollipop) / Rekomendasi Android 10+

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
   # Build APK Release (ARM64)
   flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons
   ```

---

## Lisensi
MIT License.
