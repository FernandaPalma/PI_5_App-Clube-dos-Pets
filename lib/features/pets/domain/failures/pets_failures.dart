/// Falhas esperadas do domínio. A UI pode exibir [message] diretamente,
/// sem o prefixo "Exception:" / "Invalid argument(s):".
sealed class PetsFailure implements Exception {
  const PetsFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Dados de entrada inválidos (regra de negócio).
class ValidationFailure extends PetsFailure {
  const ValidationFailure(super.message);
}

/// Usuário não autenticado ou credenciais inválidas.
class AuthFailure extends PetsFailure {
  const AuthFailure(super.message);
}

/// Erro inesperado de persistência (armazenamento corrompido, rede, etc.).
class StorageFailure extends PetsFailure {
  const StorageFailure(super.message);
}
