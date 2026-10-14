import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/local_repository.dart';
final repositoryProvider=Provider<LocalRepository>((ref)=>LocalRepository());
final appProvider=StateNotifierProvider<AppViewModel,AppState>((ref)=>AppViewModel(ref.read(repositoryProvider))..carregar());
class AppState {
  const AppState({this.loading=true,this.usuario,this.lugares=const [],this.favoritos=const [],this.avaliacoes=const [],this.erro});
  final bool loading;final Usuario? usuario;final List<Lugar> lugares;final List<String> favoritos;final List<Avaliacao> avaliacoes;final String? erro;
  AppState copyWith({bool? loading,Usuario? usuario,bool limparUsuario=false,List<Lugar>? lugares,List<String>? favoritos,List<Avaliacao>? avaliacoes,String? erro})=>AppState(loading:loading??this.loading,usuario:limparUsuario?null:usuario??this.usuario,lugares:lugares??this.lugares,favoritos:favoritos??this.favoritos,avaliacoes:avaliacoes??this.avaliacoes,erro:erro);
  double nota(String id){final n=avaliacoes.where((a)=>a.lugarId==id).toList();return n.isEmpty?0:n.map((a)=>a.nota).reduce((a,b)=>a+b)/n.length;}
}
class AppViewModel extends StateNotifier<AppState>{AppViewModel(this.repo):super(const AppState());final LocalRepository repo;
  Future<void> carregar()async {try{await repo.seed();final u=await repo.usuarioAtual();state=AppState(loading:false,usuario:u,lugares:await repo.lugares(),avaliacoes:await repo.avaliacoes(),favoritos:u==null?[]:await repo.favoritos(u.id));}catch(e){state=AppState(loading:false,erro:'Não foi possível carregar os dados locais: $e');}}
  Future<void> cadastrar(String nome,String email,String senha)async {await repo.cadastrar(nome,email,senha);await carregar();}
  Future<void> login(String email,String senha)async {await repo.login(email,senha);await carregar();}
  Future<void> sair()async {await repo.sair();await carregar();}
  Future<void> favorito(String lugarId)async {final u=state.usuario;if(u==null)throw Exception('Entre na sua conta para salvar favoritos.');await repo.toggleFavorito(u.id,lugarId);await carregar();}
  Future<void> cadastrarLugar({required String nome,required String categoria,required String cidade,required String descricao,required String endereco,required String telefone})async{if(state.usuario==null)throw Exception('Faça login.');if(nome.trim().isEmpty||cidade.trim().isEmpty)throw Exception('Nome e cidade são obrigatórios.');await repo.addLugar(Lugar(id:DateTime.now().microsecondsSinceEpoch.toString(),nome:nome.trim(),categoria:categoria,cidade:cidade.trim(),descricao:descricao.trim(),endereco:endereco.trim(),telefone:telefone.trim()));await carregar();}
  Future<void> avaliar(String id,int nota,String comentario)async{final u=state.usuario;if(u==null)throw Exception('Entre na sua conta.');await repo.avaliar(Avaliacao(id:DateTime.now().microsecondsSinceEpoch.toString(),lugarId:id,usuarioId:u.id,autor:u.nome,nota:nota,comentario:comentario.trim()));await carregar();}
}
