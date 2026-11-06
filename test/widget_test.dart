import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clube_dos_pets_offline/core/di/providers.dart';
import 'package:clube_dos_pets_offline/main.dart';

void main() {
  testWidgets('app inicia com a composição de dependências', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ClubeDosPetsApp(),
    ));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
