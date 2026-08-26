-- 20260806185213_employer_job_submissions.sql revoked EXECUTE on
-- private.publish_approved_employer_job() from public/anon/authenticated,
-- but that trigger fires "after insert or update of status" on
-- employer_job_submissions, i.e. on every job posting a signed-in user
-- submits, invoked as the authenticated role. Without EXECUTE it can never
-- fire, so submitting a job (and later an admin approving it) failed with
-- a permission-denied error.
--
-- The function also writes into public.jobs, which only has a select
-- policy for regular users. Without security definer, that insert/update
-- is silently blocked by RLS even once the function itself can run, so an
-- approved submission never actually became a visible job listing.
--
-- private.publish_approved_employer_job() lives in the private schema,
-- which is not exposed over the PostgREST API, so re-granting EXECUTE to
-- authenticated does not let clients call it directly via RPC.
alter function private.publish_approved_employer_job() security definer;
grant execute on function private.publish_approved_employer_job() to authenticated;
