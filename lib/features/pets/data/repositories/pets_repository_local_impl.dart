import '../../domain/entities/pets_entities.dart';
import '../../domain/repositories/pets_repository.dart';
import '../datasources/local_pets_datasource.dart';

class PetsRepositoryLocalImpl implements PetsRepository {
  final LocalPetsDataSource local;
  PetsRepositoryLocalImpl(this.local);

  @override Future<void> seed() => local.seed();
  @override Future<Usuario?> usuarioAtual() => local.usuarioAtual();
  @override Future<List<Lugar>> lugares() => local.lugares();
  @override Future<List<Avaliacao>> avaliacoes() => local.avaliacoes();
  @override Future<List<String>> favoritos(String userId) => local.favoritos(userId);
  @override Future<Usuario> cadastrar(String nome, String email, String senha) => local.cadastrar(nome,email,senha);
  @override Future<Usuario> login(String email, String senha) => local.login(email,senha);
  @override Future<void> sair() => local.sair();
  @override Future<void> toggleFavorito(String userId,String lugarId) => local.toggleFavorito(userId,lugarId);
  @override Future<void> addLugar(Lugar lugar) => local.addLugar(lugar);
  @override Future<void> avaliar(Avaliacao avaliacao) => local.avaliar(avaliacao);
}
