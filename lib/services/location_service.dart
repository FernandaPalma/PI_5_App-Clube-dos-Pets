import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Retorna a posição atual do usuário validando as permissões necessárias.
  static Future<Position?> obterLocalizacaoAtual() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Verifica se o serviço de localização está ativado no Aparelho
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('O serviço de localização (GPS) está desativado.');
    }

    // 2. Verifica o status atual das permissões
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('As permissões de localização foram negadas.');
      }
    }

    // 3. Verifica se foi negado permanentemente
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'As permissões de localização foram negadas permanentemente. Altere nas configurações do app.',
      );
    }

    // 4. Retorna a posição geográfica atual com alta precisão
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
