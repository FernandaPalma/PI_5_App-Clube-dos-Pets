import '../../domain/entities/pets_entities.dart';
import '../../domain/failures/pets_failures.dart';
import '../../domain/repositories/pets_repository.dart';
import '../datasources/auth_datasource.dart';
import '../datasources/pets_datasource.dart';
import '../models/pets_models.dart';

/// Implementa o contrato do domínio sobre qualquer [AuthDataSource]/[PetsDataSource]
/// (local hoje, Supabase amanhã): converte Model <-> Entity e traduz erros
/// inesperados em [StorageFailure].
class PetsRepositoryImpl implements PetsRepository {
  PetsRepositoryImpl({required AuthDataSource auth, required PetsDataSource pets})
      : _auth = auth,
        _pets = pets;

  final AuthDataSource _auth;
  final PetsDataSource _pets;

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PetsFailure {
      rethrow;
    } catch (e) {
      throw StorageFailure('Falha ao acessar os dados: $e');
    }
  }

  @override
  Future<Usuario?> usuarioAtual() =>
      _guard(() async => (await _auth.usuarioAtual())?.toEntity());

  @override
  Future<Usuario> cadastrar(String nome, String email, String senha) =>
      _guard(() async => (await _auth
              .cadastrar(nome: nome, email: email, senha: senha))
          .toEntity());

  @override
  Future<Usuario> login(String email, String senha) => _guard(
      () async => (await _auth.login(email: email, senha: senha)).toEntity());

  @override
  Future<void> sair() => _guard(_auth.sair);

  @override
  Future<List<Lugar>> lugares() => _guard(
      () async => (await _pets.lugares()).map((m) => m.toEntity()).toList());

  @override
  Future<List<Avaliacao>> avaliacoes() => _guard(() async =>
      (await _pets.avaliacoes()).map((m) => m.toEntity()).toList());

  @override
  Future<List<String>> favoritos(String userId) =>
      _guard(() => _pets.favoritos(userId));

  @override
  Future<void> toggleFavorito(String userId, String lugarId) =>
      _guard(() => _pets.toggleFavorito(userId, lugarId));

  @override
  Future<void> addLugar(Lugar lugar) =>
      _guard(() => _pets.addLugar(LugarModel.fromEntity(lugar)));

  @override
  Future<void> avaliar(Avaliacao avaliacao) =>
      _guard(() => _pets.avaliar(AvaliacaoModel.fromEntity(avaliacao)));
}
