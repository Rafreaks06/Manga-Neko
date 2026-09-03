# Manga Neko (Flutter + Rust Core)

Aplikasi Manga & Manhwa Reader multi-platform berbasis **Flutter** dengan backend engine berkekuatan tinggi menggunakan **Rust** via `flutter_rust_bridge` v2.

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
- **Katalog & Pencarian Cepat**:
  - Infinite scroll / Pagination katalog otomatis.
  - Live search filter per provider.
- **Bookmark & Riwayat Baca**:
  - Simpan manga favorit ke database lokal.
  - Catat riwayat chapter terakhir dibaca secara otomatis.
- **Optimized Reader UX**:
  - Continuous vertical webtoon-style reader.
  - Pinch-to-zoom gesture (`InteractiveViewer`).
  - Indikator counter nomor halaman per gambar (`Page X/Y`).
  - Error fallback per halaman dengan tombol **Coba Lagi** (retry individual).
  - Navigasi chapter cepat: Prev / Next toolbar & modal list chapter.
  - Optimasi memori: Streaming gambar langsung tanpa penumpukan cache disk berlebih.

---

## Arsitektur Teknis

```
mangareader_flutter/
├── lib/                     # Flutter UI Layer
│   ├── main.dart            # State Management (Riverpod), Screens & Navigation
│   └── src/rust/            # Auto-generated Dart-Rust Bridge Bindings
├── rust/                    # Rust Core Backend
│   ├── src/
│   │   ├── api/
│   │   │   ├── models.rs    # Data structs & Source Enums
│   │   │   ├── komiku.rs    # Scraper provider Komiku
│   │   │   ├── komikindo.rs # Scraper provider KomikIndo
│   │   │   ├── db.rs        # SQLite Local Database (Bookmarks & History)
│   │   │   └── mod.rs       # Public FFI endpoints
│   │   └── lib.rs
│   └── tests/               # Unit & integration tests Rust
└── pubspec.yaml
```

---

## Prasyarat Lingkungan

- **Flutter SDK**: `>= 3.13.2`
- **Rust Toolchain**: `cargo`, `rustc` (edition 2021)
- **flutter_rust_bridge_codegen**: `v2.13.0`

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

---

## Lisensi
MIT License.
