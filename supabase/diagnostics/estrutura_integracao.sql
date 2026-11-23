-- Somente leitura: estrutura, permissoes e catalogo de categorias.
with alvo as (
  select c.oid, c.relname as tabela, c.relrowsecurity as rls_ativo
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind in ('r', 'p')
    and c.relname in (
      'perfis', 'categorias', 'estabelecimentos', 'avaliacoes', 'favoritos'
    )
)
select jsonb_build_object(
  'tabelas', (
    select jsonb_agg(
      jsonb_build_object('tabela', tabela, 'rls_ativo', rls_ativo)
      order by tabela
    ) from alvo
  ),
  'colunas', (
    select jsonb_agg(to_jsonb(x) order by x.tabela, x.ordem)
    from (
      select t.tabela, a.attnum as ordem, a.attname as coluna,
        format_type(a.atttypid, a.atttypmod) as tipo,
        a.attnotnull as obrigatoria, a.attidentity as identidade,
        a.attgenerated as gerada,
        pg_get_expr(d.adbin, d.adrelid) as valor_padrao
      from alvo t
      join pg_attribute a on a.attrelid = t.oid
      left join pg_attrdef d on d.adrelid = t.oid and d.adnum = a.attnum
      where a.attnum > 0 and not a.attisdropped
    ) x
  ),
  'restricoes', (
    select jsonb_agg(to_jsonb(x) order by x.tabela, x.nome)
    from (
      select t.tabela, k.conname as nome, k.contype as tipo,
        pg_get_constraintdef(k.oid, true) as definicao
      from alvo t join pg_constraint k on k.conrelid = t.oid
    ) x
  ),
  'indices', (
    select jsonb_agg(to_jsonb(i) order by i.tablename, i.indexname)
    from pg_indexes i
    where i.schemaname = 'public'
      and i.tablename in (select tabela from alvo)
  ),
  'politicas', (
    select jsonb_agg(to_jsonb(p) order by p.tablename, p.policyname)
    from pg_policies p
    where p.schemaname = 'public'
      and p.tablename in (select tabela from alvo)
  ),
  'permissoes', (
    select jsonb_agg(to_jsonb(x) order by x.tabela, x.papel)
    from (
      select t.tabela, r.papel,
        has_schema_privilege(r.papel, 'public', 'USAGE') as acesso_schema,
        has_table_privilege(r.papel, t.oid, 'SELECT') as leitura,
        has_table_privilege(r.papel, t.oid, 'INSERT') as insercao,
        has_table_privilege(r.papel, t.oid, 'UPDATE') as atualizacao,
        has_table_privilege(r.papel, t.oid, 'DELETE') as exclusao
      from alvo t
      cross join (values ('anon'::name), ('authenticated'::name)) r(papel)
    ) x
  ),
  'categorias_cadastradas', (
    select coalesce(jsonb_agg(to_jsonb(c)), '[]'::jsonb)
    from public.categorias c
  )
) as estrutura;