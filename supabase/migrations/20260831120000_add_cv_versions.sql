create table public.cv_versions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  label text not null default '',
  category text not null default 'Tous domaines'
    check (category in (
      'Tous domaines', 'Informatique', 'Ingénierie',
      'Business & Finance', 'Marketing & Design', 'Data & IA'
    )),
  university text not null default '',
  degree text not null default '',
  city text not null default '',
  professional_summary text not null default '',
  skills jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.cv_versions enable row level security;

create policy "cv_versions_manage_own" on public.cv_versions
  for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create index cv_versions_user_id_idx on public.cv_versions (user_id);
