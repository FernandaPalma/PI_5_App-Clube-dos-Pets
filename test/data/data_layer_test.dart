import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clube_dos_pets_offline/features/pets/data/datasources/auth_datasource.dart';
import 'package:clube_dos_pets_offline/features/pets/data/datasources/local_json_store.dart';
import 'package:clube_dos_pets_offline/features/pets/data/datasources/pets_datasource.dart';
import 'package:clube_dos_pets_offline/features/pets/data/models/pets_models.dart';
import 'package:clube_dos_pets_offline/features/pets/data/repositories/pets_repository_impl.dart';
import 'package:clube_dos_pets_offline/features/pets/data/security/password_hasher.dart';
import 'package:clube_dos_pets_offline/features/pets/domain/failures/pets_failures.dart';

class _FailingPetsDataSource implements PetsDataSource {
  @override Future<List<LugarModel>> lugares() async => throw const FormatException('json corrompido');
  @override Future<List<AvaliacaoModel>> avaliacoes() async => throw const FormatException('json corrompido');
  @override Future<List<String>> favoritos(String userId) async => throw const FormatException('json corrompido');
  @override Future<void> toggleFavorito(String userId, String lugarId) async => throw const FormatException('json corrompido');
  @override Future<void> addLugar(LugarModel lugar) async => throw const FormatException('json corrompido');
  @override Future<void> avaliar(AvaliacaoModel avaliacao) async => throw const FormatException('json corrompido');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late LocalJsonStore store;
  late AuthLocalDataSource auth;
  late PetsLocalDataSource pets;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = LocalJsonStore(prefs);
    auth = AuthLocalDataSource(store: store, hasher: PasswordHasher());
    pets = PetsLocalDataSource(store);
  });

  group('AuthLocalDataSource', () {
    test('cadastra, abre sessão e permite novo login', () async {
      final u = await auth.cadastrar(nome: 'Ana', email: 'ana@pets.com', senha: 'segredo1');
      expect((await auth.usuarioAtual())?.id, u.id);

      await auth.sair();
      expect(await auth.usuarioAtual(), isNull);

      final logado = await auth.login(email: 'ana@pets.com', senha: 'segredo1');
      expect(logado.id, u.id);
      expect((await auth.usuarioAtual())?.id, u.id);
    });

    test('não grava a senha em texto puro', () async {
      await auth.cadastrar(nome: 'Ana', email: 'ana@pets.com', senha: 'segredo1');
      expect(prefs.getString(LocalKeys.usuarios), isNot(contains('segredo1')));
    });

    test('rejeita e-mail duplicado', () async {
      await auth.cadastrar(nome: 'Ana', email: 'ana@pets.com', senha: 'segredo1');
      await expectLater(
        auth.cadastrar(nome: 'Outra', email: 'ana@pets.com', senha: 'segredo2'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('rejeita senha errada e e-mail inexistente', () async {
      await auth.cadastrar(nome: 'Ana', email: 'ana@pets.com', senha: 'segredo1');
      await expectLater(auth.login(email: 'ana@pets.com', senha: 'errada'), throwsA(isA<AuthFailure>()));
      await expectLater(auth.login(email: 'x@pets.com', senha: 'segredo1'), throwsA(isA<AuthFailure>()));
    });
  });

  group('PetsLocalDataSource', () {
    test('popula os lugares de demonstração uma única vez', () async {
      expect(await pets.lugares(), hasLength(4));
      expect(await pets.lugares(), hasLength(4));
    });

    test('addLugar preserva os dados de demonstração', () async {
      await pets.addLugar(const LugarModel(id: 'n1', nome: 'Novo', categoria: 'Parques', cidade: 'Campinas', descricao: ''));
      final lista = await pets.lugares();
      expect(lista, hasLength(5));
      expect(lista.last.nome, 'Novo');
    });

    test('toggleFavorito adiciona e remove por usuário', () async {
      await pets.toggleFavorito('u1', 'demo1');
      expect(await pets.favoritos('u1'), ['demo1']);
      expect(await pets.favoritos('u2'), isEmpty);
      await pets.toggleFavorito('u1', 'demo1');
      expect(await pets.favoritos('u1'), isEmpty);
    });

    test('avaliar substitui a avaliação anterior do mesmo usuário no mesmo lugar', () async {
      await pets.avaliar(const AvaliacaoModel(id: 'a1', lugarId: 'demo1', usuarioId: 'u1', autor: 'Ana', nota: 3, comentario: 'ok'));
      await pets.avaliar(const AvaliacaoModel(id: 'a2', lugarId: 'demo1', usuarioId: 'u1', autor: 'Ana', nota: 5, comentario: 'ótimo'));
      final lista = await pets.avaliacoes();
      expect(lista, hasLength(1));
      expect(lista.single.nota, 5);
    });
  });

  group('PetsRepositoryImpl', () {
    test('converte models em entidades sem expor credenciais', () async {
      final repo = PetsRepositoryImpl(auth: auth, pets: pets);
      final u = await repo.cadastrar('Ana', 'ana@pets.com', 'segredo1');
      expect(u.email, 'ana@pets.com');
      expect((await repo.lugares()), hasLength(4));
    });

    test('propaga PetsFailure sem converter', () async {
      final repo = PetsRepositoryImpl(auth: auth, pets: pets);
      await expectLater(repo.login('x@pets.com', 'qualquer'), throwsA(isA<AuthFailure>()));
    });

    test('converte erros inesperados em StorageFailure', () async {
      final repo = PetsRepositoryImpl(auth: auth, pets: _FailingPetsDataSource());
      await expectLater(repo.lugares(), throwsA(isA<StorageFailure>()));
    });
  });
}
