import 'dart:typed_data';

import '../entities/pets_entities.dart';
import '../failures/pets_failures.dart';
import '../repositories/pets_repository.dart';

class CarregarPets {
  final PetsRepository repository;
  CarregarPets(this.repository);
  Future<PetsSnapshot> call() async {
    final usuario = await repository.usuarioAtual();
    return PetsSnapshot(
      usuario: usuario,
      lugares: await repository.lugares(),
      avaliacoes: await repository.avaliacoes(),
      favoritos: usuario == null ? [] : await repository.favoritos(usuario.id),
    );
  }
}

class PetsSnapshot {
  final Usuario? usuario;
  final List<Lugar> lugares;
  final List<Avaliacao> avaliacoes;
  final List<String> favoritos;
  const PetsSnapshot({
    this.usuario,
    required this.lugares,
    required this.avaliacoes,
    required this.favoritos,
  });
}

class CadastrarUsuario {
  final PetsRepository repository;
  CadastrarUsuario(this.repository);
  Future<Usuario> call(
    String nome,
    String email,
    String senha, {
    TipoConta tipo = TipoConta.tutor,
  }) {
    final nomeLimpo = nome.trim();
    final emailLimpo = email.trim().toLowerCase();
    if (nomeLimpo.length < 2 || !emailLimpo.contains('@') || senha.length < 6) {
      throw const ValidationFailure(
          'Informe nome, e-mail válido e senha de pelo menos 6 caracteres.');
    }
    return repository.cadastrar(nomeLimpo, emailLimpo, senha, tipo: tipo);
  }
}

class Entrar {
  final PetsRepository repository;
  Entrar(this.repository);
  Future<Usuario> call(String email, String senha) =>
      repository.login(email.trim().toLowerCase(), senha);
}

class Sair {
  final PetsRepository repository;
  Sair(this.repository);
  Future<void> call() => repository.sair();
}

class AlternarFavorito {
  final PetsRepository repository;
  AlternarFavorito(this.repository);
  Future<void> call(Usuario? usuario, String lugarId) {
    if (usuario == null) {
      throw const AuthFailure('Entre na sua conta para salvar favoritos.');
    }
    return repository.toggleFavorito(usuario.id, lugarId);
  }
}

class CadastrarLugar {
  final PetsRepository repository;
  CadastrarLugar(this.repository);
  Future<void> call({
    required Usuario? usuario,
    required String nome,
    required String categoria,
    required String cidade,
    required String descricao,
    required String endereco,
    required String telefone,
  }) {
    if (usuario == null) throw const AuthFailure('Faça login.');
    if (nome.trim().isEmpty || cidade.trim().isEmpty) {
      throw const ValidationFailure('Nome e cidade são obrigatórios.');
    }
    return repository.addLugar(Lugar(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      nome: nome.trim(),
      categoria: categoria,
      cidade: cidade.trim(),
      descricao: descricao.trim(),
      endereco: endereco.trim(),
      telefone: telefone.trim(),
    ));
  }
}

class AvaliarLugar {
  final PetsRepository repository;
  AvaliarLugar(this.repository);
  Future<void> call({
    required Usuario? usuario,
    required String lugarId,
    required int nota,
    required String comentario,
  }) {
    if (usuario == null) throw const AuthFailure('Entre na sua conta.');
    if (nota < 1 || nota > 5) {
      throw const ValidationFailure('A nota deve estar entre 1 e 5.');
    }
    return repository.avaliar(Avaliacao(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      lugarId: lugarId,
      usuarioId: usuario.id,
      autor: usuario.nome,
      nota: nota,
      comentario: comentario.trim(),
    ));
  }
}

class AtualizarNomePerfil {
  final PetsRepository repository;
  AtualizarNomePerfil(this.repository);
  Future<Usuario> call(Usuario? usuario, String nome) {
    if (usuario == null) throw const AuthFailure('Entre na sua conta.');
    final limpo = nome.trim();
    if (limpo.length < 2) {
      throw const ValidationFailure('Informe um nome com pelo menos 2 letras.');
    }
    return repository.atualizarNome(limpo);
  }
}

class AtualizarFotoPerfil {
  final PetsRepository repository;
  AtualizarFotoPerfil(this.repository);

  static const limiteBytes = 2 * 1024 * 1024;
  static const formatosAceitos = {'image/jpeg', 'image/png', 'image/webp'};

  Future<Usuario> call(Usuario? usuario, Uint8List bytes, String mimeType) {
    if (usuario == null) throw const AuthFailure('Entre na sua conta.');
    if (!formatosAceitos.contains(mimeType)) {
      throw const ValidationFailure('Use uma imagem JPEG, PNG ou WebP.');
    }
    if (bytes.isEmpty || bytes.length > limiteBytes) {
      throw const ValidationFailure('A foto deve ter no máximo 2 MB.');
    }
    return repository.atualizarFoto(bytes, mimeType);
  }
}

class RemoverFotoPerfil {
  final PetsRepository repository;
  RemoverFotoPerfil(this.repository);
  Future<Usuario> call(Usuario? usuario) {
    if (usuario == null) throw const AuthFailure('Entre na sua conta.');
    return repository.removerFoto();
  }
}

class AlterarSenha {
  final PetsRepository repository;
  AlterarSenha(this.repository);
  Future<void> call(Usuario? usuario, String senhaAtual, String novaSenha) {
    if (usuario == null) throw const AuthFailure('Entre na sua conta.');
    if (senhaAtual.isEmpty) {
      throw const ValidationFailure('Informe a senha atual.');
    }
    if (novaSenha.length < 6) {
      throw const ValidationFailure(
          'A nova senha deve ter pelo menos 6 caracteres.');
    }
    if (novaSenha == senhaAtual) {
      throw const ValidationFailure(
          'A nova senha deve ser diferente da atual.');
    }
    return repository.alterarSenha(senhaAtual, novaSenha);
  }
}

class AlterarTipoConta {
  final PetsRepository repository;
  AlterarTipoConta(this.repository);
  Future<Usuario> call(Usuario? usuario, TipoConta tipo) {
    if (usuario == null) throw const AuthFailure('Entre na sua conta.');
    return repository.alterarTipoConta(tipo);
  }
}
