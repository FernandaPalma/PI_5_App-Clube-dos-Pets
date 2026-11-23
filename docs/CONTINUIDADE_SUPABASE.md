# Continuidade da integração Supabase

Registro em 12/11/2026. Branch: `feat/integracao-supabase`.
O aplicativo integrado é o da raiz do repositório, com `lib/main.dart` e `pubspec.yaml`.

## Estado confirmado

- Cadastro, confirmação de e-mail e login testados com conta real.
- `SupabaseAuthDataSource` implementa o contrato `AuthDataSource`.
- `main.dart` injeta autenticação Supabase; os testes de widgets mantêm a composição local.
- O perfil é consultado/criado após existir sessão autenticada. Senhas ficam no Supabase Auth.
- O erro 42501 de `perfis` foi corrigido concedendo SELECT e INSERT a `authenticated`.
- Logout implementado e coberto por teste automatizado; falta registrar a validação manual.
- Verificacao desta etapa: flutter analyze e flutter test aprovados.
- Fonte remota implementada. Migration 003 aplicada; validar os fluxos descritos em INTEGRACAO_DADOS_SUPABASE.md.

## Executar o aplicativo

1. Trabalhar na raiz do repositório e na branch indicada.
2. Na primeira configuração, copiar `config/supabase.example.json` para `config/supabase.local.json`.
3. Preencher a Publishable key do projeto no arquivo local, ignorado pelo Git.
4. Executar:

```powershell
flutter pub get
flutter run -d chrome --web-port=3000 --dart-define-from-file=config/supabase.local.json
```

A URL deve ser a base do projeto, sem `/rest/v1/`. Contas da demonstração local não são contas do Supabase.

## Banco e migrações

- Projeto: `clube-dos-pets-mobile`.
- Tabelas: `perfis`, `categorias`, `estabelecimentos`, `avaliacoes`, `favoritos`.
- RLS configurado; as permissoes dos fluxos implementados estao nas migrations 002 e 003.
- `20261112000100_postgis_e_imagens.sql`: PostGIS, RPC e Storage, já aplicados.
- `20261112000200_permissoes_perfis.sql`: permissões de perfis, já aplicadas via SQL Editor.
- A estrutura inicial das cinco tabelas ainda precisa de uma versão completa no repositório.
- As migrações registram alterações aplicadas manualmente. O histórico do Supabase CLI ainda não foi reconciliado. A migração 001 não deve ser reaplicada no projeto existente: contém objetos que já existem.

## Contratos disponíveis

- RPC: `buscar_locais_proximos(lat_ref, lng_ref, raio_metros)`. Raio em metros; retorna estabelecimentos ordenados por distância.
- Gravar `latitude` e `longitude`; a coluna `localizacao` é calculada pelo banco.
- Bucket público: `estabelecimentos-imagens`; limite de 5 MiB; JPEG, PNG e WebP.
- Caminho de imagem: `<uuid_do_estabelecimento>/<id_da_imagem>.<extensao>`.
- Escrita nas imagens exige que a conta seja a responsável pelo estabelecimento.

## Próxima implementação

Consultar `INTEGRACAO_DADOS_SUPABASE.md` para contratos e testes da fonte remota.
Migration 003 aplicada. Confirmar cadastro, favoritos e avaliacao no banco real.
Continuam pendentes imagens, interface de localizacao, categorias dinamicas,
validacao com duas contas, celular/emulador e o schema inicial completo.

## Validação antes do PR

- Login, logout e restauração da sessão ao reabrir o aplicativo.
- Cadastro e confirmação de e-mail com outra conta.
- Dados persistidos no Supabase e acessíveis em outra execução/dispositivo.
- Duas contas: impedir alteração de dados e imagens pertencentes à outra conta.
- Proximidade com coordenadas conhecidas, dentro e fora do raio.
- Upload permitido ao responsável, limites/tipos de arquivo e exibição pública.
- Testes em celular/emulador e revisão dos logs `[PI-...]`, habilitados somente em debug.
- `flutter analyze` e `flutter test` aprovados; revisão do PR antes do merge com `main`.

Os testes automatizados usam simulações de HTTP e não comprovam as políticas do banco real. A validação com duas contas continua pendente.