-- sync-free-jobs already fingerprints every job by normalized title+company+city
-- and prefers higher-priority sources (direct employer feeds > Bundesagentur für
-- Arbeit > Arbeitnow > Adzuna) when the same job appears from more than one
-- source, but that dedup map was rebuilt empty on every invocation. If a
-- higher-priority source was briefly unreachable on one run, a lower-priority
-- copy got imported, and the higher-priority source's copy on a later run
-- created a genuine second row instead of being caught by the in-run dedup.
--
-- Storing the fingerprint lets the function seed that map from the database
-- (existing active rows) instead of starting empty, so dedup decisions persist
-- across runs, not just within one.
alter table public.jobs
  add column if not exists fingerprint text;

create index if not exists jobs_fingerprint_active_idx
  on public.jobs (fingerprint)
  where active = true;
