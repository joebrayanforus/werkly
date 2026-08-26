# Google Play Data safety draft

This is a conservative draft based on the source code on 11 August 2026. The developer remains responsible for validating every answer in Play Console whenever providers or app behavior change.

## Form overview

- The app collects user data: **Yes**.
- Data is encrypted in transit: **Yes** (HTTPS/TLS).
- Users can request deletion: **Yes**, in the app. The external deletion page must be deployed and entered in Play Console before submission.
- Advertising or sale of personal data: **No**.
- Account creation: **Optional**. Search and core discovery work in guest mode.

## Data types

| Play category | Collected | Required | Purpose | Handling |
| --- | --- | --- | --- | --- |
| Personal info – name | Yes | Optional | Account management, personalization | Stored in the private Supabase profile |
| Personal info – email address | Yes | Required only for an account | Authentication, account management, security emails | Supabase Auth; transactional mail via configured SMTP provider |
| Personal info – user IDs | Yes | Required only for an account | Authentication and synchronization | Supabase Auth ID |
| Approximate location | Yes | Optional | City suggestions, job ranking and commute | Raw device position is converted locally to the nearest supported city; only the city is saved. City-centre coordinates can be sent to OSRM for routing |
| Files and docs – CV | Yes | Optional | CV analysis, professional profile and matching | Private Supabase Storage; sent to Google Gemini only after explicit CV-analysis consent |
| App activity – app interactions | Yes | Optional | Favorites, application tracking and personalization | Synced to Supabase for signed-in users; guest data remains on device |
| Other user-generated content | Yes | Optional | AI questions, AI-answer reports, application preparation and employer vacancy submissions | AI context can be sent to Gemini after consent; reported answers/reasons and employer contact data are stored in Supabase for moderation |

## Data that stays on the device

- Raw device location after choosing the nearest city.
- Guest favorites and application statuses.
- Saved searches, commute cache and local notification schedules.
- Local assistant state when generative AI is not used.

## Sharing declaration – conservative choice

Declare the following as shared unless a legal review confirms that the applicable Google Play service-provider exception covers the transfer:

- **Files and docs** with Google Gemini when the user requests CV analysis.
- **Other user-generated content and professional profile context** with Google Gemini when the user requests a generated answer.
- **Approximate location/city-centre route coordinates** with the public OSRM routing service.

Supabase and the configured SMTP provider process data to provide Werkly's infrastructure and authentication email delivery. They are not used for advertising in the app.

## Collection properties

- Name/profile fields: optional and user provided.
- Email/user ID: required only if the user creates an account.
- Location: optional and requested in context.
- CV and AI content: optional, user initiated and protected by an explicit disclosure/consent step.
- Favorites and application tracking: optional.

## Security and deletion evidence

- RLS restricts profiles, favorites and applications to their owner.
- The CV bucket is private and scoped to the authenticated user's folder.
- The in-app delete action invokes `delete-account`, removes the private CV and deletes the Auth user. Foreign-key cascades remove the profile, favorites, applications, AI quota events and employer submissions.
- AI-answer reports accept inserts only from an authenticated owner under RLS. App users cannot read, modify or delete report records; account deletion removes their reports by cascade.
- No advertising or analytics SDK is included in `pubspec.yaml`.

## Before submitting the form

1. Deploy `web/privacy.html` and `web/account-deletion.html` to stable HTTPS URLs.
2. Verify that the legal controller name, postal address and support email in the privacy page are correct before deployment.
3. Confirm the Gemini account/terms and whether Google Play's service-provider exception applies.
4. Test account deletion with a disposable account and verify removal in Supabase.
5. Keep this declaration synchronized with the public privacy policy.

Official guidance: https://support.google.com/googleplay/android-developer/answer/10787469
