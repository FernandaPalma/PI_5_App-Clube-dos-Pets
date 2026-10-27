import '../entities/pets_entities.dart';

/// Contrato do domínio, independente de banco, Flutter ou rede.
abstract class PetsRepository {
  Future<void> seed();
  Future<Usuario?> usuarioAtual();
  Future<List<Lugar>> lugares();
  Future<List<Avaliacao>> avaliacoes();
  Future<List<String>> favoritos(String userId);
  Future<Usuario> cadastrar(String nome, String email, String senha);
  Future<Usuario> login(String email, String senha);
  Future<void> sair();
  Future<void> toggleFavorito(String userId, String lugarId);
  Future<void> addLugar(Lugar lugar);
  Future<void> avaliar(Avaliacao avaliacao);
}
