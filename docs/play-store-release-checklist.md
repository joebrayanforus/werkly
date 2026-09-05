# Werkly Play Store release checklist

## Blocking items

- [ ] Google developer identity approved.
- [ ] Android device verification completed in the Play Console mobile app.
- [ ] Custom SMTP enabled and confirmation/password-reset emails tested. Personalized, localized templates are written and pushed (`supabase/email-templates/`, commit `dc55b53`) — still need to be pasted into Supabase → Authentication → Emails → Templates and verified with a real test send.
- [x] Google Sign-In fixed and verified end-to-end on the web build: `redirectTo` was hardcoded to the domain root instead of preserving the `/werkly/` sub-path (`lib/services/auth_redirects.dart`, commit `d58bc34`), and `https://joebrayanforus.github.io/werkly/**` was missing from Supabase's Redirect URLs allowlist. Both fixed; a fresh sign-in now lands back in the app instead of the fallback confirmation page. Google Cloud OAuth consent branding also configured: app name "Werkly", logo, support email, homepage/privacy/terms links, both `supabase.co` and `github.io` domains authorized. Note: the "Sign in to X" line on Google's consent screen will still show the Supabase domain rather than "Werkly" — that requires a custom domain for Supabase Auth, which isn't in place.
- [x] Stable HTTPS hosting deployed for the web app, privacy policy, terms of service and account-deletion page. Live at:
  - App: https://joebrayanforus.github.io/werkly/
  - Privacy policy: https://joebrayanforus.github.io/werkly/privacy.html
  - Terms of service: https://joebrayanforus.github.io/werkly/terms.html
  - Account deletion: https://joebrayanforus.github.io/werkly/account-deletion.html
- [x] Legal controller name, address and support email added to the privacy policy.
- [x] Privacy policy is readable from registration and from the in-app profile.
- [x] Generated AI answers have an in-app reporting flow backed by an RLS-protected report table.
- [ ] Data safety form reviewed and submitted.

## Store listing

- [ ] Create app with default language German and package `de.werkly.app`.
- [ ] Paste the localized texts from `docs/play-store-listing.md`.
- [x] Prepare the 512 × 512 icon at `assets/store/app-icon-512.png`.
- [x] Prepare the 1024 × 500 feature graphic at `assets/store/feature-graphic-1024x500.png`.
- [x] Upload at least two accurate phone screenshots; four are prepared at `assets/store/screenshots/` (1080 × 2400, captured on a Pixel 8 emulator running the debug build, 5 September 2026): `01-preferences.png`, `02-matching-explanation.png`, `03-map-commute.png`, `04-application-tracking.png`.
- [ ] Select the appropriate app category and provide support contact details. Recommended: category **Business** (Play has no dedicated "Jobs" category), support email `joeoumbe@gmail.com`, website `https://joebrayanforus.github.io/werkly/`.
- [x] Add the public privacy policy URL: https://joebrayanforus.github.io/werkly/privacy.html

## App content

- [ ] Complete Data safety using `docs/play-store-data-safety.md` as the draft.
- [x] Provide the public external account-deletion URL: https://joebrayanforus.github.io/werkly/account-deletion.html
- [ ] Complete content rating questionnaire.
- [ ] Complete target audience and content declarations.
- [ ] Complete ads declaration: the app contains no ads.
- [ ] Provide review instructions: guest mode is available; include a test account only if Google needs to inspect synchronized or AI features.

## Release and testing

- [x] Target Android 16 / API 36 (Google Play requirement from 31 August 2026).
- [x] Declare the Android 13+ notification permission; the app still asks users before sending alerts.
- [x] Build and verify the signed `1.0.0+3` Android App Bundle locally (5 September 2026, SHA-256 `5AFE5C82F42A8B8A7AA89DD008DBAD3C47F2D66FA113F40F855042618DCAFBC2`).
- [ ] Upload the new `build/app/outputs/bundle/release/app-release.aab` to **Internal testing** after the local release build succeeds.
- [ ] Run internal testing on at least one real Android device.
- [ ] Test signup, confirmation, password recovery, CV upload/analysis, city location, map, commute, PDF generation, notifications and deletion.
- [ ] Check Android vitals/pre-launch report and resolve crashes or policy warnings.
- [ ] For a new personal account, run the required closed test with at least 12 opted-in testers for 14 continuous days.
- [ ] Apply for production access after the closed test.

Official testing requirements: https://support.google.com/googleplay/android-developer/answer/14151465
