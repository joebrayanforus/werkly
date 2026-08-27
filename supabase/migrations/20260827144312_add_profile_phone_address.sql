alter table public.profiles
  add column phone text not null default '',
  add column address text not null default '';
