import 'dart:typed_data';

import '../entities/pets_entities.dart';

/// Contrato do domínio, independente de banco, Flutter ou rede.
///
/// Implementações lançam apenas [PetsFailure] (ver domain/failures).
abstract class PetsRepository {
  Future<Usuario?> usuarioAtual();
  Future<List<Lugar>> lugares();
  Future<List<Avaliacao>> avaliacoes();
  Future<List<String>> favoritos(String userId);
  Future<Usuario> cadastrar(
    String nome,
    String email,
    String senha, {
    TipoConta tipo = TipoConta.tutor,
  });
  Future<Usuario> login(String email, String senha);
  Future<void> sair();
  Future<Usuario> atualizarNome(String nome);
  Future<Usuario> atualizarFoto(Uint8List bytes, String mimeType);
  Future<Usuario> removerFoto();
  Future<void> alterarSenha(String senhaAtual, String novaSenha);
  Future<Usuario> alterarTipoConta(TipoConta tipo);
  Future<void> toggleFavorito(String userId, String lugarId);
  Future<void> addLugar(Lugar lugar);
  Future<void> avaliar(Avaliacao avaliacao);
}
