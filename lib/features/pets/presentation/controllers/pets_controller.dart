import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Necessário para chamar o Supabase.instance.client.rpc

import '../../domain/entities/pets_entities.dart';
import '../../domain/usecases/pets_usecases.dart';
import '../services/location_service.dart'; // Importe o serviço de geolocalização que criamos antes

class PetsState {
  const PetsState({
    this.loading = true,
    this.usuario,
    this.lugares = const [],
    this.favoritos = const [],
    this.avaliacoes = const [],
    this.erro,
  });
  final bool loading;
  final Usuario? usuario;
  final List<Lugar> lugares;
  final List<String> favoritos;
  final List<Avaliacao> avaliacoes;
  final String? erro;

  PetsState copyWith({
    bool? loading,
    Usuario? usuario,
    bool limparUsuario = false,
    List<Lugar>? lugares,
    List<String>? favoritos,
    List<Avaliacao>? avaliacoes,
    String? erro,
  }) => PetsState(
    loading: loading ?? this.loading,
    usuario: limparUsuario ? null : usuario ?? this.usuario,
    lugares: lugares ?? this.lugares,
    favoritos: favoritos ?? this.favoritos,
    avaliacoes: avaliacoes ?? this.avaliacoes,
    erro: erro,
  );

  double nota(String id) {
    final n = avaliacoes.where((a) => a.lugarId == id).toList();
    return n.isEmpty
        ? 0
        : n.map((a) => a.nota).reduce((a, b) => a + b) / n.length;
  }
}

class PetsController extends StateNotifier<PetsState> {
  PetsController({
    required this.carregarPets,
    required this.cadastrarUsuario,
    required this.entrar,
    required this.sairUseCase,
    required this.alternarFavorito,
    required this.cadastrarEstabelecimento,
    required this.avaliarLugar,
  }) : super(const PetsState());

  final CarregarPets carregarPets;
  final CadastrarUsuario cadastrarUsuario;
  final Entrar entrar;
  final Sair sairUseCase;
  final AlternarFavorito alternarFavorito;
  final CadastrarLugar cadastrarEstabelecimento;
  final AvaliarLugar avaliarLugar;

  Future<void> carregar() async {
    try {
      final resultado = await carregarPets();
      state = PetsState(
        loading: false,
        usuario: resultado.usuario,
        lugares: resultado.lugares,
        avaliacoes: resultado.avaliacoes,
        favoritos: resultado.favoritos,
      );
    } catch (e) {
      state = PetsState(
        loading: false,
        erro: 'Não foi possível carregar os dados locais: $e',
      );
    }
  }

  Future<void> cadastrar(String nome, String email, String senha) async {
    await cadastrarUsuario(nome, email, senha);
    await carregar();
  }

  Future<void> login(String email, String senha) async {
    await entrar(email, senha);
    await carregar();
  }

  Future<void> sair() async {
    await sairUseCase();
    await carregar();
  }

  Future<void> favorito(String lugarId) async {
    await alternarFavorito(state.usuario, lugarId);
    await carregar();
  }

  Future<void> cadastrarLugar({
    required String nome,
    required String categoria,
    required String cidade,
    required String descricao,
    required String endereco,
    required String telefone,
  }) async {
    await cadastrarEstabelecimento(
      usuario: state.usuario,
      nome: nome,
      categoria: categoria,
      cidade: cidade,
      descricao: descricao,
      endereco: endereco,
      telefone: telefone,
    );
    await carregar();
  }

  Future<void> avaliar(String id, int nota, String comentario) async {
    await avaliarLugar(
      usuario: state.usuario,
      lugarId: id,
      nota: nota,
      comentario: comentario,
    );
    await carregar();
  }

  /// NOVO MÉTODO: Busca locais por geolocalização e raio (ex: 10 km) usando PostGIS no Supabase
  Future<void> buscarLugaresProximos({double raioMetros = 10000.0}) async {
    state = state.copyWith(loading: true, erro: null);
    try {
      // 1. Obtém a posição GPS atual do dispositivo
      final posicao = await LocationService.obterLocalizacaoAtual();

      if (posicao == null) {
        state = state.copyWith(
          loading: false,
          erro: 'Não foi possível obter a localização atual.',
        );
        return;
      }

      // 2. Executa a função RPC criada no Supabase
      final response = await Supabase.instance.client.rpc(
        'buscar_locais_proximos',
        params: {
          'lat_ref': posicao.latitude,
          'lng_ref': posicao.longitude,
          'raio_metros': raioMetros,
        },
      );

      // 3. Converte a resposta JSON do Supabase para a lista de entidades `Lugar`
      // (Certifique-se de que a sua entidade `Lugar` possui um construtor como `fromMap` ou ajuste conforme necessário)
      final List<Lugar> lugaresProximos = (response as List)
          .map((item) => Lugar.fromMap(item))
          .toList();

      // 4. Atualiza o estado da tela com os novos lugares filtrados por raio
      state = state.copyWith(loading: false, lugares: lugaresProximos);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        erro: 'Erro ao filtrar locais por proximidade: $e',
      );
    }
  }
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

// Estado do controller para gerenciar a geolocalização e os dados de pets
class PetsState {
  final bool isLoading;
  final Position? currentPosition;
  final String? errorMessage;

  const PetsState({
    this.isLoading = false,
    this.currentPosition,
    this.errorMessage,
  });

  PetsState copyWith({
    bool? isLoading,
    Position? currentPosition,
    String? errorMessage,
  }) {
    return PetsState(
      isLoading: isLoading ?? this.isLoading,
      currentPosition: currentPosition ?? this.currentPosition,
      errorMessage: errorMessage,
    );
  }
}

class PetsController extends StateNotifier<PetsState> {
  PetsController() : super(const PetsState());

  /// Método responsável por obter a localização atual do usuário (Android e iOS)
  Future<void> determinePosition() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      bool serviceEnabled;
      LocationPermission permission;

      // 1. Verifica se o serviço de localização está habilitado no dispositivo
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Os serviços de localização estão desativados. Por favor, ative-os.',
        );
        return;
      }

      // 2. Verifica as permissões de localização atuais
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'As permissões de localização foram negadas.',
          );
          return;
        }
      }

      // 3. Verifica se a permissão foi negada permanentemente
      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'As permissões de localização foram negadas permanentemente. Altere nas configurações do aparelho.',
        );
        return;
      }

      // 4. Obtém a posição atual do dispositivo com alta precisão
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      state = state.copyWith(
        isLoading: false,
        currentPosition: position,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao obter a geolocalização: ${e.toString()}',
      );
    }
  }
}

// Provedor Riverpod para disponibilizar o PetsController na camada de apresentação
final petsControllerProvider = StateNotifierProvider<PetsController, PetsState>((ref) {
  return PetsController();
});