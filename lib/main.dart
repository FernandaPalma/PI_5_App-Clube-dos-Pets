import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/di/providers.dart';
import 'features/pets/presentation/pages/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const url = String.fromEnvironment('SUPABASE_URL');
  const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (url.isNotEmpty && publishableKey.isNotEmpty) {
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const ClubeDosPetsApp(),
  ));
}

class ClubeDosPetsApp extends StatelessWidget {
  const ClubeDosPetsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Clube dos Pets',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: petPrimary),
          scaffoldBackgroundColor: const Color(0xfff7f9fa),
          appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xfff7f9fa), foregroundColor: petDark),
          filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                  backgroundColor: petPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 19, vertical: 15))),
          inputDecorationTheme: InputDecorationTheme(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          cardTheme: CardThemeData(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 7),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)))),
      home: const AppShell());
}
