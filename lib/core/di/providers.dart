import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/pets/data/datasources/auth_datasource.dart';
import '../../features/pets/data/datasources/local_json_store.dart';
import '../../features/pets/data/datasources/pets_datasource.dart';
import '../../features/pets/data/repositories/pets_repository_impl.dart';
import '../../features/pets/data/security/password_hasher.dart';
import '../../features/pets/domain/repositories/pets_repository.dart';
import '../../features/pets/domain/usecases/pets_usecases.dart';
import '../../features/pets/presentation/controllers/pets_controller.dart';

/// Sobrescrito em main() (e nos testes) com a instância já carregada.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
      'Sobrescreva sharedPreferencesProvider no ProviderScope.'),
);

final localJsonStoreProvider =
    Provider<LocalJsonStore>((ref) => LocalJsonStore(ref.watch(sharedPreferencesProvider)));

// Ao integrar o Supabase, troque APENAS estes dois providers por
// implementações de AuthDataSource / PetsDataSource.
final authDataSourceProvider = Provider<AuthDataSource>((ref) =>
    AuthLocalDataSource(
        store: ref.watch(localJsonStoreProvider), hasher: PasswordHasher()));

final petsDataSourceProvider = Provider<PetsDataSource>(
    (ref) => PetsLocalDataSource(ref.watch(localJsonStoreProvider)));

final repositoryProvider = Provider<PetsRepository>((ref) => PetsRepositoryImpl(
      auth: ref.watch(authDataSourceProvider),
      pets: ref.watch(petsDataSourceProvider),
    ));

final appProvider = StateNotifierProvider<PetsController, PetsState>((ref) {
  final repository = ref.read(repositoryProvider);
  return PetsController(
    carregarPets: CarregarPets(repository),
    cadastrarUsuario: CadastrarUsuario(repository),
    entrar: Entrar(repository),
    sairUseCase: Sair(repository),
    alternarFavorito: AlternarFavorito(repository),
    cadastrarEstabelecimento: CadastrarLugar(repository),
    avaliarLugar: AvaliarLugar(repository),
  )..carregar();
});
