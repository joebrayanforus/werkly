# Werkly authentication emails

The branded English-first templates are stored in `supabase/email-templates`.

Supabase projects created on the Free plan after 3 June 2026 cannot edit the default authentication templates while they use the shared Supabase mail server. A custom SMTP provider must be enabled first.

## Remaining dashboard configuration

1. Create a free SMTP account with a provider such as Resend or Brevo and verify the sender address or domain.
2. Open Supabase **Authentication > Emails > SMTP Settings** and enable custom SMTP.
3. Enter the provider host, port, username, password, sender address and sender name `Werkly`.
4. Open **Authentication > Emails > Templates**.
5. Copy `confirm-signup.html` and its subject into the confirmation template.
6. Copy `reset-password.html` and its subject into the password recovery template.
7. Send one confirmation and one password reset email to a test account before release.

Never commit SMTP passwords or provider API keys to this repository.
