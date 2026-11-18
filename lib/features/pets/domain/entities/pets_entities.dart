class Lugar {
  const Lugar({
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
}

/// Tipo de conta: tutor (usa o app) ou empresa/parceiro (divulga locais).
enum TipoConta { tutor, empresa }

/// Usuário do domínio. Credenciais (hash/salt) pertencem à camada de dados.
class Usuario {
  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.fotoUrl,
    this.tipo = TipoConta.tutor,
  });
  final String id, nome, email;
  final TipoConta tipo;

  /// Endereço público da foto de perfil (null quando não há foto).
  final String? fotoUrl;
}

class Avaliacao {
  const Avaliacao({
    required this.id,
    required this.lugarId,
    required this.usuarioId,
    required this.autor,
    required this.nota,
    required this.comentario,
  });
  final String id, lugarId, usuarioId, autor, comentario;
  final int nota;
}
