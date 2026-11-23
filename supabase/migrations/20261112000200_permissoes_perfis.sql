begin;
grant usage on schema public to authenticated;
grant select, insert on table public.perfis to authenticated;
commit;