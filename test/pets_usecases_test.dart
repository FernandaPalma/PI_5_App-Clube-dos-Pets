import 'package:flutter_test/flutter_test.dart';
import 'package:clube_dos_pets_offline/features/pets/domain/entities/pets_entities.dart';
import 'package:clube_dos_pets_offline/features/pets/domain/repositories/pets_repository.dart';
import 'package:clube_dos_pets_offline/features/pets/domain/usecases/pets_usecases.dart';

class FakePetsRepository implements PetsRepository {
  final lugaresSalvos = <Lugar>[];
  final avaliacoesSalvas = <Avaliacao>[];
  @override Future<void> seed() async {}
  @override Future<Usuario?> usuarioAtual() async => null;
  @override Future<List<Lugar>> lugares() async => lugaresSalvos;
  @override Future<List<Avaliacao>> avaliacoes() async => avaliacoesSalvas;
  @override Future<List<String>> favoritos(String userId) async => [];
  @override Future<Usuario> cadastrar(String nome,String email,String senha) async => Usuario(id:'u1',nome:nome,email:email,senhaHash:'',salt:'');
  @override Future<Usuario> login(String email,String senha) async => Usuario(id:'u1',nome:'Teste',email:email,senhaHash:'',salt:'');
  @override Future<void> sair() async {}
  @override Future<void> toggleFavorito(String userId,String lugarId) async {}
  @override Future<void> addLugar(Lugar lugar) async {lugaresSalvos.add(lugar);}
  @override Future<void> avaliar(Avaliacao avaliacao) async {avaliacoesSalvas.add(avaliacao);}
}
void main() {
  final user=Usuario(id:'u1',nome:'Tutor',email:'a@b.com',senhaHash:'',salt:'');
  test('Cadastro de estabelecimento exige login', () async {
    final usecase=CadastrarLugar(FakePetsRepository());
    expect(() => usecase(usuario:null,nome:'Parque',categoria:'Parques',cidade:'Campinas',descricao:'',endereco:'',telefone:''),throwsStateError);
  });
  test('Cadastro de estabelecimento valida o nome', () async {
    final usecase=CadastrarLugar(FakePetsRepository());
    expect(() => usecase(usuario:user,nome:' ',categoria:'Parques',cidade:'Campinas',descricao:'',endereco:'',telefone:''),throwsArgumentError);
  });
  test('Cadastro de estabelecimento persiste entidade por contrato', () async {
    final repo=FakePetsRepository();
    await CadastrarLugar(repo)(usuario:user,nome:' Parque Pet ',categoria:'Parques',cidade:' Campinas ',descricao:'',endereco:'',telefone:'');
    expect(repo.lugaresSalvos.single.nome,'Parque Pet');
  });
  test('Avaliação não permite notas fora de 1 até 5', () async {
    expect(() => AvaliarLugar(FakePetsRepository())(usuario:user,lugarId:'p1',nota:6,comentario:'ok'),throwsArgumentError);
  });
}
