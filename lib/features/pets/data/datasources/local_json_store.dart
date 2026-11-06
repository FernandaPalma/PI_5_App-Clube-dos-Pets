import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Chaves de armazenamento (mesmas da versão anterior: dados existentes continuam válidos).
abstract final class LocalKeys {
  static const lugares = 'pets_lugares_v2';
  static const usuarios = 'pets_usuarios_v2';
  static const favoritos = 'pets_favoritos_v2';
  static const avaliacoes = 'pets_avaliacoes_v2';
  static const sessao = 'pets_sessao_v2';
}

/// Pequena fachada sobre [SharedPreferences] para listas JSON.
/// Leituras são síncronas (a instância já vem carregada) e a escrita atualiza o
/// cache na hora, então ler-modificar-gravar sem `await` no meio é seguro.
class LocalJsonStore {
  LocalJsonStore(this._prefs);
  final SharedPreferences _prefs;

  bool contains(String key) => _prefs.containsKey(key);

  List<Map<String, dynamic>> readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  String? readString(String key) => _prefs.getString(key);

  Future<void> writeString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}
