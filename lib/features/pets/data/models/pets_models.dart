import '../../domain/entities/pets_entities.dart';

String _str(Map<String, dynamic> j, String key) => (j[key] ?? '').toString();

/// Representação serializável de [Lugar]. Fica restrita à camada de dados.
class LugarModel {
  const LugarModel({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.cidade,
    required this.descricao,
    this.endereco = '',
    this.telefone = '',
    this.latitude,
    this.longitude,
  });

  final String id, nome, categoria, cidade, descricao, endereco, telefone;
  final double? latitude, longitude;

  factory LugarModel.fromJson(Map<String, dynamic> j) => LugarModel(
        id: _str(j, 'id'),
        nome: _str(j, 'nome'),
        categoria: _str(j, 'categoria'),
        cidade: _str(j, 'cidade'),
        descricao: _str(j, 'descricao'),
        endereco: _str(j, 'endereco'),
        telefone: _str(j, 'telefone'),
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
      );

  factory LugarModel.fromEntity(Lugar e) => LugarModel(
        id: e.id,
        nome: e.nome,
        categoria: e.categoria,
        cidade: e.cidade,
        descricao: e.descricao,
        endereco: e.endereco,
        telefone: e.telefone,
        latitude: e.latitude,
        longitude: e.longitude,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'categoria': categoria,
        'cidade': cidade,
        'descricao': descricao,
        'endereco': endereco,
        'telefone': telefone,
        'latitude': latitude,
        'longitude': longitude,
      };

  Lugar toEntity() => Lugar(
        id: id,
        nome: nome,
        categoria: categoria,
        cidade: cidade,
        descricao: descricao,
        endereco: endereco,
        telefone: telefone,
        latitude: latitude,
        longitude: longitude,
      );
}

/// Usuário + credenciais. As credenciais nunca sobem para o domínio.
class UsuarioModel {
  const UsuarioModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.senhaHash,
    required this.salt,
  });

  final String id, nome, email, senhaHash, salt;

  factory UsuarioModel.fromJson(Map<String, dynamic> j) => UsuarioModel(
        id: _str(j, 'id'),
        nome: _str(j, 'nome'),
        email: _str(j, 'email'),
        senhaHash: _str(j, 'senhaHash'),
        salt: _str(j, 'salt'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'senhaHash': senhaHash,
        'salt': salt,
      };

  Usuario toEntity() => Usuario(id: id, nome: nome, email: email);
}

class AvaliacaoModel {
  const AvaliacaoModel({
    required this.id,
    required this.lugarId,
    required this.usuarioId,
    required this.autor,
    required this.nota,
    required this.comentario,
  });

  final String id, lugarId, usuarioId, autor, comentario;
  final int nota;

  factory AvaliacaoModel.fromJson(Map<String, dynamic> j) => AvaliacaoModel(
        id: _str(j, 'id'),
        lugarId: _str(j, 'lugarId'),
        usuarioId: _str(j, 'usuarioId'),
        autor: _str(j, 'autor'),
        nota: (j['nota'] as num).toInt(),
        comentario: _str(j, 'comentario'),
      );

  factory AvaliacaoModel.fromEntity(Avaliacao e) => AvaliacaoModel(
        id: e.id,
        lugarId: e.lugarId,
        usuarioId: e.usuarioId,
        autor: e.autor,
        nota: e.nota,
        comentario: e.comentario,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lugarId': lugarId,
        'usuarioId': usuarioId,
        'autor': autor,
        'nota': nota,
        'comentario': comentario,
      };

  Avaliacao toEntity() => Avaliacao(
        id: id,
        lugarId: lugarId,
        usuarioId: usuarioId,
        autor: autor,
        nota: nota,
        comentario: comentario,
      );
}
