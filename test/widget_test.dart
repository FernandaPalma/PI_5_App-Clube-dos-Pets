import 'package:clube_dos_pets_offline/core/di/providers.dart';
import 'package:clube_dos_pets_offline/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> aguardar(WidgetTester tester) async {
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 10),
  );
}

Future<ProviderContainer> abrirApp(
  WidgetTester tester, {
  bool autenticado = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const ClubeDosPetsApp(),
  ));
  await aguardar(tester);

  final container = ProviderScope.containerOf(
    tester.element(find.byType(ClubeDosPetsApp)),
    listen: false,
  );

  if (autenticado) {
    await container.read(appProvider.notifier).cadastrar(
          'Conta de teste',
          'teste@exemplo.test',
          'Teste123!',
        );
    await aguardar(tester);
    expect(container.read(appProvider).usuario, isNotNull);
    expect(find.byType(NavigationBar), findsOneWidget);
  }

  return container;
}

Finder destino(String texto) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(texto),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Visitante inicia na tela de login', (tester) async {
    await abrirApp(tester);

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Bem-vindo de volta!'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Locais filtra os estabelecimentos pela cidade', (tester) async {
    final container = await abrirApp(tester, autenticado: true);
    final controller = container.read(appProvider.notifier);

    await controller.cadastrarLugar(
      nome: 'Local Alfa TestePI',
      categoria: 'Outros',
      cidade: 'Campinas TestePI',
      descricao: 'Dados exclusivos do teste.',
      endereco: '',
      telefone: '',
    );
    await controller.cadastrarLugar(
      nome: 'Local Beta TestePI',
      categoria: 'Outros',
      cidade: 'Santos TestePI',
      descricao: 'Dados exclusivos do teste.',
      endereco: '',
      telefone: '',
    );

    await aguardar(tester);
    await tester.tap(destino('Locais'));
    await aguardar(tester);

    final busca = find.byType(TextField);
    expect(busca, findsOneWidget);

    await tester.enterText(busca, 'TestePI');
    await aguardar(tester);
    expect(find.text('Local Alfa TestePI'), findsOneWidget);
    expect(find.text('Local Beta TestePI'), findsOneWidget);

    await tester.enterText(busca, 'Campinas TestePI');
    await aguardar(tester);
    expect(find.text('Local Alfa TestePI'), findsOneWidget);
    expect(find.text('Local Beta TestePI'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Favoritos mostra lista vazia para uma conta nova',
      (tester) async {
    await abrirApp(tester, autenticado: true);
    await tester.tap(destino('Favoritos'));
    await aguardar(tester);

    expect(find.text('Meus favoritos'), findsOneWidget);
    expect(find.text('Você ainda não salvou favoritos.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
