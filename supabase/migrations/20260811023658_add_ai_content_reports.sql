create table public.ai_content_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  message_excerpt text not null check (
    char_length(message_excerpt) between 1 and 4000
  ),
  reason text not null check (
    reason in ('inaccurate', 'offensive', 'unsafe', 'other')
  ),
  details text check (
    details is null or char_length(details) <= 1000
  ),
  created_at timestamptz not null default now()
);

comment on table public.ai_content_reports is
  'User reports for generated AI answers. Accessible to users only for insert; review is server-side.';

alter table public.ai_content_reports enable row level security;

revoke all on table public.ai_content_reports from anon, authenticated;
grant insert on table public.ai_content_reports to authenticated;

create policy "Authenticated users can report AI content"
on public.ai_content_reports
for insert
to authenticated
with check ((select auth.uid()) = user_id);

create index ai_content_reports_user_created_idx
on public.ai_content_reports (user_id, created_at desc);
