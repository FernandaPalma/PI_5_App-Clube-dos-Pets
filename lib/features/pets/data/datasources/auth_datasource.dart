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
  });
  Future<UsuarioModel> login({required String email, required String senha});
  Future<void> sair();
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
}
