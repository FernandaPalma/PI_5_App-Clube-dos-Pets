import '../models/pets_models.dart';
import 'local_json_store.dart';

/// Fonte de dados de lugares, avaliações e favoritos.
abstract interface class PetsDataSource {
  Future<List<LugarModel>> lugares();
  Future<List<AvaliacaoModel>> avaliacoes();
  Future<List<String>> favoritos(String userId);
  Future<void> toggleFavorito(String userId, String lugarId);
  Future<void> addLugar(LugarModel lugar);
  Future<void> avaliar(AvaliacaoModel avaliacao);
}

class PetsLocalDataSource implements PetsDataSource {
  PetsLocalDataSource(this._store);
  final LocalJsonStore _store;

  static const _seedLugares = <LugarModel>[
    LugarModel(
        id: 'demo1',
        nome: 'Parque dos Amigos',
        categoria: 'Parques',
        cidade: 'São Paulo',
        descricao: 'Área verde e espaço para passear com seu pet.',
        endereco: 'São Paulo - SP'),
    LugarModel(
        id: 'demo2',
        nome: 'Clínica Patinhas',
        categoria: 'Veterinários',
        cidade: 'Campinas',
        descricao: 'Consultas e cuidados veterinários.',
        endereco: 'Campinas - SP'),
    LugarModel(
        id: 'demo3',
        nome: 'Hotel AuMiau',
        categoria: 'Hotéis pet',
        cidade: 'Rio Claro',
        descricao: 'Hospedagem e recreação para cães e gatos.',
        endereco: 'Rio Claro - SP'),
    LugarModel(
        id: 'demo4',
        nome: 'Café Pet Friendly',
        categoria: 'Restaurantes',
        cidade: 'São Paulo',
        descricao: 'Café com espaço para tutores e seus animais.',
        endereco: 'São Paulo - SP'),
  ];

  /// Popula os dados de demonstração uma única vez (antes era `seed()` no contrato do domínio).
  Future<void> _seedIfNeeded() async {
    if (_store.contains(LocalKeys.lugares)) return;
    await _store.writeList(
        LocalKeys.lugares, _seedLugares.map((l) => l.toJson()).toList());
  }

  @override
  Future<List<LugarModel>> lugares() async {
    await _seedIfNeeded();
    return _store.readList(LocalKeys.lugares).map(LugarModel.fromJson).toList();
  }

  @override
  Future<void> addLugar(LugarModel lugar) async {
    await _seedIfNeeded();
    final lista = _store.readList(LocalKeys.lugares)..add(lugar.toJson());
    await _store.writeList(LocalKeys.lugares, lista);
  }

  @override
  Future<List<AvaliacaoModel>> avaliacoes() async => _store
      .readList(LocalKeys.avaliacoes)
      .map(AvaliacaoModel.fromJson)
      .toList();

  @override
  Future<void> avaliar(AvaliacaoModel avaliacao) async {
    final lista = _store.readList(LocalKeys.avaliacoes)
      ..removeWhere((e) =>
          e['usuarioId'] == avaliacao.usuarioId &&
          e['lugarId'] == avaliacao.lugarId)
      ..add(avaliacao.toJson());
    await _store.writeList(LocalKeys.avaliacoes, lista);
  }

  @override
  Future<List<String>> favoritos(String userId) async => _store
      .readList(LocalKeys.favoritos)
      .where((j) => j['usuarioId'] == userId)
      .map((j) => '${j['lugarId']}')
      .toList();

  @override
  Future<void> toggleFavorito(String userId, String lugarId) async {
    final lista = _store.readList(LocalKeys.favoritos);
    final ix = lista.indexWhere(
        (e) => e['usuarioId'] == userId && e['lugarId'] == lugarId);
    if (ix >= 0) {
      lista.removeAt(ix);
    } else {
      lista.add({'usuarioId': userId, 'lugarId': lugarId});
    }
    await _store.writeList(LocalKeys.favoritos, lista);
  }
}
