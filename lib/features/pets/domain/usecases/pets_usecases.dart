import '../entities/pets_entities.dart';
import '../repositories/pets_repository.dart';

class CarregarPets {
  final PetsRepository repository;
  CarregarPets(this.repository);
  Future<PetsSnapshot> call() async {
    await repository.seed();
    final usuario = await repository.usuarioAtual();
    return PetsSnapshot(usuario: usuario, lugares: await repository.lugares(),
      avaliacoes: await repository.avaliacoes(),
      favoritos: usuario == null ? [] : await repository.favoritos(usuario.id));
  }
}
class PetsSnapshot {
  final Usuario? usuario;
  final List<Lugar> lugares;
  final List<Avaliacao> avaliacoes;
  final List<String> favoritos;
  const PetsSnapshot({this.usuario,required this.lugares,required this.avaliacoes,required this.favoritos});
}
class CadastrarUsuario {
  final PetsRepository repository;
  CadastrarUsuario(this.repository);
  Future<Usuario> call(String nome,String email,String senha) {
    if(nome.trim().length < 2 || !email.contains('@') || senha.length < 6) {
      throw ArgumentError('Informe nome, e-mail válido e senha de pelo menos 6 caracteres.');
    }
    return repository.cadastrar(nome,email,senha);
  }
}
class Entrar {
  final PetsRepository repository;
  Entrar(this.repository);
  Future<Usuario> call(String email,String senha) => repository.login(email,senha);
}
class Sair {
  final PetsRepository repository;
  Sair(this.repository);
  Future<void> call()=>repository.sair();
}
class AlternarFavorito {
  final PetsRepository repository;
  AlternarFavorito(this.repository);
  Future<void> call(Usuario? usuario,String lugarId) {
    if(usuario == null) throw StateError('Entre na sua conta para salvar favoritos.');
    return repository.toggleFavorito(usuario.id,lugarId);
  }
}
class CadastrarLugar {
  final PetsRepository repository;
  CadastrarLugar(this.repository);
  Future<void> call({required Usuario? usuario,required String nome,required String categoria,
    required String cidade,required String descricao,required String endereco,required String telefone}) {
    if(usuario == null) throw StateError('Faça login.');
    if(nome.trim().isEmpty || cidade.trim().isEmpty) throw ArgumentError('Nome e cidade são obrigatórios.');
    return repository.addLugar(Lugar(id:DateTime.now().microsecondsSinceEpoch.toString(),
      nome:nome.trim(),categoria:categoria,cidade:cidade.trim(),descricao:descricao.trim(),
      endereco:endereco.trim(),telefone:telefone.trim()));
  }
}
class AvaliarLugar {
  final PetsRepository repository;
  AvaliarLugar(this.repository);
  Future<void> call({required Usuario? usuario,required String lugarId,required int nota,required String comentario}) {
    if(usuario == null) throw StateError('Entre na sua conta.');
    if(nota < 1 || nota > 5) throw ArgumentError('A nota deve estar entre 1 e 5.');
    return repository.avaliar(Avaliacao(id:DateTime.now().microsecondsSinceEpoch.toString(),
      lugarId:lugarId,usuarioId:usuario.id,autor:usuario.nome,nota:nota,comentario:comentario.trim()));
  }
}
