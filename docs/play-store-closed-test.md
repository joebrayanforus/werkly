# Werkly closed-test plan

This plan is for a new personal Google Play developer account that must complete a closed test before production access.

## Before inviting testers

- Upload the signed app bundle to a closed-testing release.
- Add a support email and the tester feedback channel in Play Console.
- Create a Google Group or an email list containing at least 12 dependable Android testers.
- Add the privacy-policy URL and account-deletion URL.
- Publish the closed-testing release and copy the Android opt-in link.

## Message to send to testers

> Thank you for testing Werkly. Open the opt-in link with the Google account used on your Android phone, select **Become a tester**, then install Werkly from Google Play. Please remain opted in for the full 14-day test. Try the checklist below on several days and send screenshots or a short description if something does not work. Do not upload a real CV containing sensitive information; a test CV is enough.

## Tester checklist

1. Open the app, choose a language and complete or skip the tutorial.
2. Search in guest mode and set city, field and working-time preferences.
3. Open a vacancy and check the compatibility explanation and original-source link.
4. Use the map, distance and commute estimate.
5. Save a favorite and move a vacancy through the application tracker.
6. Create a disposable account, confirm its email and sign in again.
7. Upload a non-sensitive test CV and, after reading the disclosure, test CV analysis.
8. Generate an application kit/PDF and test interview preparation.
9. Ask Nia a generated question and report one test answer from inside the conversation.
10. Test password recovery from the same Android device.
11. Delete the disposable account and confirm that it can no longer sign in.

## Feedback to record

For each report, collect only:

- Android model and Android version.
- Werkly app version.
- Feature being tested.
- Expected and actual result.
- Reproduction steps.
- Screenshot without personal data.
- Severity: blocking, important or cosmetic.

## During the 14 days

- Keep at least 12 testers continuously opted in; use a few additional testers as a buffer.
- Review crashes and Android vitals in Play Console.
- Fix blocking defects in a new closed-test release without ending the test track.
- Keep notes on feedback received and improvements made; Google asks about testing engagement when production access is requested.

Official requirement: https://support.google.com/googleplay/android-developer/answer/14151465
