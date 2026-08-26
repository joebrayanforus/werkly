-- Keep provider snapshots consistent: rows absent from the latest complete
-- source response can be deactivated only after the new snapshot is stored.
alter table public.jobs
  add column if not exists last_seen_at timestamptz;

alter table public.jobs
  alter column last_seen_at set default now();

update public.jobs
set last_seen_at = coalesce(last_seen_at, created_at, posted_at, now())
where last_seen_at is null;

alter table public.jobs
  alter column last_seen_at set not null;

create index if not exists jobs_source_last_seen_at_idx
  on public.jobs (source, last_seen_at);

alter table public.job_sync_state
  add column if not exists sync_started_at timestamptz,
  add column if not exists sync_token uuid;

insert into public.job_sync_state (
  source,
  last_synced_at,
  item_count,
  details
)
values (
  'free-multi-source',
  now() - interval '1 day',
  0,
  '{}'::jsonb
)
on conflict (source) do nothing;

-- An atomic lease prevents two app/cron requests from publishing interleaved
-- snapshots. Ten minutes also covers a future move to a higher runtime limit.
create or replace function public.claim_free_job_sync(p_token uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
strict
as $$
declare
  claimed_rows integer;
begin
  update public.job_sync_state
  set sync_started_at = now(),
      sync_token = p_token
  where source = 'free-multi-source'
    and last_synced_at <= now() - interval '20 minutes'
    and (
      sync_started_at is null
      or sync_started_at < now() - interval '10 minutes'
    );

  get diagnostics claimed_rows = row_count;
  return claimed_rows = 1;
end;
$$;

revoke all on function public.claim_free_job_sync(uuid) from public, anon, authenticated;
grant execute on function public.claim_free_job_sync(uuid) to service_role;

do $check_vault$
begin
  if not exists (
    select 1 from vault.secrets where name = 'werkly_project_url'
  ) then
    raise exception 'Missing Vault secret: werkly_project_url';
  end if;

  if not exists (
    select 1 from vault.secrets where name = 'werkly_publishable_key'
  ) then
    raise exception 'Missing Vault secret: werkly_publishable_key';
  end if;
end
$check_vault$;

-- Arbeitnow recommends restrained polling. Two runs per day keep the app
-- fresh while remaining far below the public APIs' documented limits.
select cron.schedule(
  'werkly-daily-job-sync',
  '17 3,15 * * *',
  $job$
  select net.http_post(
    url := (
      select decrypted_secret
      from vault.decrypted_secrets
      where name = 'werkly_project_url'
    ) || '/functions/v1/sync-free-jobs',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', (
        select decrypted_secret
        from vault.decrypted_secrets
        where name = 'werkly_publishable_key'
      )
    ),
    body := jsonb_build_object(
      'trigger', 'cron',
      'scheduled_at', now()
    ),
    timeout_milliseconds := 60000
  ) as request_id;
  $job$
);
