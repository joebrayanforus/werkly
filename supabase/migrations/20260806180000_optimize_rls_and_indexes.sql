-- Keep user-scoped queries fast as the catalog and user base grow.
create index if not exists favorites_job_id_idx
  on public.favorites (job_id);

create index if not exists applications_job_id_idx
  on public.applications (job_id);

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select using ((select auth.uid()) = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

drop policy if exists "favorites_manage_own" on public.favorites;
create policy "favorites_manage_own" on public.favorites
  for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "applications_manage_own" on public.applications;
create policy "applications_manage_own" on public.applications
  for all
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
