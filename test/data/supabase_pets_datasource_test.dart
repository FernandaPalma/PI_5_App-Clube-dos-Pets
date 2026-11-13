import 'dart:convert';

import 'package:clube_dos_pets_offline/features/pets/data/datasources/supabase_pets_datasource.dart';
import 'package:clube_dos_pets_offline/features/pets/data/models/pets_models.dart';
import 'package:clube_dos_pets_offline/features/pets/domain/failures/pets_failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _userId = '11111111-1111-4111-8111-111111111111';
const _lugarId = '22222222-2222-4222-8222-222222222222';
const _outroId = '33333333-3333-4333-8333-333333333333';

const _lugar = <String, dynamic>{
  'id': _lugarId,
  'categoria_id': 7,
  'nome': 'Local de teste',
  'cidade': 'Rio Claro',
  'descricao': '',
  'latitude': -22.355,
  'longitude': -47.381,
};

http.Response _json(Object valor) => http.Response(
      jsonEncode(valor),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Future<SupabaseClient> _cliente(
  Future<http.Response> Function(http.Request) responder,
) async {
  String parte(Object valor) =>
      base64Url.encode(utf8.encode(jsonEncode(valor))).replaceAll('=', '');

  final cabecalho = parte({'alg': 'HS256', 'typ': 'JWT'});
  final payload = parte({
    'sub': _userId,
    'role': 'authenticated',
    'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
  });
  final token = '$cabecalho.$payload.c2lnbmF0dXJl';

  final transporte = MockClient((request) async {
    final response = request.url.path == '/auth/v1/token'
        ? _json({
            'access_token': token,
            'refresh_token': 'simulado',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': _userId,
              'email': 'teste@exemplo.test',
              'aud': 'authenticated',
              'role': 'authenticated',
            },
          })
        : await responder(request);

    return http.Response.bytes(
      response.bodyBytes,
      response.statusCode,
      request: request,
      headers: {
        ...response.headers,
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

  await client.auth.signInWithPassword(
    email: 'teste@exemplo.test',
    password: 'Teste123!',
  );

  return client;
}

void main() {
  test('lugares mapeia categoria e continua lendo depois da primeira pagina',
      () async {
    var pagina = 0;

    final client = await _cliente((r) async {
      if (r.url.path == '/rest/v1/categorias') {
        return _json([
          {'id': 7, 'nome': 'Parques'}
        ]);
      }

      expect(r.url.path, '/rest/v1/estabelecimentos');
      expect(r.url.queryParameters['offset'], '${pagina * 200}');
      expect(r.url.queryParameters['limit'], '200');

      if (pagina++ == 0) {
        return _json(List.generate(
            200,
            (i) => {
                  ..._lugar,
                  'id':
                      '22222222-2222-4222-8222-${i.toString().padLeft(12, '0')}',
                }));
      }

      return _json([
        {..._lugar, 'nome': 'Ultimo local'}
      ]);
    });

    final lugares = await SupabasePetsDataSource(client).lugares();

    expect(lugares, hasLength(201));
    expect(lugares.first.categoria, 'Parques');
    expect(lugares.first.latitude, -22.355);
    expect(lugares.last.nome, 'Ultimo local');
    expect(pagina, 2);
  });

  test('cadastro envia responsavel e deixa o banco gerar o UUID', () async {
    var insercoes = 0;

    final client = await _cliente((r) async {
      if (r.url.path == '/rest/v1/categorias') {
        expect(r.url.queryParameters['nome'], 'eq.Parques');
        return _json([
          {'id': 7}
        ]);
      }

      expect(r.url.path, '/rest/v1/estabelecimentos');
      expect(r.method, 'POST');

      final corpo = jsonDecode(r.body) as Map<String, dynamic>;
      expect(corpo['responsavel_id'], _userId);
      expect(corpo['categoria_id'], 7);
      expect(corpo.containsKey('id'), isFalse);
      expect(corpo.containsKey('localizacao'), isFalse);
      expect(r.headers['prefer'], contains('missing=default'));

      insercoes++;
      return http.Response('', 201);
    });

    await SupabasePetsDataSource(client).addLugar(const LugarModel(
      id: 'id-local-123',
      nome: 'Local de teste',
      categoria: 'Parques',
      cidade: 'Rio Claro',
      descricao: '',
    ));

    expect(insercoes, 1);
  });

  test('favoritos usa a conta atual e alterna por RPC', () async {
    var pedidos = 0;

    final client = await _cliente((r) async {
      pedidos++;

      if (r.url.path == '/rest/v1/favoritos') {
        expect(r.url.queryParameters['usuario_id'], 'eq.$_userId');
        return _json([
          {'estabelecimento_id': _lugarId}
        ]);
      }

      expect(r.url.path, '/rest/v1/rpc/alternar_favorito');
      expect(jsonDecode(r.body), {'p_estabelecimento_id': _lugarId});
      return _json(false);
    });

    final fonte = SupabasePetsDataSource(client);

    await expectLater(
      fonte.favoritos(_outroId),
      throwsA(isA<AuthFailure>()),
    );
    await expectLater(
      fonte.toggleFavorito(_outroId, _lugarId),
      throwsA(isA<AuthFailure>()),
    );

    expect(pedidos, 0);
    expect(await fonte.favoritos(_userId), [_lugarId]);

    await fonte.toggleFavorito(_userId, _lugarId);
    expect(pedidos, 2);
  });

  test('avaliacoes preserva perfis privados e identifica a propria avaliacao',
      () async {
    final client = await _cliente((r) async {
      expect(r.url.path, '/rest/v1/avaliacoes');

      return _json([
        {
          'id': _lugarId,
          'usuario_id': _userId,
          'estabelecimento_id': _lugarId,
          'nota': 5,
          'comentario': 'Bom',
        },
        {
          'id': _outroId,
          'usuario_id': _outroId,
          'estabelecimento_id': _lugarId,
          'nota': 4,
          'comentario': null,
        },
      ]);
    });

    final lista = await SupabasePetsDataSource(client).avaliacoes();

    expect(lista.first.autor, 'Você');
    expect(lista.last.autor, 'Usuário');
    expect(lista.last.comentario, isEmpty);
  });

  test('avaliar usa conflito por usuario/local e rejeita nota fora da escala',
      () async {
    final notas = <int>[];

    final client = await _cliente((r) async {
      expect(r.url.path, '/rest/v1/avaliacoes');
      expect(
        r.url.queryParameters['on_conflict'],
        'usuario_id,estabelecimento_id',
      );
      expect(r.headers['prefer'], contains('resolution=merge-duplicates'));
      expect(r.headers['prefer'], contains('missing=default'));

      final corpo = jsonDecode(r.body) as Map<String, dynamic>;
      expect(corpo['usuario_id'], _userId);
      expect(corpo['estabelecimento_id'], _lugarId);
      expect(corpo.containsKey('id'), isFalse);
      expect(corpo.containsKey('autor'), isFalse);

      notas.add(corpo['nota'] as int);
      return http.Response('', 201);
    });

    final fonte = SupabasePetsDataSource(client);

    AvaliacaoModel avaliacao(int nota) => AvaliacaoModel(
          id: 'id-local',
          lugarId: _lugarId,
          usuarioId: _userId,
          autor: 'Nome local',
          nota: nota,
          comentario: 'Teste',
        );

    await expectLater(
      fonte.avaliar(avaliacao(6)),
      throwsA(isA<ValidationFailure>()),
    );

    expect(notas, isEmpty);

    await fonte.avaliar(avaliacao(5));
    await fonte.avaliar(avaliacao(3));

    expect(notas, [5, 3]);
  });

  test('proximidade valida coordenadas e envia o raio em metros', () async {
    var pedidos = 0;

    final client = await _cliente((r) async {
      pedidos++;

      if (r.url.path == '/rest/v1/categorias') {
        return _json([
          {'id': 7, 'nome': 'Parques'}
        ]);
      }

      expect(r.url.path, '/rest/v1/rpc/buscar_locais_proximos');
      expect(jsonDecode(r.body), {
        'lat_ref': -22.355,
        'lng_ref': -47.381,
        'raio_metros': 10000.0,
      });

      return _json([_lugar]);
    });

    final fonte = SupabasePetsDataSource(client);

    await expectLater(
      fonte.lugaresProximos(
        latitude: 91,
        longitude: 0,
        raioMetros: 10,
      ),
      throwsA(isA<ValidationFailure>()),
    );

    expect(pedidos, 0);

    final locais = await fonte.lugaresProximos(
      latitude: -22.355,
      longitude: -47.381,
      raioMetros: 10000,
    );

    expect(locais.single.id, _lugarId);
    expect(locais.single.categoria, 'Parques');
  });
}
