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
- Built: 24 August 2026 at 10:23 Europe/Berlin
- Size: 63.71 MB
- SHA-256: `18B7E582FE462CB69A9901309E8E566243BFF99EDA581415674641F01A1F74AB`

The `versionCode 3` bundle must be built after these final changes, checked on a
real device, then uploaded to the **Internal testing** track. The prior bundle
below remains a historical verification record and must not be uploaded again.

Previously verified bundle:

- Built: 11 August 2026 at 04:52:37 Europe/Berlin
- Size: 66,601,590 bytes
- SHA-256: `33924290D0CBDEABEC80ABC1C625505FAF5AC33B36CEE7F2A5737B59A5C7F489`
- Manifest: package `de.werkly.app`, `versionCode 2`, `versionName 1.0.0`,
  target SDK 36
- JAR signature verification: successful

The deployable web package is in `build/web`; it contains both
`privacy.html` and `account-deletion.html`.

## Actions that require the developer account

1. Wait until Google approves the developer identity and complete Android
   device verification when requested.
2. Deploy the Flutter web build together with `privacy.html` and
   `account-deletion.html` to stable public HTTPS URLs. Enter those two URLs in
   Play Console.
3. Create the app in Play Console with default language German and package
   `de.werkly.app`.
4. Upload the store icon, feature graphic and at least two accurate phone
   screenshots captured from the final Android build.
5. Complete Data safety, content rating, target audience, ads (none), app
   access/review instructions and the account-deletion declaration.
6. Upload the signed AAB to an internal test first. Run the smoke-test list in
   `docs/play-store-release-checklist.md` on a real Android phone.
7. For a new personal developer account, start a closed test with at least 12
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
