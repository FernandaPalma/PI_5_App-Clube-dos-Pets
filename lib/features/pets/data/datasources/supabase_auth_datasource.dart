import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/pets_entities.dart';
import '../../domain/failures/pets_failures.dart';
import '../models/pets_models.dart';
import 'auth_datasource.dart';

class SupabaseAuthDataSource implements AuthDataSource {
  SupabaseAuthDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<UsuarioModel?> usuarioAtual() => _guard(() async {
        var session = _client.auth.currentSession;
        if (session == null) return null;

        if (session.isExpired) {
          try {
            session = (await _client.auth.refreshSession()).session;
          } on AuthException {
            if (_client.auth.currentSession == null) return null;
            rethrow;
          }
        }

        return session == null ? null : await _perfil(session.user);
      });

  @override
  Future<UsuarioModel> cadastrar({
    required String nome,
    required String email,
    required String senha,
    TipoConta tipo = TipoConta.tutor,
  }) =>
      _guard(() async {
        final resposta = await _client.auth.signUp(
          email: email.trim().toLowerCase(),
          password: senha,
          data: {'nome': nome.trim(), 'tipo': tipo.name},
        );

        if (resposta.user == null) {
          throw const AuthFailure('Não foi possível concluir o cadastro.');
        }

        if (resposta.session == null) {
          throw const AuthFailure(
            'Verifique seu e-mail para confirmar o cadastro. '
            'Depois, toque em "Já tenho uma conta" para entrar.',
          );
        }

        return _perfil(resposta.session!.user);
      });

  @override
  Future<UsuarioModel> login({
    required String email,
    required String senha,
  }) =>
      _guard(() async {
        final resposta = await _client.auth.signInWithPassword(
          email: email.trim().toLowerCase(),
          password: senha,
        );

        if (resposta.session == null) {
          throw const AuthFailure('Não foi possível iniciar a sessão.');
        }

        return _perfil(resposta.session!.user);
      });

  @override
  Future<void> sair() =>
      _guard(() => _client.auth.signOut(scope: SignOutScope.local));

  static const _bucketAvatares = 'avatares';

  @override
  Future<UsuarioModel> atualizarNome(String nome) => _guard(() async {
        final usuario = _usuarioLogado();
        final linha = await _client
            .from('perfis')
            .update({'nome': nome})
            .eq('id', usuario.id)
            .select('id')
            .maybeSingle();

        if (linha == null) {
          // Sem permissão de UPDATE em perfis (RLS) nenhuma linha é alterada.
          throw const StorageFailure(
            'Não foi possível salvar o nome. A permissão de edição do perfil '
            'ainda não foi aplicada no Supabase (migration 004).',
          );
        }

        await _client.auth.updateUser(UserAttributes(data: {'nome': nome}));
        return _perfil(_client.auth.currentUser ?? usuario);
      });

  @override
  Future<UsuarioModel> atualizarFoto({
    required Uint8List bytes,
    required String mimeType,
  }) =>
      _guard(() async {
        final usuario = _usuarioLogado();
        // Caminho fixo por usuário: cada envio substitui a foto anterior.
        final caminho = '${usuario.id}/avatar';
        final bucket = _client.storage.from(_bucketAvatares);

        await bucket.uploadBinary(
          caminho,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );

        // O parâmetro "v" evita que o app mostre a foto antiga em cache.
        final url = '${bucket.getPublicUrl(caminho)}'
            '?v=${DateTime.now().millisecondsSinceEpoch}';
        await _client.auth.updateUser(UserAttributes(data: {'foto_url': url}));
        return _perfil(_client.auth.currentUser ?? usuario);
      });

  @override
  Future<UsuarioModel> removerFoto() => _guard(() async {
        final usuario = _usuarioLogado();
        await _client.storage
            .from(_bucketAvatares)
            .remove(['${usuario.id}/avatar']);
        await _client.auth.updateUser(UserAttributes(data: {'foto_url': ''}));
        return _perfil(_client.auth.currentUser ?? usuario);
      });

  @override
  Future<UsuarioModel> alterarTipoConta(TipoConta tipo) => _guard(() async {
        final usuario = _usuarioLogado();
        await _client.auth.updateUser(UserAttributes(data: {'tipo': tipo.name}));
        return _perfil(_client.auth.currentUser ?? usuario);
      });

  @override
  Future<void> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) =>
      _guard(() async {
        final usuario = _usuarioLogado();
        final email = usuario.email;
        if (email == null || email.isEmpty) {
          throw const AuthFailure('Não foi possível confirmar sua conta.');
        }

        // Confirma a senha atual antes de trocar.
        try {
          await _client.auth
              .signInWithPassword(email: email, password: senhaAtual);
        } on AuthException catch (e) {
          if (e.code == 'invalid_credentials') {
            throw const AuthFailure('Senha atual incorreta.');
          }
          rethrow;
        }

        await _client.auth.updateUser(UserAttributes(password: novaSenha));
      });

  User _usuarioLogado() {
    final usuario = _client.auth.currentUser;
    if (usuario == null) {
      throw const AuthFailure('Entre novamente para continuar.');
    }
    return usuario;
  }

  Future<UsuarioModel> _perfil(User usuario) async {
    if (_client.auth.currentSession?.user.id != usuario.id) {
      throw const AuthFailure('Entre novamente para acessar seu perfil.');
    }

    var perfil = await _client
        .from('perfis')
        .select('id, nome, email')
        .eq('id', usuario.id)
        .maybeSingle();

    if (perfil == null) {
      // Senhas e credenciais ficam exclusivamente no Supabase Auth.
      await _client.from('perfis').upsert(
        {
          'id': usuario.id,
          'nome': usuario.userMetadata?['nome']?.toString() ?? '',
          'email': usuario.email ?? '',
        },
        onConflict: 'id',
        ignoreDuplicates: true,
      );

      perfil = await _client
          .from('perfis')
          .select('id, nome, email')
          .eq('id', usuario.id)
          .maybeSingle();
    }

    if (perfil == null) {
      throw const StorageFailure(
        'Não foi possível carregar seu perfil. Tente entrar novamente.',
      );
    }

    final foto = usuario.userMetadata?['foto_url']?.toString() ?? '';
    final tipo = usuario.userMetadata?['tipo']?.toString() ?? '';
    return UsuarioModel.fromJson({...perfil, 'foto_url': foto, 'tipo': tipo});
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PetsFailure catch (e) {
      if (kDebugMode) debugPrint('[PI-DOMINIO] ${e.message}');
      rethrow;
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint('[PI-AUTH] tipo=${e.runtimeType}; codigo=${e.code}; '
            'http=${e.statusCode}; mensagem=${e.message}');
      }
      throw AuthFailure(switch (e.code) {
        'invalid_credentials' => 'E-mail ou senha inválidos.',
        'email_not_confirmed' => 'Confirme seu e-mail antes de entrar.',
        'user_already_exists' || 'email_exists' => 'E-mail já cadastrado.',
        'weak_password' => 'Escolha uma senha mais forte.',
        'same_password' => 'A nova senha deve ser diferente da atual.',
        'email_address_invalid' => 'Informe um endereço de e-mail válido.',
        'over_email_send_rate_limit' ||
        'over_request_rate_limit' =>
          'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
        'email_address_not_authorized' =>
          'O envio de e-mail deste projeto ainda está restrito. '
              'A equipe precisa configurar o serviço de envio.',
        _ =>
          'Não foi possível autenticar. Verifique sua conexão e tente novamente.',
      });
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        debugPrint('[PI-PERFIL] codigo=${e.code}; mensagem=${e.message}');
      }
      throw const StorageFailure(
        'Não foi possível acessar seu perfil. Tente entrar novamente.',
      );
    } on StorageException catch (e) {
      if (kDebugMode) {
        debugPrint('[PI-STORAGE] http=${e.statusCode}; mensagem=${e.message}');
      }
      throw const StorageFailure(
        'Não foi possível enviar a foto. Confira se a migration 004 '
        '(bucket "avatares") foi aplicada no Supabase.',
      );
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('[PI-OUTRO] tipo=${e.runtimeType}');
      throw const StorageFailure(
        'Não foi possível conectar ao serviço. Tente novamente.',
      );
    }
  }
}
