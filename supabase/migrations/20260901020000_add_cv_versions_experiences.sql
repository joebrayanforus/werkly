alter table public.cv_versions
  add column experiences jsonb not null default '[]'::jsonb;
