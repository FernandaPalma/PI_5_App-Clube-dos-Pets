# Integração dos dados remotos

A migration `20261112000300_dados_remotos.sql` foi aplicada no projeto clube-dos-pets-mobile. As seis categorias e as permissoes foram conferidas.

## Implementação

- `SupabasePetsDataSource` implementa `PetsDataSource` e é injetado em `main.dart`.
- Os testes de widgets continuam locais. Os novos testes de dados usam HTTP simulado.
- Categorias são lidas do banco e convertidas de `categoria_id` para o nome usado por `LugarModel`.
- A migration cadastra as seis opções do formulário atual.
- Estabelecimentos recebem `responsavel_id` da sessão. O banco gera os UUIDs.
- Uma avaliação por conta/estabelecimento; nova avaliação atualiza nota e comentário. Escala de 1 a 5.
- Perfis permanecem privados. Avaliações mostram `Você` ou `Usuário`, pois a tabela não possui nome público do autor.
- Favoritos são filtrados pela conta. A RPC `alternar_favorito(p_estabelecimento_id)` alterna o registro em uma transação.
- `lugaresProximos(latitude:, longitude:, raioMetros:)` chama a RPC geográfica existente. Ainda falta expor o método pelo domínio/repositório e ligá-lo à interface.
- Listagens usam lotes de 200. Se o limite da Data API for menor, ajustar o tamanho do lote.

## Validação manual pendente

1. Cadastrar estabelecimento identificado como teste e conferir no banco.
2. Marcar/desmarcar favorito e conferir em `favoritos`.
3. Avaliar e alterar a nota; confirmar uma única avaliação da conta para o local.
4. Sair e entrar novamente; confirmar persistência.
5. Validar autorização usando duas contas.

Os exemplos locais não são migrados automaticamente. Os dados locais existentes são preservados; a lista remota pode começar vazia.

## Continuidade

- Upload e exibição de imagens.
- Coordenadas no cadastro, interface de localização e busca por proximidade.
- Dropdown de categorias alimentado dinamicamente pelo banco.
- Confirmar com a equipe/MER a administração dos estabelecimentos; a RLS atual autoriza o responsável.
- Testes com duas contas e celular/emulador.
- Versionar a estrutura inicial completa e reconciliar o histórico das migrations aplicadas manualmente.
- Revisar o PR antes do merge em `main`.

Índices únicos e vínculos obrigatórios são adicionados sem excluir dados. Duplicatas ou avaliações sem vínculos fazem a migration abortar para revisão.
## Estado confirmado para entrega

- Cadastro, confirmacao de e-mail e login funcionaram com uma conta real.
- Migration 003 aplicada; seis categorias e permissoes verificadas no Supabase.
- Analise e testes automatizados aprovados na preparacao deste commit.
- Testes reais de estabelecimentos, favoritos e avaliacoes ainda pendentes.
- Cadastro com outra conta, envio de e-mail e restauracao da sessao ainda precisam ser validados.
- As demais pendencias de continuidade permanecem listadas acima.
