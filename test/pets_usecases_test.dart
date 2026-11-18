import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:clube_dos_pets_offline/features/pets/domain/entities/pets_entities.dart';
import 'package:clube_dos_pets_offline/features/pets/domain/failures/pets_failures.dart';
import 'package:clube_dos_pets_offline/features/pets/domain/repositories/pets_repository.dart';
import 'package:clube_dos_pets_offline/features/pets/domain/usecases/pets_usecases.dart';

class FakePetsRepository implements PetsRepository {
  final lugaresSalvos = <Lugar>[];
  final avaliacoesSalvas = <Avaliacao>[];
  @override Future<Usuario?> usuarioAtual() async => null;
  @override Future<List<Lugar>> lugares() async => lugaresSalvos;
  @override Future<List<Avaliacao>> avaliacoes() async => avaliacoesSalvas;
  @override Future<List<String>> favoritos(String userId) async => [];
  @override Future<Usuario> cadastrar(String nome,String email,String senha,{TipoConta tipo=TipoConta.tutor}) async => Usuario(id:'u1',nome:nome,email:email,tipo:tipo);
  @override Future<Usuario> alterarTipoConta(TipoConta tipo) async => Usuario(id:'u1',nome:'Tutor',email:'a@b.com',tipo:tipo);
  @override Future<Usuario> login(String email,String senha) async => Usuario(id:'u1',nome:'Teste',email:email);
  @override Future<void> sair() async {}
  String? senhaTrocada;
  @override Future<Usuario> atualizarNome(String nome) async => Usuario(id:'u1',nome:nome,email:'a@b.com');
  @override Future<Usuario> atualizarFoto(Uint8List bytes,String mimeType) async => const Usuario(id:'u1',nome:'Tutor',email:'a@b.com',fotoUrl:'https://exemplo.test/foto');
  @override Future<Usuario> removerFoto() async => const Usuario(id:'u1',nome:'Tutor',email:'a@b.com');
  @override Future<void> alterarSenha(String senhaAtual,String novaSenha) async {senhaTrocada=novaSenha;}
  @override Future<void> toggleFavorito(String userId,String lugarId) async {}
  @override Future<void> addLugar(Lugar lugar) async {lugaresSalvos.add(lugar);}
  @override Future<void> avaliar(Avaliacao avaliacao) async {avaliacoesSalvas.add(avaliacao);}
}

void main() {
  const user = Usuario(id: 'u1', nome: 'Tutor', email: 'a@b.com');

  test('Cadastro de estabelecimento exige login', () async {
    final usecase = CadastrarLugar(FakePetsRepository());
    expect(() => usecase(usuario:null,nome:'Parque',categoria:'Parques',cidade:'Campinas',descricao:'',endereco:'',telefone:''), throwsA(isA<AuthFailure>()));
  });
  test('Cadastro de estabelecimento valida o nome', () async {
    final usecase = CadastrarLugar(FakePetsRepository());
    expect(() => usecase(usuario:user,nome:' ',categoria:'Parques',cidade:'Campinas',descricao:'',endereco:'',telefone:''), throwsA(isA<ValidationFailure>()));
  });
  test('Cadastro de estabelecimento persiste entidade por contrato', () async {
    final repo = FakePetsRepository();
    await CadastrarLugar(repo)(usuario:user,nome:' Parque Pet ',categoria:'Parques',cidade:' Campinas ',descricao:'',endereco:'',telefone:'');
    expect(repo.lugaresSalvos.single.nome, 'Parque Pet');
  });
  test('Avaliação não permite notas fora de 1 até 5', () async {
    expect(() => AvaliarLugar(FakePetsRepository())(usuario:user,lugarId:'p1',nota:6,comentario:'ok'), throwsA(isA<ValidationFailure>()));
  });
  test('Cadastro de usuário normaliza nome e e-mail', () async {
    final u = await CadastrarUsuario(FakePetsRepository())(' Ana ', ' ANA@Pets.com ', 'segredo1');
    expect(u.nome, 'Ana');
    expect(u.email, 'ana@pets.com');
  });
  test('Cadastro de usuário rejeita senha curta', () async {
    expect(() => CadastrarUsuario(FakePetsRepository())('Ana','ana@pets.com','123'), throwsA(isA<ValidationFailure>()));
  });
  test('Atualizar nome exige login e normaliza o texto', () async {
    expect(() => AtualizarNomePerfil(FakePetsRepository())(null,'Ana'), throwsA(isA<AuthFailure>()));
    expect(() => AtualizarNomePerfil(FakePetsRepository())(user,' A '), throwsA(isA<ValidationFailure>()));
    final u = await AtualizarNomePerfil(FakePetsRepository())(user,'  Ana Paula ');
    expect(u.nome, 'Ana Paula');
  });
  test('Foto de perfil valida formato e tamanho', () async {
    final caso = AtualizarFotoPerfil(FakePetsRepository());
    expect(() => caso(user, Uint8List.fromList([1,2,3]), 'image/gif'), throwsA(isA<ValidationFailure>()));
    expect(() => caso(user, Uint8List(0), 'image/png'), throwsA(isA<ValidationFailure>()));
    expect(() => caso(user, Uint8List(AtualizarFotoPerfil.limiteBytes + 1), 'image/png'), throwsA(isA<ValidationFailure>()));
    expect(() => caso(null, Uint8List.fromList([1]), 'image/png'), throwsA(isA<AuthFailure>()));
    final u = await caso(user, Uint8List.fromList([1,2,3]), 'image/png');
    expect(u.fotoUrl, isNotNull);
  });
  test('Alterar senha valida as regras antes de chamar o repositório', () async {
    final repo = FakePetsRepository();
    final caso = AlterarSenha(repo);
    expect(() => caso(null,'abc123','novaSenha1'), throwsA(isA<AuthFailure>()));
    expect(() => caso(user,'','novaSenha1'), throwsA(isA<ValidationFailure>()));
    expect(() => caso(user,'abc123','123'), throwsA(isA<ValidationFailure>()));
    expect(() => caso(user,'abc123','abc123'), throwsA(isA<ValidationFailure>()));
    await caso(user,'abc123','novaSenha1');
    expect(repo.senhaTrocada, 'novaSenha1');
  });
  test('Cadastro respeita o tipo de conta (tutor por padrão)', () async {
    final repo = FakePetsRepository();
    expect((await CadastrarUsuario(repo)('Ana','ana@pets.com','segredo1')).tipo, TipoConta.tutor);
    expect((await CadastrarUsuario(repo)('Loja','loja@pets.com','segredo1',tipo:TipoConta.empresa)).tipo, TipoConta.empresa);
  });
  test('Mudar tipo de conta exige login', () async {
    expect(() => AlterarTipoConta(FakePetsRepository())(null,TipoConta.empresa), throwsA(isA<AuthFailure>()));
    final u = await AlterarTipoConta(FakePetsRepository())(user,TipoConta.empresa);
    expect(u.tipo, TipoConta.empresa);
  });
  test('Favoritar exige usuário logado', () async {
    expect(() => AlternarFavorito(FakePetsRepository())(null,'demo1'), throwsA(isA<AuthFailure>()));
  });
}
