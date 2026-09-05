alter table public.applications
  add column keywords_copied boolean not null default false,
  add column materials_prepared boolean not null default false;
