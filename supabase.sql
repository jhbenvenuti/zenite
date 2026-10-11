-- Zênite: estrutura do banco de dados no Supabase
-- Cole tudo no SQL Editor do Supabase e clique em Run. Pode rodar mais de uma vez sem problema.

create table if not exists public.docs (
  path text primary key,
  col text not null,
  id text not null,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  lease_holder text,
  lease_until timestamptz
);
create index if not exists docs_col_idx on public.docs (col);
alter table public.docs replica identity full;
alter table public.docs enable row level security;

-- Só jogadores logados leem e gravam
drop policy if exists "zenite_ler" on public.docs;
drop policy if exists "zenite_inserir" on public.docs;
drop policy if exists "zenite_alterar" on public.docs;
drop policy if exists "zenite_apagar" on public.docs;
create policy "zenite_ler" on public.docs for select to authenticated using (true);
create policy "zenite_inserir" on public.docs for insert to authenticated with check (true);
create policy "zenite_alterar" on public.docs for update to authenticated using (true) with check (true);
create policy "zenite_apagar" on public.docs for delete to authenticated using (true);

-- Atualizações em tempo real (duelos, mural, ranking)
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'docs') then
    alter publication supabase_realtime add table public.docs;
  end if;
end $$;

-- Mescla dois JSON em profundidade (para atualizar só parte de um registro)
create or replace function public.jsonb_deep_merge(a jsonb, b jsonb) returns jsonb
language plpgsql immutable as $$
declare k text; r jsonb;
begin
  if a is null or jsonb_typeof(a) <> 'object' or b is null or jsonb_typeof(b) <> 'object' then
    return b;
  end if;
  r := a;
  for k in select jsonb_object_keys(b) loop
    if r ? k and jsonb_typeof(r -> k) = 'object' and jsonb_typeof(b -> k) = 'object' then
      r := jsonb_set(r, array[k], public.jsonb_deep_merge(r -> k, b -> k));
    else
      r := jsonb_set(r, array[k], b -> k);
    end if;
  end loop;
  return r;
end $$;

create or replace function public.doc_update(p_path text, p_patch jsonb) returns boolean
language plpgsql as $$
begin
  update public.docs set data = public.jsonb_deep_merge(data, p_patch), updated_at = now() where path = p_path;
  return found;
end $$;

-- Trava curta para evitar que duas pessoas resolvam o mesmo duelo ou comprem o mesmo item
create or replace function public.doc_acquire(p_path text, p_holder text, p_ttl_ms int) returns boolean
language plpgsql as $$
begin
  if not exists (select 1 from public.docs where path = p_path) then
    return true;
  end if;
  update public.docs
     set lease_holder = p_holder,
         lease_until = now() + make_interval(secs => greatest(p_ttl_ms, 1000) / 1000.0)
   where path = p_path
     and (lease_until is null or lease_until < now() or lease_holder = p_holder);
  return found;
end $$;

grant execute on function public.jsonb_deep_merge(jsonb, jsonb) to authenticated;
grant execute on function public.doc_update(text, jsonb) to authenticated;
grant execute on function public.doc_acquire(text, text, int) to authenticated;
