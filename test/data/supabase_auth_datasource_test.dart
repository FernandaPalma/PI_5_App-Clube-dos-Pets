import 'dart:convert';

import 'package:clube_dos_pets_offline/features/pets/data/datasources/supabase_auth_datasource.dart';
import 'package:clube_dos_pets_offline/features/pets/domain/failures/pets_failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const usuario = <String, dynamic>{
  'id': '11111111-1111-4111-8111-111111111111',
  'email': 'teste@exemplo.test',
  'aud': 'authenticated',
  'role': 'authenticated',
  'user_metadata': {'nome': 'Pessoa de teste'},
};

http.Response jsonResponse(Object dados, [int status = 200]) => http.Response(
      jsonEncode(dados),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> sessao() {
  String parte(Object valor) =>
      base64Url.encode(utf8.encode(jsonEncode(valor))).replaceAll('=', '');

  final cabecalho = parte({'alg': 'HS256', 'typ': 'JWT'});
  final payload = parte({
    'sub': usuario['id'],
    'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
    'role': 'authenticated',
  });

  return {
    'access_token': '$cabecalho.$payload.c2lnbmF0dXJl',
    'refresh_token': 'refresh-simulado',
    'token_type': 'bearer',
    'expires_in': 3600,
    'user': usuario,
  };
}

SupabaseClient clienteTeste(
  Future<http.Response> Function(http.Request) responder,
) {
  final transporte = MockClient((request) async {
    final response = await responder(request);
    return http.Response.bytes(
      response.bodyBytes,
      response.statusCode,
      request: request,
      headers: {
        ...response.headers,
        if (request.url.path.startsWith('/auth/v1/'))
          'x-supabase-api-version': '2024-01-01',
      },
    );
  });
  final client = SupabaseClient(
    'https://teste.invalid',
    'sb_publishable_teste',
    httpClient: transporte,
    authOptions: const AuthClientOptions(
      autoRefreshToken: false,
      authFlowType: AuthFlowType.implicit,
    ),
  );

  addTearDown(() async {
    await client.dispose();
    transporte.close();
  });

  return client;
}

void main() {
  test('cadastro sem sessão orienta confirmação e não grava perfil', () async {
    final pedidos = <http.Request>[];

    final client = clienteTeste((r) async {
      pedidos.add(r);
      if (r.url.path == '/auth/v1/signup') {
        expect(jsonDecode(r.body)['data'], {'nome': 'Pessoa de teste'});
        return jsonResponse(usuario);
      }
      fail('Requisição inesperada: ${r.method} ${r.url.path}');
    });

    final auth = SupabaseAuthDataSource(client);
    expect(await auth.usuarioAtual(), isNull);

    await expectLater(
      auth.cadastrar(
        nome: 'Pessoa de teste',
        email: 'teste@exemplo.test',
        senha: 'Teste123!',
      ),
      throwsA(isA<AuthFailure>().having(
        (e) => e.message,
        'orientação',
        contains('confirmar'),
      )),
    );

    expect(client.auth.currentSession, isNull);
    expect(pedidos, hasLength(1));
  });

  test('login cria perfil sem credenciais e sair remove a sessão', () async {
    Map<String, dynamic>? perfil;
    var gravacoes = 0;

    final client = clienteTeste((r) async {
      if (r.url.path == '/auth/v1/token') return jsonResponse(sessao());
      if (r.url.path == '/auth/v1/logout') return http.Response('', 204);

      if (r.url.path == '/rest/v1/perfis') {
        expect(r.headers['authorization'], startsWith('Bearer '));

        if (r.method == 'POST') {
          perfil = Map<String, dynamic>.from(jsonDecode(r.body) as Map);
          gravacoes++;

          expect(perfil, {
            'id': usuario['id'],
            'nome': 'Pessoa de teste',
            'email': usuario['email'],
          });
          expect(
            r.headers['prefer'],
            contains('resolution=ignore-duplicates'),
          );
          return http.Response('', 201);
        }

        expect(r.url.queryParameters['id'], 'eq.${usuario['id']}');
        return jsonResponse(perfil == null ? [] : [perfil]);
      }

      fail('Requisição inesperada: ${r.method} ${r.url.path}');
    });

    final auth = SupabaseAuthDataSource(client);
    final pessoa = await auth.login(
      email: 'teste@exemplo.test',
      senha: 'Teste123!',
    );

    expect(pessoa.id, usuario['id']);
    expect(pessoa.senhaHash, isEmpty);
    expect(pessoa.salt, isEmpty);

    perfil!['nome'] = 'Nome editado';
    expect((await auth.usuarioAtual())?.nome, 'Nome editado');
    expect(gravacoes, 1);

    await auth.sair();
    expect(client.auth.currentSession, isNull);
    expect(await auth.usuarioAtual(), isNull);
  });

  test('senha inválida não autentica nem acessa perfis', () async {
    final client = clienteTeste((r) async {
      expect(r.url.path, '/auth/v1/token');
      return jsonResponse({
        'code': 'invalid_credentials',
        'message': 'Invalid login credentials',
      }, 400);
    });

    await expectLater(
      SupabaseAuthDataSource(client).login(
        email: 'teste@exemplo.test',
        senha: 'incorreta',
      ),
      throwsA(isA<AuthFailure>().having(
        (e) => e.message,
        'mensagem',
        'E-mail ou senha inválidos.',
      )),
    );

    expect(client.auth.currentSession, isNull);
  });
}
