import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/pets/domain/repositories/pets_repository.dart';
import '../../features/pets/domain/usecases/pets_usecases.dart';
import '../../features/pets/data/datasources/local_pets_datasource.dart';
import '../../features/pets/data/repositories/pets_repository_local_impl.dart';
import '../../features/pets/presentation/controllers/pets_controller.dart';

// Troque só esta implementação ao integrar o Supabase.
final repositoryProvider = Provider<PetsRepository>((ref) => PetsRepositoryLocalImpl(LocalPetsDataSource()));
final appProvider = StateNotifierProvider<PetsController,PetsState>((ref) {
  final repository=ref.read(repositoryProvider);
  return PetsController(carregarPets:CarregarPets(repository),
    cadastrarUsuario:CadastrarUsuario(repository),entrar:Entrar(repository),
    sairUseCase:Sair(repository),alternarFavorito:AlternarFavorito(repository),
    cadastrarEstabelecimento:CadastrarLugar(repository),avaliarLugar:AvaliarLugar(repository))..carregar();
});
