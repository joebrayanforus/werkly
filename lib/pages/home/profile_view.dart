part of '../home_page.dart';

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.profile,
    required this.jobs,
    required this.onUploadCv,
    required this.onAnalyzeCv,
    required this.onViewCv,
    required this.isAnalyzingCv,
    required this.onEditProfile,
    required this.onEditPreferences,
    required this.pushSubscribed,
    required this.onTogglePush,
    required this.onOptimizeCv,
    required this.onSignIn,
    required this.onSignOut,
    required this.onDeleteAccount,
    required this.onReplayTutorial,
    required this.onOpenPrivacy,
    required this.isAdmin,
    required this.onOpenAdmin,
  });

  final UserProfileData profile;
  final List<Job> jobs;
  final VoidCallback onUploadCv;
  final VoidCallback onAnalyzeCv;
  final VoidCallback onViewCv;
  final bool isAnalyzingCv;
  final VoidCallback onEditProfile;
  final VoidCallback onEditPreferences;
  final bool pushSubscribed;
  final VoidCallback onTogglePush;
  final VoidCallback onOptimizeCv;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;
  final VoidCallback onReplayTutorial;
  final VoidCallback onOpenPrivacy;
  final bool isAdmin;
  final VoidCallback onOpenAdmin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 960;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 24, wide ? 28 : 16, 100),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    title: context.tr('professionalProfile'),
                    subtitle: context.tr('professionalProfileSubtitle'),
                  ),
                  const SizedBox(height: 18),
                  if (wide) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: _ProfileSummary(
                            profile: profile,
                            jobs: jobs,
                            onUploadCv: onUploadCv,
                            onEditProfile: onEditProfile,
                            onEditPreferences: onEditPreferences,
                            pushSubscribed: pushSubscribed,
                            onTogglePush: onTogglePush,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              _CvChecklist(
                                profile: profile,
                                onOptimize: onOptimizeCv,
                              ),
                              const SizedBox(height: 14),
                              _LanguageSelectorCard(),
                              const SizedBox(height: 14),
                              _AccountActions(
                                onSignIn: onSignIn,
                                onSignOut: onSignOut,
                                onDeleteAccount: onDeleteAccount,
                                onReplayTutorial: onReplayTutorial,
                                onOpenPrivacy: onOpenPrivacy,
                                isAdmin: isAdmin,
                                onOpenAdmin: onOpenAdmin,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _CvAnalysisCard(
                      profile: profile,
                      isAnalyzing: isAnalyzingCv,
                      onAnalyze: onAnalyzeCv,
                      onView: onViewCv,
                      onUpload: onUploadCv,
                    ),
                  ] else ...[
                    _ProfileSummary(
                      profile: profile,
                      jobs: jobs,
                      onUploadCv: onUploadCv,
                      onEditProfile: onEditProfile,
                      onEditPreferences: onEditPreferences,
                      pushSubscribed: pushSubscribed,
                      onTogglePush: onTogglePush,
                    ),
                    const SizedBox(height: 16),
                    _CvAnalysisCard(
                      profile: profile,
                      isAnalyzing: isAnalyzingCv,
                      onAnalyze: onAnalyzeCv,
                      onView: onViewCv,
                      onUpload: onUploadCv,
                    ),
                    const SizedBox(height: 16),
                    _CvChecklist(profile: profile, onOptimize: onOptimizeCv),
                    const SizedBox(height: 14),
                    _LanguageSelectorCard(),
                    const SizedBox(height: 14),
                    _AccountActions(
                      onSignIn: onSignIn,
                      onSignOut: onSignOut,
                      onDeleteAccount: onDeleteAccount,
                      onReplayTutorial: onReplayTutorial,
                      onOpenPrivacy: onOpenPrivacy,
                      isAdmin: isAdmin,
                      onOpenAdmin: onOpenAdmin,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.profile,
    required this.jobs,
    required this.onUploadCv,
    required this.onEditProfile,
    required this.onEditPreferences,
    required this.pushSubscribed,
    required this.onTogglePush,
  });
  final UserProfileData profile;
  final List<Job> jobs;
  final VoidCallback onUploadCv;
  final VoidCallback onEditProfile;
  final VoidCallback onEditPreferences;
  final bool pushSubscribed;
  final VoidCallback onTogglePush;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadataName = (user?.userMetadata?['full_name'] as String?)?.trim();
    final name = !_isGuestProfileName(profile.fullName)
        ? profile.fullName.trim()
        : metadataName == null || metadataName.isEmpty
        ? (user?.email?.split('@').first ?? context.tr('guestProfileName'))
        : metadataName;
    final subtitle = [
      profile.degree,
      profile.university,
      profile.city,
    ].where((value) => value.trim().isNotEmpty).join(' · ');
    final demand = <String, int>{};
    for (final job in jobs) {
      for (final tag in job.tags) {
        demand[tag] = (demand[tag] ?? 0) + 1;
      }
    }
    final topDemand = demand.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB9D7CC),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials.isEmpty ? 'W' : initials,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle.isEmpty
                            ? context.tr('addEducationCity')
                            : subtitle,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: context.tr('editProfile'),
                  onSelected: (action) => switch (action) {
                    'profile' => onEditProfile(),
                    'preferences' => onEditPreferences(),
                    'push' => onTogglePush(),
                    _ => onUploadCv(),
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: Text(context.tr('editProfile')),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'cv',
                      child: ListTile(
                        leading: const Icon(Icons.upload_file_rounded),
                        title: Text(context.tr('addCv')),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'preferences',
                      child: ListTile(
                        leading: const Icon(Icons.tune_rounded),
                        title: Text(context.tr('editPreferences')),
                      ),
                    ),
                    if (kIsWeb)
                      PopupMenuItem(
                        value: 'push',
                        child: ListTile(
                          leading: Icon(
                            pushSubscribed
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_none_rounded,
                          ),
                          title: Text(
                            context.tr(
                              pushSubscribed
                                  ? 'disableNotifications'
                                  : 'enableNotifications',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('aiSummary'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              profile.professionalSummary.trim().isEmpty
                  ? context.tr('addSummary')
                  : profile.professionalSummary,
            ),
            const SizedBox(height: 22),
            Text(
              context.tr('detectedSkills'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (profile.skills.isEmpty)
              Text(
                context.tr('noSkillsProvided'),
                style: const TextStyle(color: _muted),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.skills
                    .map(
                      (skill) => _SkillPill(
                        label: skill,
                        level: context.tr('declared'),
                        strong: jobs.any(
                          (job) => job.tags.any(
                            (tag) => tag.toLowerCase() == skill.toLowerCase(),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 24),
            Text(
              context.tr('marketDemand'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            if (topDemand.isEmpty)
              Text(context.tr('marketTrendsEmpty'))
            else
              for (final entry in topDemand.take(3)) ...[
                _DemandBar(
                  label: entry.key,
                  value: entry.value / math.max(1, jobs.length),
                  opportunities: context.trFormat('jobCount', {
                    'count': entry.value,
                  }),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _SkillPill extends StatelessWidget {
  const _SkillPill({
    required this.label,
    required this.level,
    this.strong = false,
  });
  final String label;
  final String level;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: strong ? _mint : const Color(0xFFF1F2EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: _ink,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
          children: [
            TextSpan(text: '$label  '),
            TextSpan(
              text: level,
              style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w500,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemandBar extends StatelessWidget {
  const _DemandBar({
    required this.label,
    required this.value,
    required this.opportunities,
  });
  final String label;
  final double value;
  final String opportunities;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value,
            minHeight: 9,
            color: _orange,
            backgroundColor: const Color(0xFFF0EEE8),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 52,
          child: Text(
            opportunities,
            style: const TextStyle(color: _muted, fontSize: 9),
          ),
        ),
      ],
    );
  }
}

