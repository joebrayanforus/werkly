alter table public.employer_job_submissions
  add column if not exists reviewed_by uuid references auth.users(id) on delete set null,
  add column if not exists reviewed_at timestamptz;

create index if not exists employer_job_submissions_pending_created_idx
  on public.employer_job_submissions (created_at desc)
  where status = 'pending';

drop policy if exists "employer_submissions_admin_select" on public.employer_job_submissions;
create policy "employer_submissions_admin_select"
on public.employer_job_submissions for select
to authenticated
using (((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin');

drop policy if exists "employer_submissions_admin_update" on public.employer_job_submissions;
create policy "employer_submissions_admin_update"
on public.employer_job_submissions for update
to authenticated
using (((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin')
with check (((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin');

create or replace function private.guard_employer_submission_review()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  is_admin boolean := coalesce(
    ((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin',
    false
  );
begin
  if not is_admin and (
    new.status is distinct from old.status
    or new.review_notes is distinct from old.review_notes
    or new.reviewed_by is distinct from old.reviewed_by
    or new.reviewed_at is distinct from old.reviewed_at
  ) then
    raise exception 'Only administrators can review employer submissions';
  end if;

  if is_admin and new.status is distinct from old.status then
    new.reviewed_by := (select auth.uid());
    new.reviewed_at := now();
  end if;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists guard_employer_submission_review
  on public.employer_job_submissions;
create trigger guard_employer_submission_review
before update on public.employer_job_submissions
for each row execute function private.guard_employer_submission_review();

revoke all on function private.guard_employer_submission_review()
  from public, anon, authenticated;

comment on column public.employer_job_submissions.reviewed_by is
  'Administrator who approved or rejected the submission.';
comment on column public.employer_job_submissions.reviewed_at is
  'Timestamp of the latest moderation decision.';
