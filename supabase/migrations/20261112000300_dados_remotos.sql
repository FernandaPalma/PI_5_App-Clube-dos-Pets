begin;

grant usage on schema public to anon, authenticated;
grant select on public.categorias, public.estabelecimentos, public.avaliacoes
  to anon, authenticated;
grant insert, update, delete on public.estabelecimentos, public.avaliacoes
  to authenticated;
grant select, insert, delete on public.favoritos to authenticated;

-- Toda avaliacao precisa estar ligada a uma conta e a um estabelecimento.
alter table public.avaliacoes
  alter column usuario_id set not null,
  alter column estabelecimento_id set not null;

-- Nulos ou duplicatas preexistentes abortam a transacao; nada e apagado.
create unique index if not exists categorias_nome_unico
  on public.categorias (nome);

create unique index if not exists avaliacoes_usuario_estabelecimento_unico
  on public.avaliacoes (usuario_id, estabelecimento_id);

-- Mesmas opcoes do formulario atual do aplicativo.
insert into public.categorias (nome)
values ('Parques'), ('Veterinários'), ('Hotéis pet'),
       ('Restaurantes'), ('Pet shops'), ('Outros')
on conflict (nome) do nothing;

create or replace function public.alternar_favorito(p_estabelecimento_id uuid)
returns boolean
language plpgsql
security invoker
set search_path = ''
as $func$
declare
  usuario uuid := auth.uid();
  removidos integer;
begin
  if usuario is null then
    raise exception 'Autenticacao necessaria.' using errcode = '42501';
  end if;

  if p_estabelecimento_id is null then
    raise exception 'Estabelecimento obrigatorio.' using errcode = '22023';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      usuario::text || ':' || p_estabelecimento_id::text, 0
    )
  );

  delete from public.favoritos
  where usuario_id = usuario
    and estabelecimento_id = p_estabelecimento_id;

  get diagnostics removidos = row_count;
  if removidos > 0 then
    return false;
  end if;

  insert into public.favoritos (usuario_id, estabelecimento_id)
  values (usuario, p_estabelecimento_id);

  return true;
end;
$func$;

revoke all on function public.alternar_favorito(uuid) from public;
grant execute on function public.alternar_favorito(uuid) to authenticated;

notify pgrst, 'reload schema';
commit;

select jsonb_build_object(
  'categorias',
    (select jsonb_agg(nome order by nome) from public.categorias),
  'leitura_categorias',
    has_table_privilege('authenticated', 'public.categorias', 'SELECT'),
  'cadastro_estabelecimentos',
    has_table_privilege('authenticated', 'public.estabelecimentos', 'INSERT'),
  'leitura_avaliacoes',
    has_table_privilege('authenticated', 'public.avaliacoes', 'SELECT'),
  'cadastro_avaliacoes',
    has_table_privilege('authenticated', 'public.avaliacoes', 'INSERT'),
  'leitura_favoritos',
    has_table_privilege('authenticated', 'public.favoritos', 'SELECT'),
  'rpc_favoritos',
    has_function_privilege(
      'authenticated', 'public.alternar_favorito(uuid)', 'EXECUTE'
    )
) as verificacao;