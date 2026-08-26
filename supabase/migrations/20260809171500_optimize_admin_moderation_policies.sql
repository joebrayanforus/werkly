create index if not exists employer_job_submissions_reviewed_by_idx
  on public.employer_job_submissions (reviewed_by);

drop policy if exists "employer_submissions_select_own"
  on public.employer_job_submissions;
drop policy if exists "employer_submissions_admin_select"
  on public.employer_job_submissions;
create policy "employer_submissions_select_owner_or_admin"
on public.employer_job_submissions for select
to authenticated
using (
  (select auth.uid()) = submitted_by
  or ((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin'
);

drop policy if exists "employer_submissions_update_pending_own"
  on public.employer_job_submissions;
drop policy if exists "employer_submissions_admin_update"
  on public.employer_job_submissions;
create policy "employer_submissions_update_owner_or_admin"
on public.employer_job_submissions for update
to authenticated
using (
  ((select auth.uid()) = submitted_by and status = 'pending')
  or ((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  ((select auth.uid()) = submitted_by and status = 'pending')
  or ((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin'
);
