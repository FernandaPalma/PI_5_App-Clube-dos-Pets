import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Hash com salt para a autenticação LOCAL de demonstração.
/// Mantém o mesmo formato (sha256 de "salt:senha") já gravado no aparelho.
/// Em produção, use Supabase Auth (ou argon2/bcrypt no servidor).
class PasswordHasher {
  PasswordHasher({Random? random}) : _random = random ?? Random.secure();
  final Random _random;

  String generateSalt([int bytes = 24]) => List.generate(
        bytes,
        (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();

  String hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  /// Comparação em tempo constante.
  bool verify(String password, String salt, String expectedHash) {
    final actual = hash(password, salt);
    if (actual.length != expectedHash.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
    }
    return diff == 0;
  }
}
