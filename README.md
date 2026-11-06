# Clube dos Pets — Flutter Clean Architecture

Projeto migrado da estrutura MVVM para **Clean Architecture** seguindo o material do professor *Clean Architecture no Flutter, sem dor*.

## Estrutura

- `lib/features/pets/domain/`: entidades Dart puras, interface de repositório e casos de uso.
- `lib/features/pets/data/`: modelos JSON, fonte de dados local e implementação do contrato do Domain.
- `lib/features/pets/presentation/`: controller Riverpod e telas Flutter.
- `lib/core/di/providers.dart`: composição e injeção de dependências.
- `assets/`: imagens locais do visual inspirado no React.
- `test/pets_usecases_test.dart`: testes dos casos de uso com fake repository.

A feature `pets` agrupa as operações existentes para preservar o comportamento; pode ser desmembrada em `auth`, `estabelecimentos`, `avaliacoes` e `favoritos` conforme o escopo crescer.

## Executar no VS Code

1. Extraia o projeto e abra **esta pasta, que contém `pubspec.yaml`**, no VS Code.
2. No terminal PowerShell execute:

```powershell
flutter create --platforms=web .
flutter pub get
flutter run -d chrome -t lib/main.dart
```

Para conferir as regras de negócio:

```powershell
flutter test
```

`flutter create --platforms=web .` gera somente arquivos de plataforma ausentes ou arquivos previstos pelo comando; confira o `git diff` depois de executar. Não substitua o `lib/main.dart` pelo template Flutter Demo.

## Camada de dados

```
data/
  models/        LugarModel, UsuarioModel (com hash/salt), AvaliacaoModel -> toEntity()/fromEntity()
  datasources/   AuthDataSource + PetsDataSource (interfaces) e implementações locais (SharedPreferences)
  security/      PasswordHasher (hash + salt, comparação em tempo constante)
  repositories/  PetsRepositoryImpl: Model <-> Entity e erros inesperados -> StorageFailure
```

O domínio lança apenas `PetsFailure` (`ValidationFailure`, `AuthFailure`, `StorageFailure`). Credenciais nunca saem da camada de dados.

## Supabase (não conectado)

O contrato `PetsRepository` vive no Domain e `PetsRepositoryImpl` não conhece o banco. Para migrar, crie `AuthSupabaseDataSource` e `PetsSupabaseDataSource` (implementando `AuthDataSource` e `PetsDataSource`) em `data/datasources/` e altere **somente** `authDataSourceProvider` e `petsDataSourceProvider` em `lib/core/di/providers.dart`. Não adicione URLs e chaves privadas ao Git.

A autenticação local é **somente para demonstração**, não substitui autenticação segura de produção; na migração use Supabase Auth, políticas RLS e regras de autorização adequadas.

## Git

Se você clonou o repositório de equipe, crie a branch antes de copiar os arquivos:

```powershell
git switch -c feature/clean-architecture
# copie o conteúdo desta pasta para o diretório desejado no clone
git add .
git commit -m "refactor: migra Flutter para Clean Architecture"
git push -u origin feature/clean-architecture
```

## Limitação da entrega

A migração preserva o layout e os fluxos existentes. O projeto não foi compilado aqui porque o Flutter SDK não está instalado no ambiente de preparação; execute `flutter analyze`, `flutter test` e `flutter run` localmente antes de publicar.
