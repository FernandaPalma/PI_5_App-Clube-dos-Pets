import 'package:clube_dos_pets_offline/services/location_service.dart'; // Ajuste o import conforme o nome do seu pacote
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class PetsState {
  final bool isLoading;
  final Position? currentPosition;
  final String? errorMessage;

  const PetsState({
    this.isLoading = false,
    this.currentPosition,
    this.errorMessage,
  });

  PetsState copyWith({
    bool? isLoading,
    Position? currentPosition,
    String? errorMessage,
  }) {
    return PetsState(
      isLoading: isLoading ?? this.isLoading,
      currentPosition: currentPosition ?? this.currentPosition,
      errorMessage: errorMessage,
    );
  }
}

class PetsController extends StateNotifier<PetsState> {
  PetsController() : super(const PetsState());

  /// Obtém a localização atual utilizando o LocationService
  Future<void> determinePosition() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Delega a lógica de permissões e obtenção para o serviço dedicado
      Position? position = await LocationService.obterLocalizacaoAtual();

      state = state.copyWith(isLoading: false, currentPosition: position);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final petsControllerProvider = StateNotifierProvider<PetsController, PetsState>(
  (ref) {
    return PetsController();
  },
);
