import '../../domain/entities/pets_entities.dart';

class LugarModel {
  static Lugar fromJson(Map<String,dynamic> j) => Lugar(id:'${j['id']}',nome:'${j['nome']}',categoria:'${j['categoria']}',cidade:'${j['cidade']}',descricao:'${j['descricao']}',endereco:'${j['endereco']??''}',telefone:'${j['telefone']??''}',latitude:(j['latitude'] as num?)?.toDouble(),longitude:(j['longitude'] as num?)?.toDouble());
  static Map<String,dynamic> toJson(Lugar entity) {
    final id = entity.id;
    final nome = entity.nome;
    final categoria = entity.categoria;
    final cidade = entity.cidade;
    final descricao = entity.descricao;
    final endereco = entity.endereco;
    final telefone = entity.telefone;
    final latitude = entity.latitude;
    final longitude = entity.longitude;
    return {'id':id,'nome':nome,'categoria':categoria,'cidade':cidade,'descricao':descricao,'endereco':endereco,'telefone':telefone,'latitude':latitude,'longitude':longitude};
  }
}

class UsuarioModel {
  static Usuario fromJson(Map<String,dynamic> j) => Usuario(id:'${j['id']}',nome:'${j['nome']}',email:'${j['email']}',senhaHash:'${j['senhaHash']}',salt:'${j['salt']}');
  static Map<String,dynamic> toJson(Usuario entity) {
    final id = entity.id;
    final nome = entity.nome;
    final email = entity.email;
    final senhaHash = entity.senhaHash;
    final salt = entity.salt;
    return {'id':id,'nome':nome,'email':email,'senhaHash':senhaHash,'salt':salt};
  }
}

class AvaliacaoModel {
  static Avaliacao fromJson(Map<String,dynamic> j) => Avaliacao(id:'${j['id']}',lugarId:'${j['lugarId']}',usuarioId:'${j['usuarioId']}',autor:'${j['autor']}',nota:(j['nota'] as num).toInt(),comentario:'${j['comentario']}');
  static Map<String,dynamic> toJson(Avaliacao entity) {
    final id = entity.id;
    final lugarId = entity.lugarId;
    final usuarioId = entity.usuarioId;
    final autor = entity.autor;
    final nota = entity.nota;
    final comentario = entity.comentario;
    return {'id':id,'lugarId':lugarId,'usuarioId':usuarioId,'autor':autor,'nota':nota,'comentario':comentario};
  }
}

