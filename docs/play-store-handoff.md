# Werkly Play Store handoff

Prepared locally on 11 August 2026.

## Ready to upload

- Android package: `de.werkly.app`
- Candidate version: `1.0.0` (`versionCode 3`)
- Store icon: `assets/store/app-icon-512.png`
- Feature graphic: `assets/store/feature-graphic-1024x500.png`
- Privacy source page: `web/privacy.html`
- Account-deletion source page: `web/account-deletion.html`
- Store text: `docs/play-store-listing.md`
- Data safety draft: `docs/play-store-data-safety.md`

The signed Android App Bundle is generated at
`build/app/outputs/bundle/release/app-release.aab`. Record its SHA-256 checksum
after every final build and upload only that exact file.

## Current Android test candidate

- Version: `1.0.0` (`versionCode 3`)
- Android target: API 36
- Package: `de.werkly.app`
- Android 13+ notifications: declared and requested only when the user enables them
- Build command: `powershell -ExecutionPolicy Bypass -File tooling/build_android_release.ps1`

Latest bundle — this is the one to check on a real device, then upload to
**Internal testing** (reflects the CV versions feature, embedded-CV
application kit, persisted application checklist and the two September UI
fixes):

- Built: 5 September 2026 at 18:10 Europe/Berlin
- Size: 67,765,316 bytes (64.6 MB)
- SHA-256: `5AFE5C82F42A8B8A7AA89DD008DBAD3C47F2D66FA113F40F855042618DCAFBC2`

The bundles below are historical verification records and must not be
uploaded again:

- Built: 24 August 2026 at 10:23 Europe/Berlin — Size: 63.71 MB — SHA-256:
  `18B7E582FE462CB69A9901309E8E566243BFF99EDA581415674641F01A1F74AB`
- Built: 11 August 2026 at 04:52:37 Europe/Berlin — Size: 66,601,590 bytes —
  SHA-256: `33924290D0CBDEABEC80ABC1C625505FAF5AC33B36CEE7F2A5737B59A5C7F489`
  — manifest: package `de.werkly.app`, `versionCode 2`, `versionName 1.0.0`,
  target SDK 36; JAR signature verification successful

The deployable web package is in `build/web`; it contains both
`privacy.html` and `account-deletion.html`.

## Privacy and account-deletion pages: hosting status

Pushed to the `gh-pages` branch on 5 September 2026 (commit `c30b4971`),
containing only `privacy.html` and `account-deletion.html` at the branch
root. **GitHub Pages still needs to be enabled** (repo Settings → Pages →
Source: Deploy from a branch → `gh-pages` / `(root)` → Save) — this requires
signing in as the repo owner, so it wasn't done automatically. Once enabled,
the pages resolve at:

- `https://joebrayanforus.github.io/werkly/privacy.html`
- `https://joebrayanforus.github.io/werkly/account-deletion.html`

Enter both URLs in Play Console (privacy policy field, and the
account-deletion URL in Data safety). Note: only the two static pages are
published this way, not the full Werkly web app, so the "Open Werkly" button
on the account-deletion page won't resolve yet — its written instructions
(delete via the mobile app, or email support) still work. Deploy the full
`build/web` output to the same branch if that button should also work.

## Actions that require the developer account

1. Enable GitHub Pages for the `gh-pages` branch (see above), then wait until
   Google approves the developer identity and complete Android device
   verification when requested.
2. Create the app in Play Console with default language German and package
   `de.werkly.app`.
3. Upload the store icon, feature graphic and at least two accurate phone
   screenshots captured from the final Android build.
4. Complete Data safety, content rating, target audience, ads (none), app
   access/review instructions and the account-deletion declaration, using the
   two hosted URLs above.
5. Upload the signed AAB to an internal test first. Run the smoke-test list in
   `docs/play-store-release-checklist.md` on a real Android phone.
6. For a new personal developer account, start a closed test with at least 12
   continuously opted-in testers for 14 days, then request production access.

## Review instructions draft

Werkly can be inspected without an account by choosing guest mode. Account
creation is optional. An account is required only for synchronization, private
CV storage/analysis and the generative Nia assistant. Testers should use a
non-sensitive sample CV. AI answers can be reported directly through the flag
action below each assistant response. Account deletion is available under
Profile > Account and privacy > Delete my account and data.

## Final manual checks

- Verify `Tchinda Oumbe Joe Brayan`, `Engsbachstraße 58, 57076 Siegen` and
  `joeoumbe@gmail.com` before publishing the privacy page.
- Confirm that signup confirmation and password-recovery emails arrive on a
  real device through the configured SMTP provider.
- Enable Supabase leaked-password protection before production if the project
  plan supports it.
- Check the Play pre-launch report and Android vitals before promoting the
  release.
