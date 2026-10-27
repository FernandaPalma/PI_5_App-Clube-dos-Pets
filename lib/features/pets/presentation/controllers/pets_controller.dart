import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/pets_entities.dart';
import '../../domain/usecases/pets_usecases.dart';
class PetsState {
  const PetsState({this.loading=true,this.usuario,this.lugares=const [],this.favoritos=const [],this.avaliacoes=const [],this.erro});
  final bool loading;final Usuario? usuario;final List<Lugar> lugares;final List<String> favoritos;final List<Avaliacao> avaliacoes;final String? erro;
  PetsState copyWith({bool? loading,Usuario? usuario,bool limparUsuario=false,List<Lugar>? lugares,List<String>? favoritos,List<Avaliacao>? avaliacoes,String? erro})=>PetsState(loading:loading??this.loading,usuario:limparUsuario?null:usuario??this.usuario,lugares:lugares??this.lugares,favoritos:favoritos??this.favoritos,avaliacoes:avaliacoes??this.avaliacoes,erro:erro);
  double nota(String id){final n=avaliacoes.where((a)=>a.lugarId==id).toList();return n.isEmpty?0:n.map((a)=>a.nota).reduce((a,b)=>a+b)/n.length;}
}
class PetsController extends StateNotifier<PetsState> {
  PetsController({required this.carregarPets,required this.cadastrarUsuario,
    required this.entrar,required this.sairUseCase,required this.alternarFavorito,
    required this.cadastrarEstabelecimento,required this.avaliarLugar}) : super(const PetsState());
  final CarregarPets carregarPets;
  final CadastrarUsuario cadastrarUsuario;
  final Entrar entrar;
  final Sair sairUseCase;
  final AlternarFavorito alternarFavorito;
  final CadastrarLugar cadastrarEstabelecimento;
  final AvaliarLugar avaliarLugar;

  Future<void> carregar() async {
    try {
      final resultado=await carregarPets();
      state=PetsState(loading:false,usuario:resultado.usuario,lugares:resultado.lugares,
        avaliacoes:resultado.avaliacoes,favoritos:resultado.favoritos);
    } catch(e) {state=PetsState(loading:false,erro:'Não foi possível carregar os dados locais: $e');}
  }
  Future<void> cadastrar(String nome,String email,String senha) async {await cadastrarUsuario(nome,email,senha);await carregar();}
  Future<void> login(String email,String senha) async {await entrar(email,senha);await carregar();}
  Future<void> sair() async {await sairUseCase();await carregar();}
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
  }
}
