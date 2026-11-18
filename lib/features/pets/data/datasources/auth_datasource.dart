import 'dart:typed_data';

import '../../domain/entities/pets_entities.dart';
import '../../domain/failures/pets_failures.dart';
import '../models/pets_models.dart';
import '../security/password_hasher.dart';
import 'local_json_store.dart';

/// Fonte de dados de autenticação. Trocar por Supabase = nova implementação.
abstract interface class AuthDataSource {
  Future<UsuarioModel?> usuarioAtual();
  Future<UsuarioModel> cadastrar({
    required String nome,
    required String email,
    required String senha,
    TipoConta tipo = TipoConta.tutor,
  });
  Future<UsuarioModel> login({required String email, required String senha});
  Future<void> sair();
  Future<UsuarioModel> atualizarNome(String nome);
  Future<UsuarioModel> atualizarFoto({
    required Uint8List bytes,
    required String mimeType,
  });
  Future<UsuarioModel> removerFoto();
  Future<UsuarioModel> alterarTipoConta(TipoConta tipo);
  Future<void> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  });
}

/// Autenticação local, SOMENTE para demonstração.
/// Validação de entrada e normalização do e-mail ficam nos casos de uso.
class AuthLocalDataSource implements AuthDataSource {
  AuthLocalDataSource({
    required LocalJsonStore store,
    required PasswordHasher hasher,
    String Function()? idGenerator,
  })  : _store = store,
        _hasher = hasher,
        _newId = idGenerator ?? _timestampId;

  final LocalJsonStore _store;
  final PasswordHasher _hasher;
  final String Function() _newId;

  static String _timestampId() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  List<UsuarioModel> _usuarios() =>
      _store.readList(LocalKeys.usuarios).map(UsuarioModel.fromJson).toList();

  @override
  Future<UsuarioModel?> usuarioAtual() async {
    final id = _store.readString(LocalKeys.sessao);
    if (id == null) return null;
    for (final u in _usuarios()) {
      if (u.id == id) return u;
    }
    return null;
  }

  @override
  Future<UsuarioModel> cadastrar({
    required String nome,
    required String email,
    required String senha,
    TipoConta tipo = TipoConta.tutor,
  }) async {
    final lista = _store.readList(LocalKeys.usuarios);
    if (lista.any((j) => j['email'] == email)) {
      throw const AuthFailure('E-mail já cadastrado.');
    }
    final salt = _hasher.generateSalt();
    final usuario = UsuarioModel(
      id: _newId(),
      nome: nome,
      email: email,
      senhaHash: _hasher.hash(senha, salt),
      salt: salt,
      tipo: tipo,
    );
    lista.add(usuario.toJson());
    await _store.writeList(LocalKeys.usuarios, lista);
    await _store.writeString(LocalKeys.sessao, usuario.id);
    return usuario;
  }

  @override
  Future<UsuarioModel> login({
    required String email,
    required String senha,
  }) async {
    for (final u in _usuarios()) {
      if (u.email == email && _hasher.verify(senha, u.salt, u.senhaHash)) {
        await _store.writeString(LocalKeys.sessao, u.id);
        return u;
      }
    }
    throw const AuthFailure('E-mail ou senha inválidos.');
  }

  @override
  Future<void> sair() => _store.remove(LocalKeys.sessao);

  Future<UsuarioModel> _logado() async {
    final u = await usuarioAtual();
    if (u == null) throw const AuthFailure('Entre na sua conta.');
    return u;
  }

  Future<UsuarioModel> _salvar(UsuarioModel novo) async {
    final lista = _store.readList(LocalKeys.usuarios);
    final i = lista.indexWhere((j) => j['id'] == novo.id);
    if (i < 0) throw const AuthFailure('Conta não encontrada.');
    lista[i] = novo.toJson();
    await _store.writeList(LocalKeys.usuarios, lista);
    return novo;
  }

  @override
  Future<UsuarioModel> atualizarNome(String nome) async =>
      _salvar((await _logado()).copyWith(nome: nome));

  @override
  Future<UsuarioModel> atualizarFoto({
    required Uint8List bytes,
    required String mimeType,
  }) async =>
      throw const AuthFailure(
          'Foto de perfil só está disponível com conta online (Supabase).');

  @override
  Future<UsuarioModel> removerFoto() async => _logado();

  @override
  Future<UsuarioModel> alterarTipoConta(TipoConta tipo) async =>
      _salvar((await _logado()).copyWith(tipo: tipo));

  @override
  Future<void> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    final u = await _logado();
    if (!_hasher.verify(senhaAtual, u.salt, u.senhaHash)) {
      throw const AuthFailure('Senha atual incorreta.');
    }
    final salt = _hasher.generateSalt();
    await _salvar(
        u.copyWith(senhaHash: _hasher.hash(novaSenha, salt), salt: salt));
  }
}
