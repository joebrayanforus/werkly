drop policy if exists "job_sync_state_no_client_access" on public.job_sync_state;
create policy "job_sync_state_no_client_access"
on public.job_sync_state for select
to anon, authenticated
using (false);
