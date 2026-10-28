class Lugar {
  const Lugar({required this.id,required this.nome,required this.categoria,required this.cidade,required this.descricao,this.endereco='',this.telefone='',this.latitude,this.longitude});
  final String id,nome,categoria,cidade,descricao,endereco,telefone;
  final double? latitude,longitude;
  factory Lugar.fromJson(Map<String,dynamic> j)=>Lugar(id:'${j['id']}',nome:'${j['nome']}',categoria:'${j['categoria']}',cidade:'${j['cidade']}',descricao:'${j['descricao']}',endereco:'${j['endereco']??''}',telefone:'${j['telefone']??''}',latitude:(j['latitude'] as num?)?.toDouble(),longitude:(j['longitude'] as num?)?.toDouble());
  Map<String,dynamic> toJson()=>{'id':id,'nome':nome,'categoria':categoria,'cidade':cidade,'descricao':descricao,'endereco':endereco,'telefone':telefone,'latitude':latitude,'longitude':longitude};
}
class Usuario {
  const Usuario({required this.id,required this.nome,required this.email,required this.senhaHash,required this.salt});
  final String id,nome,email,senhaHash,salt;
  factory Usuario.fromJson(Map<String,dynamic> j)=>Usuario(id:'${j['id']}',nome:'${j['nome']}',email:'${j['email']}',senhaHash:'${j['senhaHash']}',salt:'${j['salt']}');
  Map<String,dynamic> toJson()=>{'id':id,'nome':nome,'email':email,'senhaHash':senhaHash,'salt':salt};
}
class Avaliacao {
  const Avaliacao({required this.id,required this.lugarId,required this.usuarioId,required this.autor,required this.nota,required this.comentario});
  final String id,lugarId,usuarioId,autor,comentario;
  final int nota;
  factory Avaliacao.fromJson(Map<String,dynamic> j)=>Avaliacao(id:'${j['id']}',lugarId:'${j['lugarId']}',usuarioId:'${j['usuarioId']}',autor:'${j['autor']}',nota:(j['nota'] as num).toInt(),comentario:'${j['comentario']}');
  Map<String,dynamic> toJson()=>{'id':id,'lugarId':lugarId,'usuarioId':usuarioId,'autor':autor,'nota':nota,'comentario':comentario};
}
