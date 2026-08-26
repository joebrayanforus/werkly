alter table public.profiles
  add column if not exists cv_analysis jsonb not null default '{}'::jsonb,
  add column if not exists cv_analysis_status text not null default 'not_started'
    check (cv_analysis_status in ('not_started', 'processing', 'complete', 'failed')),
  add column if not exists cv_analysis_error text not null default '',
  add column if not exists cv_analyzed_at timestamptz,
  add column if not exists cv_ai_consent_at timestamptz;

comment on column public.profiles.cv_analysis is
  'Structured, user-owned CV analysis generated from the private CV object.';

comment on column public.profiles.cv_ai_consent_at is
  'Timestamp of the explicit user consent to send the private CV to the configured AI processor.';

drop policy if exists "cv_update_own" on storage.objects;
create policy "cv_update_own" on storage.objects
for update to authenticated
using (
  bucket_id = 'cvs'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'cvs'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
