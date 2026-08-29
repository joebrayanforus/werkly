alter table public.profiles
  add column if not exists language text not null default 'en'
  check (language in ('fr', 'de', 'en'));
