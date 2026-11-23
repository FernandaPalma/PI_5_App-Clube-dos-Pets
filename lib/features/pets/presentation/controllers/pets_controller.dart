import 'dart:typed_data';

import 'package:clube_dos_pets_offline/services/location_service.dart'; // Ajuste o import conforme o nome do seu pacote
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

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
  PetsController({required this.carregarPets,required this.cadastrarUsuario,
    required this.entrar,required this.sairUseCase,required this.alternarFavorito,
    required this.cadastrarEstabelecimento,required this.avaliarLugar,
    required this.atualizarNomePerfil,required this.atualizarFotoPerfil,
    required this.removerFotoPerfil,required this.alterarSenhaUseCase,required this.alterarTipoContaUseCase}) : super(const PetsState());
  final CarregarPets carregarPets;
  final CadastrarUsuario cadastrarUsuario;
  final Entrar entrar;
  final Sair sairUseCase;
  final AlternarFavorito alternarFavorito;
  final CadastrarLugar cadastrarEstabelecimento;
  final AvaliarLugar avaliarLugar;
  final AtualizarNomePerfil atualizarNomePerfil;
  final AtualizarFotoPerfil atualizarFotoPerfil;
  final RemoverFotoPerfil removerFotoPerfil;
  final AlterarSenha alterarSenhaUseCase;
  final AlterarTipoConta alterarTipoContaUseCase;

  Future<void> carregar() async {
    try {
      final resultado=await carregarPets();
      state=PetsState(loading:false,usuario:resultado.usuario,lugares:resultado.lugares,
        avaliacoes:resultado.avaliacoes,favoritos:resultado.favoritos);
    } catch(e) {state=PetsState(loading:false,erro:'Não foi possível carregar os dados: $e');}
  }
  /// Recarrega os dados (pull to refresh). Em caso de falha mantém a tela atual e propaga o erro.
  Future<void> atualizar() async {
    final r=await carregarPets();
    state=PetsState(loading:false,usuario:r.usuario,lugares:r.lugares,avaliacoes:r.avaliacoes,favoritos:r.favoritos);
  }
  Future<void> cadastrar(String nome,String email,String senha,{TipoConta tipo=TipoConta.tutor}) async {await cadastrarUsuario(nome,email,senha,tipo:tipo);await carregar();}
  Future<void> alterarTipoConta(TipoConta tipo) async {await alterarTipoContaUseCase(state.usuario,tipo);await carregar();}
  Future<void> login(String email,String senha) async {await entrar(email,senha);await carregar();}
  Future<void> sair() async {await sairUseCase();await carregar();}
  Future<void> atualizarNome(String nome) async {await atualizarNomePerfil(state.usuario,nome);await carregar();}
  Future<void> atualizarFoto(Uint8List bytes,String mimeType) async {await atualizarFotoPerfil(state.usuario,bytes,mimeType);await carregar();}
  Future<void> removerFoto() async {await removerFotoPerfil(state.usuario);await carregar();}
  Future<void> alterarSenha(String senhaAtual,String novaSenha) async {await alterarSenhaUseCase(state.usuario,senhaAtual,novaSenha);}
  Future<void> favorito(String lugarId) async {await alternarFavorito(state.usuario,lugarId);await carregar();}
  Future<void> cadastrarLugar({required String nome,required String categoria,required String cidade,
    required String descricao,required String endereco,required String telefone}) async {
    await cadastrarEstabelecimento(usuario:state.usuario,nome:nome,categoria:categoria,
      cidade:cidade,descricao:descricao,endereco:endereco,telefone:telefone);
    await carregar();
  }
  Future<void> avaliar(String id,int nota,String comentario) async {
    await avaliarLugar(usuario:state.usuario,lugarId:id,nota:nota,comentario:comentario);
    await carregar();
  PetsController() : super(const PetsState());

  /// Obtém a localização atual utilizando o LocationService
  Future<void> determinePosition() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Delega a lógica de permissões e obtenção para o serviço dedicado
      Position? position = await LocationService.obterLocalizacaoAtual();

      state = state.copyWith(isLoading: false, currentPosition: position);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final petsControllerProvider = StateNotifierProvider<PetsController, PetsState>(
  (ref) {
    return PetsController();
  },
);
