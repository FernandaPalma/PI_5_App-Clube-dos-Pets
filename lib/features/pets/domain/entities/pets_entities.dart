class Lugar {
  const Lugar({required this.id,required this.nome,required this.categoria,required this.cidade,required this.descricao,this.endereco='',this.telefone='',this.latitude,this.longitude});
  final String id,nome,categoria,cidade,descricao,endereco,telefone;
  final double? latitude,longitude;
}
class Usuario {
  const Usuario({required this.id,required this.nome,required this.email,required this.senhaHash,required this.salt});
  final String id,nome,email,senhaHash,salt;
}
class Avaliacao {
  const Avaliacao({required this.id,required this.lugarId,required this.usuarioId,required this.autor,required this.nota,required this.comentario});
  final String id,lugarId,usuarioId,autor,comentario;
  final int nota;
}
