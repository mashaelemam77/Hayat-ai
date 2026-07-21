create extension if not exists pgcrypto;

create table if not exists public.reports (
  id text primary key default ('RPT-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8))),
  subject text not null,
  description text not null default '',
  date date not null default current_date,
  type text not null default 'أخرى',
  status text not null default 'جديد',
  severity text not null default 'متوسطة',
  location text not null default '',
  department text not null default '',
  reporter_name text not null default '',
  reporter_phone text not null default '',
  analysis text not null default '',
  image_analysis text not null default '',
  audio_analysis text not null default '',
  image_path text not null default '',
  voice_path text not null default '',
  document_path text not null default '',
  maps_url text not null default '',
  report_text text not null default '',
  created_at timestamptz not null default now()
);


alter table public.reports
  add column if not exists date date not null default current_date;

alter table public.reports
  add column if not exists image_analysis text not null default '',
  add column if not exists audio_analysis text not null default '',
  add column if not exists image_path text not null default '',
  add column if not exists voice_path text not null default '',
  add column if not exists document_path text not null default '',
  add column if not exists maps_url text not null default '',
  add column if not exists report_text text not null default '',
  add column if not exists location_desc text not null default '';

alter table public.reports enable row level security;

drop policy if exists "Allow public report insert" on public.reports;
create policy "Allow public report insert"
  on public.reports for insert
  to anon
  with check (true);

drop policy if exists "Allow public report read" on public.reports;
create policy "Allow public report read"
  on public.reports for select
  to anon
  using (true);

drop policy if exists "Allow public report update" on public.reports;
create policy "Allow public report update"
  on public.reports for update
  to anon
  using (true)
  with check (true);

drop policy if exists "Allow public report delete" on public.reports;
create policy "Allow public report delete"
  on public.reports for delete
  to anon
  using (true);

-- Enable realtime updates for the mobile reports list.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'reports'
  ) then
    alter publication supabase_realtime add table public.reports;
  end if;
end $$;
