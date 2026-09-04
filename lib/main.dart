import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:mangareader_flutter/src/providers/app_providers.dart';
import 'package:mangareader_flutter/src/screens/main_navigation_screen.dart';
import 'package:mangareader_flutter/src/rust/api.dart' as rust_api;
import 'package:mangareader_flutter/src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  final prefs = await SharedPreferences.getInstance();
  final docDir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(docDir.path, 'mangareader.db');
  await rust_api.initDatabase(dbPath: dbPath);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MangaApp(),
    ),
  );
}
