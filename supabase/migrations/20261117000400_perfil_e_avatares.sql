-- Perfil do usuario: editar o proprio nome e enviar foto de perfil.
-- Aplicar no SQL Editor do Supabase. Pode ser executada mais de uma vez.
begin;

-- 1) Cada conta pode alterar somente o PROPRIO nome (nao id nem e-mail).
grant update (nome) on table public.perfis to authenticated;

drop policy if exists perfis_atualizar_proprio on public.perfis;
create policy perfis_atualizar_proprio
on public.perfis for update to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

-- 2) Bucket publico das fotos de perfil: JPEG, PNG e WebP, ate 2 MiB.
insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values (
  'avatares', 'avatares', true, 2097152,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

-- Caminho: <id_do_usuario>/avatar. Cada conta escreve so na propria pasta.
drop policy if exists avatares_ler on storage.objects;
create policy avatares_ler
on storage.objects for select to anon, authenticated
using (bucket_id = 'avatares');

drop policy if exists avatares_inserir on storage.objects;
create policy avatares_inserir
on storage.objects for insert to authenticated
with check (
  bucket_id = 'avatares'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists avatares_atualizar on storage.objects;
create policy avatares_atualizar
on storage.objects for update to authenticated
using (
  bucket_id = 'avatares'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'avatares'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists avatares_excluir on storage.objects;
create policy avatares_excluir
on storage.objects for delete to authenticated
using (
  bucket_id = 'avatares'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

notify pgrst, 'reload schema';

commit;

-- Conferencia (deve mostrar o bucket e 4 politicas de storage):
select
  (select count(*) from storage.buckets where id = 'avatares') as bucket,
  (select count(*) from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname like 'avatares_%') as politicas_storage,
  (select count(*) from pg_policies
    where schemaname = 'public' and tablename = 'perfis'
      and policyname = 'perfis_atualizar_proprio') as politica_perfis;
