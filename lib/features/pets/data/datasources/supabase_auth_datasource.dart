import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  }) =>
      _guard(() async {
        final resposta = await _client.auth.signUp(
          email: email.trim().toLowerCase(),
          password: senha,
          data: {'nome': nome.trim()},
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

    return UsuarioModel.fromJson(perfil);
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
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('[PI-OUTRO] tipo=${e.runtimeType}');
      throw const StorageFailure(
        'Não foi possível conectar ao serviço. Tente novamente.',
      );
    }
  }
}
