create schema if not exists private;

create table if not exists public.job_sync_state (
  source text primary key,
  last_synced_at timestamptz not null default now(),
  item_count integer not null default 0 check (item_count >= 0),
  details jsonb not null default '{}'::jsonb
);

alter table public.job_sync_state enable row level security;
revoke all on public.job_sync_state from anon, authenticated;
grant all on public.job_sync_state to service_role;

create table if not exists public.employer_job_submissions (
  id uuid primary key default gen_random_uuid(),
  submitted_by uuid not null references auth.users(id) on delete cascade,
  company_name text not null check (char_length(company_name) between 2 and 200),
  contact_name text not null check (char_length(contact_name) between 2 and 160),
  contact_email text not null check (char_length(contact_email) <= 320 and position('@' in contact_email) > 1),
  title text not null check (char_length(title) between 3 and 300),
  location text not null check (char_length(location) between 2 and 300),
  remote_type text not null default 'onsite' check (remote_type in ('onsite', 'hybrid', 'remote')),
  salary_min numeric check (salary_min is null or salary_min >= 0),
  salary_max numeric check (salary_max is null or salary_max >= salary_min),
  source_url text not null check (source_url ~ '^https://[^[:space:]]+$'),
  tags text[] not null default '{}',
  description text not null check (char_length(description) between 40 and 8000),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  review_notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists employer_job_submissions_owner_idx
  on public.employer_job_submissions (submitted_by, created_at desc);
create index if not exists employer_job_submissions_review_idx
  on public.employer_job_submissions (status, created_at);

alter table public.employer_job_submissions enable row level security;

revoke all on public.employer_job_submissions from anon;
grant select, insert, update on public.employer_job_submissions to authenticated;
grant all on public.employer_job_submissions to service_role;

drop policy if exists "employer_submissions_select_own" on public.employer_job_submissions;
create policy "employer_submissions_select_own"
on public.employer_job_submissions for select
to authenticated
using ((select auth.uid()) = submitted_by);

drop policy if exists "employer_submissions_insert_own" on public.employer_job_submissions;
create policy "employer_submissions_insert_own"
on public.employer_job_submissions for insert
to authenticated
with check (
  (select auth.uid()) = submitted_by
  and status = 'pending'
);

drop policy if exists "employer_submissions_update_pending_own" on public.employer_job_submissions;
create policy "employer_submissions_update_pending_own"
on public.employer_job_submissions for update
to authenticated
using (
  (select auth.uid()) = submitted_by
  and status = 'pending'
)
with check (
  (select auth.uid()) = submitted_by
  and status = 'pending'
);

create or replace function private.publish_approved_employer_job()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status = 'approved' then
    insert into public.jobs (
      external_id,
      title,
      company,
      location,
      remote_type,
      salary_min,
      salary_max,
      source,
      source_url,
      tags,
      description,
      posted_at,
      active
    ) values (
      'employer-' || new.id::text,
      new.title,
      new.company_name,
      new.location,
      new.remote_type,
      new.salary_min,
      new.salary_max,
      'Entreprise vérifiée',
      new.source_url,
      new.tags,
      new.description,
      now(),
      true
    )
    on conflict (source, external_id) do update set
      title = excluded.title,
      company = excluded.company,
      location = excluded.location,
      remote_type = excluded.remote_type,
      salary_min = excluded.salary_min,
      salary_max = excluded.salary_max,
      source_url = excluded.source_url,
      tags = excluded.tags,
      description = excluded.description,
      posted_at = excluded.posted_at,
      active = true;
  elsif old.status = 'approved' and new.status <> 'approved' then
    update public.jobs
    set active = false
    where source = 'Entreprise vérifiée'
      and external_id = 'employer-' || new.id::text;
  end if;
  return new;
end;
$$;

drop trigger if exists publish_approved_employer_job on public.employer_job_submissions;
create trigger publish_approved_employer_job
after insert or update of status on public.employer_job_submissions
for each row execute function private.publish_approved_employer_job();

revoke all on function private.publish_approved_employer_job() from public, anon, authenticated;
