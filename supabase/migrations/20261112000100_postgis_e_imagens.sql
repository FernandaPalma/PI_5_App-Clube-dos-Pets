begin;

create schema if not exists extensions;
create extension if not exists postgis with schema extensions;
grant usage on schema extensions to anon, authenticated;

-- O aplicativo grava latitude/longitude; o banco calcula o ponto.
alter table public.estabelecimentos
  add column localizacao extensions.geography(Point, 4326)
  generated always as (
    case
      when latitude between -90 and 90
       and longitude between -180 and 180
      then extensions.st_setsrid(
        extensions.st_makepoint(longitude, latitude), 4326
      )::extensions.geography
      else null
    end
  ) stored;

create index estabelecimentos_localizacao_gist
  on public.estabelecimentos using gist (localizacao);

create function public.buscar_locais_proximos(
  lat_ref double precision,
  lng_ref double precision,
  raio_metros double precision
)
returns setof public.estabelecimentos
language plpgsql
stable
security invoker
set search_path = ''
as $func$
declare
  origem extensions.geography;
begin
  if lat_ref is null or not (lat_ref between -90 and 90)
     or lng_ref is null or not (lng_ref between -180 and 180) then
    raise exception 'Latitude ou longitude invalida.'
      using errcode = '22023';
  end if;

  if raio_metros is null
     or not (raio_metros >= 0 and raio_metros < 'Infinity'::double precision) then
    raise exception 'O raio deve ser finito e maior ou igual a zero.'
      using errcode = '22023';
  end if;

  origem := extensions.st_setsrid(
    extensions.st_makepoint(lng_ref, lat_ref), 4326
  )::extensions.geography;

  return query
    select e.*
    from public.estabelecimentos e
    where e.localizacao is not null
      and extensions.st_dwithin(e.localizacao, origem, raio_metros)
    order by extensions.st_distance(e.localizacao, origem), e.id;
end;
$func$;

revoke all on function public.buscar_locais_proximos(
  double precision, double precision, double precision
) from public;

grant execute on function public.buscar_locais_proximos(
  double precision, double precision, double precision
) to anon, authenticated;

grant select on public.estabelecimentos to anon, authenticated;

-- Bucket de fotos publicas: JPEG, PNG e WebP, ate 5 MiB.
insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values (
  'estabelecimentos-imagens',
  'estabelecimentos-imagens',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
);

-- Permite listar as fotos para montar a galeria.
create policy est_imagens_ler
on storage.objects for select to anon, authenticated
using (bucket_id = 'estabelecimentos-imagens');

-- Caminho: <id_do_estabelecimento>/<id_da_imagem>.jpg
create policy est_imagens_inserir
on storage.objects for insert to authenticated
with check (
  bucket_id = 'estabelecimentos-imagens'
  and exists (
    select 1 from public.estabelecimentos e
    where e.id::text = (storage.foldername(storage.objects.name))[1]
      and e.responsavel_id = (select auth.uid())
  )
);

create policy est_imagens_atualizar
on storage.objects for update to authenticated
using (
  bucket_id = 'estabelecimentos-imagens'
  and exists (
    select 1 from public.estabelecimentos e
    where e.id::text = (storage.foldername(storage.objects.name))[1]
      and e.responsavel_id = (select auth.uid())
  )
)
with check (
  bucket_id = 'estabelecimentos-imagens'
  and exists (
    select 1 from public.estabelecimentos e
    where e.id::text = (storage.foldername(storage.objects.name))[1]
      and e.responsavel_id = (select auth.uid())
  )
);

create policy est_imagens_excluir
on storage.objects for delete to authenticated
using (
  bucket_id = 'estabelecimentos-imagens'
  and exists (
    select 1 from public.estabelecimentos e
    where e.id::text = (storage.foldername(storage.objects.name))[1]
      and e.responsavel_id = (select auth.uid())
  )
);

notify pgrst, 'reload schema';

-- Verifica a chamada publica antes de confirmar a transacao.
set local role anon;
do $teste$
begin
  perform count(*)
  from public.buscar_locais_proximos(-22.3550, -47.3810, 10000);

  begin
    perform count(*) from public.buscar_locais_proximos(91, 0, 10000);
    raise exception 'A RPC aceitou latitude invalida.';
  exception when sqlstate '22023' then null;
  end;

  begin
    perform count(*) from public.buscar_locais_proximos(0, 0, -1);
    raise exception 'A RPC aceitou raio negativo.';
  exception when sqlstate '22023' then null;
  end;
end;
$teste$;

commit;

select jsonb_build_object(
  'postgis_schema', (
    select n.nspname
    from pg_extension e
    join pg_namespace n on n.oid = e.extnamespace
    where e.extname = 'postgis'
  ),
  'bucket', (
    select jsonb_build_object(
      'id', id,
      'publico', public,
      'limite_bytes', file_size_limit,
      'formatos', allowed_mime_types
    )
    from storage.buckets
    where id = 'estabelecimentos-imagens'
  ),
  'politicas_storage', (
    select count(*)
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname in (
        'est_imagens_ler', 'est_imagens_inserir',
        'est_imagens_atualizar', 'est_imagens_excluir'
      )
  ),
  'total_estabelecimentos', (
    select count(*) from public.estabelecimentos
  ),
  'com_coordenadas_validas', (
    select count(*) from public.estabelecimentos
    where localizacao is not null
  ),
  'encontrados_em_10km', (
    select count(*)
    from public.buscar_locais_proximos(-22.3550, -47.3810, 10000)
  )
) as verificacao;
