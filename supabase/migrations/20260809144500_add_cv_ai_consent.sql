alter table public.profiles
  add column if not exists cv_ai_consent_at timestamptz;

comment on column public.profiles.cv_ai_consent_at is
  'Timestamp of the explicit user consent to send the private CV to the configured AI processor.';
