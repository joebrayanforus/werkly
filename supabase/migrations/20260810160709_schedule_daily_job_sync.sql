create extension if not exists pg_net;
create extension if not exists pg_cron;

do $$
begin
  if not exists (select 1 from vault.secrets where name = 'werkly_project_url') then
    perform vault.create_secret(
      'https://bygqatraidykcxjfjala.supabase.co',
      'werkly_project_url',
      'Werkly Edge Function base URL'
    );
  end if;
  if not exists (select 1 from vault.secrets where name = 'werkly_publishable_key') then
    perform vault.create_secret(
      'sb_publishable_bE4vhtX2id53rSg1DpnmxA_8xxGFnui',
      'werkly_publishable_key',
      'Werkly public Edge Function key'
    );
  end if;
end
$$;

select cron.unschedule(jobid)
from cron.job
where jobname in ('werkly-daily-job-sync', 'werkly-deactivate-stale-jobs');

select cron.schedule(
  'werkly-daily-job-sync',
  '17 3 * * *',
  $job$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'werkly_project_url') || '/functions/v1/sync-free-jobs',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', (select decrypted_secret from vault.decrypted_secrets where name = 'werkly_publishable_key')
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 15000
  ) as request_id;
  $job$
);

select cron.schedule(
  'werkly-deactivate-stale-jobs',
  '47 3 * * *',
  $job$
  update public.jobs
  set active = false
  where active = true
    and (
      (expires_at is not null and expires_at < now())
      or posted_at < now() - interval '120 days'
    );
  $job$
);
