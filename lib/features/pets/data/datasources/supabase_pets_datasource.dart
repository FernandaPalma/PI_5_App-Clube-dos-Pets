import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/failures/pets_failures.dart';
import '../models/pets_models.dart';
import 'pets_datasource.dart';

class SupabasePetsDataSource implements PetsDataSource {
  SupabasePetsDataSource(this._client);

  final SupabaseClient _client;

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  String _usuario([String? esperado]) {
    final id = _client.auth.currentSession?.user.id;
    if (id == null || (esperado != null && esperado != id)) {
      throw const AuthFailure('Entre na sua conta para continuar.');
    }
    return id;
  }

  void _validarId(String id) {
    if (!_uuid.hasMatch(id)) {
      throw const ValidationFailure(
        'Selecione um estabelecimento salvo no aplicativo.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> _paginar(
    Future<List<Map<String, dynamic>>> Function(int, int) buscar,
  ) async {
    const tamanho = 200;
    final resultado = <Map<String, dynamic>>[];

    for (var inicio = 0;; inicio += tamanho) {
      final pagina = await buscar(inicio, inicio + tamanho - 1);
      resultado.addAll(pagina);
      if (pagina.length < tamanho) return resultado;
    }
  }

  Future<Map<String, String>> _categorias() async {
    final linhas = await _paginar(
      (i, f) =>
          _client.from('categorias').select('id, nome').order('id').range(i, f),
    );

    return {
      for (final linha in linhas) '${linha['id']}': '${linha['nome']}',
    };
  }

  LugarModel _lugar(
    Map<String, dynamic> linha,
    Map<String, String> categorias,
  ) =>
      LugarModel.fromJson({
        ...linha,
        'categoria': categorias[linha['categoria_id']?.toString()] ?? 'Outros',
      });

  @override
  Future<List<LugarModel>> lugares() => _guard(() async {
        final categorias = await _categorias();
        final linhas = await _paginar(
          (i, f) =>
              _client.from('estabelecimentos').select().order('id').range(i, f),
        );
        return linhas.map((l) => _lugar(l, categorias)).toList();
      });

  @override
  Future<List<AvaliacaoModel>> avaliacoes() => _guard(() async {
        final linhas = await _paginar(
          (i, f) => _client
              .from('avaliacoes')
              .select('id, usuario_id, estabelecimento_id, nota, comentario')
              .order('id')
              .range(i, f),
        );

        return linhas
            .map((a) => AvaliacaoModel.fromJson({
                  'id': a['id'],
                  'lugarId': a['estabelecimento_id'],
                  'usuarioId': a['usuario_id'],
                  'nota': a['nota'],
                  'comentario': a['comentario'],
                  // Perfis privados: esta consulta nao busca nomes ou e-mails.
                  'autor': a['usuario_id'] == _client.auth.currentUser?.id
                      ? 'Você'
                      : 'Usuário',
                }))
            .toList();
      });

  @override
  Future<List<String>> favoritos(String userId) => _guard(() async {
        final usuario = _usuario(userId);
        final linhas = await _paginar(
          (i, f) => _client
              .from('favoritos')
              .select('estabelecimento_id')
              .eq('usuario_id', usuario)
              .order('estabelecimento_id')
              .range(i, f),
        );
        return linhas.map((f) => f['estabelecimento_id'] as String).toList();
      });

  @override
  Future<void> toggleFavorito(String userId, String lugarId) =>
      _guard(() async {
        _usuario(userId);
        _validarId(lugarId);
        await _client.rpc(
          'alternar_favorito',
          params: {'p_estabelecimento_id': lugarId},
        );
      });

  @override
  Future<void> addLugar(LugarModel lugar) => _guard(() async {
        final usuario = _usuario();

        if (lugar.latitude != null || lugar.longitude != null) {
          _coordenadas(
            lugar.latitude ?? double.nan,
            lugar.longitude ?? double.nan,
          );
        }

        final categoria = await _client
            .from('categorias')
            .select('id')
            .eq('nome', lugar.categoria.trim())
            .maybeSingle();

        if (categoria == null) {
          throw const ValidationFailure(
            'Categoria indisponível. Atualize o aplicativo.',
          );
        }

        // O banco gera o UUID; o ID local do caso de uso nao e enviado.
        await _client.from('estabelecimentos').insert({
          'responsavel_id': usuario,
          'categoria_id': categoria['id'],
          'nome': lugar.nome,
          'cidade': lugar.cidade,
          'descricao': lugar.descricao,
          'endereco': lugar.endereco,
          'telefone': lugar.telefone,
          'latitude': lugar.latitude,
          'longitude': lugar.longitude,
        }, defaultToNull: false);
      });

  @override
  Future<void> avaliar(AvaliacaoModel avaliacao) => _guard(() async {
        final usuario = _usuario(avaliacao.usuarioId);
        _validarId(avaliacao.lugarId);

        if (avaliacao.nota < 1 || avaliacao.nota > 5) {
          throw const ValidationFailure('A nota deve estar entre 1 e 5.');
        }

        await _client.from('avaliacoes').upsert({
          'usuario_id': usuario,
          'estabelecimento_id': avaliacao.lugarId,
          'nota': avaliacao.nota,
          'comentario': avaliacao.comentario,
          'atualizado_em': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'usuario_id,estabelecimento_id', defaultToNull: false);
      });

  Future<List<LugarModel>> lugaresProximos({
    required double latitude,
    required double longitude,
    required double raioMetros,
  }) =>
      _guard(() async {
        _coordenadas(latitude, longitude);

        if (!raioMetros.isFinite || raioMetros < 0) {
          throw const ValidationFailure('Informe um raio válido em metros.');
        }

        final categorias = await _categorias();
        final linhas = await _paginar((i, f) async {
          final resultado = await _client.rpc(
            'buscar_locais_proximos',
            params: {
              'lat_ref': latitude,
              'lng_ref': longitude,
              'raio_metros': raioMetros,
            },
          ).range(i, f);

          return List<Map<String, dynamic>>.from(resultado as List);
        });

        return linhas.map((l) => _lugar(l, categorias)).toList();
      });

  void _coordenadas(double latitude, double longitude) {
    if (!latitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        !longitude.isFinite ||
        longitude < -180 ||
        longitude > 180) {
      throw const ValidationFailure('Informe latitude e longitude válidas.');
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PetsFailure {
      rethrow;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        debugPrint('[PI-DADOS] codigo=${e.code}; mensagem=${e.message}');
      }
      throw const StorageFailure(
        'Não foi possível acessar os dados. Tente novamente.',
      );
    } on AuthException {
      throw const AuthFailure(
        'Não foi possível validar a sessão. Entre novamente.',
      );
    } on Exception {
      throw const StorageFailure(
        'Não foi possível conectar ao serviço. Tente novamente.',
      );
    }
  }
}
