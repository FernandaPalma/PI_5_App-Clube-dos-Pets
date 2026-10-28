# Clube dos Pets — Flutter Offline

Aplicativo **100% Flutter/Dart** com arquitetura **MVVM**, **Riverpod** e persistência local pelo pacote `shared_preferences`, compatível com **Android e Flutter Web (Chrome)**. Não usa Node.js, API, Docker, MySQL ou XAMPP.

## Requisitos
- Flutter SDK instalado e configurado no PATH
- Extensões Flutter e Dart no VS Code
- Para Android: Android SDK/emulador ou celular com depuração USB
- Para Web: Chrome

## Abrir no VS Code
1. Extraia o ZIP e abra a pasta `Clube_dos_Pets_Offline`.
2. Abra o terminal nesta pasta e rode:

```powershell
flutter create --platforms=android,web .
flutter pub get
flutter run -d chrome
```

Para Android:

```powershell
flutter devices
flutter run -d <ID_DO_DISPOSITIVO>
```

> **Importante:** o ambiente usado para gerar o ZIP não tem Flutter SDK. Portanto, os diretórios nativos gerados pelo Flutter (`android/`, `web/`) precisam ser criados com `flutter create` na primeira execução. Não foi possível realizar compilação/testes com Flutter neste ambiente.

## Recursos
- Lista de estabelecimentos e categorias com dados de exemplo **fictícios**
- Busca por nome, cidade e categoria
- Cadastro local de tutores, login e logout
- Cadastro local de estabelecimentos
- Favoritos por usuário
- Avaliações com nota de 1 a 5
- Consulta de endereços e abertura de mapa externo (requer internet)
- Estados com Riverpod `StateNotifier`
- Persistência local em JSON com `shared_preferences`

## Estrutura MVVM

```text
lib/
  models/models.dart                # Modelos de dados
  repositories/local_repository.dart # Armazenamento e regras de persistência
  viewmodels/app_viewmodel.dart      # Estado e operações com Riverpod
  views/app_shell.dart               # Views / navegação e formulários
  main.dart                          # Bootstrap e tema
```

## Limitações importantes
- Os dados ficam **somente no navegador ou dispositivo** atual; não há sincronização entre dispositivos.
- Limpar dados do aplicativo/navegador pode apagar usuários, favoritos e estabelecimentos cadastrados.
- Os dados de demonstração **não** são dados reais do banco MySQL original.
- O login é **local e educacional** (hash SHA-256 com salt, não indicado para autenticação de produção). Em produção, recomenda-se autenticação segura e sincronização com um backend.
- A página **Mapa** é uma lista de locais com abertura de Google Maps externo, e **não** um mapa interno offline.
- Não há migração automática do MySQL para os dispositivos.

## Testes

```powershell
flutter analyze
flutter test
```
