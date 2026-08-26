part of '../home_page.dart';

class _LanguageSelectorCard extends StatelessWidget {
  const _LanguageSelectorCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.translate_rounded, color: _green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('language'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              context.tr('languageHelp'),
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            ValueListenableBuilder<AppLanguage>(
              valueListenable: AppLanguageController.language,
              builder: (context, language, _) => SizedBox(
                width: double.infinity,
                child: SegmentedButton<AppLanguage>(
                  showSelectedIcon: false,
                  segments: AppLanguage.values
                      .map(
                        (item) => ButtonSegment<AppLanguage>(
                          value: item,
                          label: Text(item.shortLabel),
                          tooltip: item.label,
                        ),
                      )
                      .toList(),
                  selected: {language},
                  onSelectionChanged: (selection) async {
                    await AppLanguageController.setLanguage(selection.single);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountActions extends StatelessWidget {
  const _AccountActions({
    required this.onSignIn,
    required this.onSignOut,
    required this.onDeleteAccount,
    required this.onReplayTutorial,
    required this.onOpenPrivacy,
    required this.isAdmin,
    required this.onOpenAdmin,
  });

  final VoidCallback onSignIn;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;
  final VoidCallback onReplayTutorial;
  final VoidCallback onOpenPrivacy;
  final bool isAdmin;
  final VoidCallback onOpenAdmin;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('accountPrivacy'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              user?.email ?? context.tr('guestNavigation'),
              style: const TextStyle(color: _muted, fontSize: 10),
            ),
            const SizedBox(height: 14),
            if (isAdmin) ...[
              FilledButton.tonalIcon(
                onPressed: onOpenAdmin,
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                label: Text(context.tr('moderateJobs')),
              ),
              const SizedBox(height: 8),
            ],
            if (user == null)
              FilledButton.icon(
                onPressed: onSignIn,
                icon: const Icon(Icons.login_rounded, size: 17),
                label: Text(context.tr('signInSync')),
              )
            else
              OutlinedButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded, size: 17),
                label: Text(context.tr('signOut')),
              ),
            TextButton.icon(
              onPressed: onOpenPrivacy,
              icon: const Icon(Icons.privacy_tip_outlined, size: 17),
              label: Text(context.tr('privacyPolicy')),
            ),
            TextButton.icon(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'Werkly',
                applicationVersion: '1.0.0',
                applicationLegalese: context.tr('legalAttribution'),
              ),
              icon: const Icon(Icons.description_outlined, size: 17),
              label: Text(context.tr('legal')),
            ),
            TextButton.icon(
              onPressed: onReplayTutorial,
              icon: const Icon(Icons.school_outlined, size: 17),
              label: Text(context.tr('replayTutorial')),
            ),
            if (user != null)
              TextButton.icon(
                onPressed: onDeleteAccount,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 17),
                label: Text(context.tr('deleteAccount')),
              ),
          ],
        ),
      ),
    );
  }
}

