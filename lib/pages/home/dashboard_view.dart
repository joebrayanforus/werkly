part of '../home_page.dart';

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    required this.jobs,
    required this.allJobs,
    required this.profile,
    required this.firstName,
    required this.savedJobs,
    required this.onOpenJobs,
    required this.onOpenMap,
    required this.onOpenJob,
    required this.onToggleSaved,
  });

  final List<Job> jobs;
  final List<Job> allJobs;
  final UserProfileData profile;
  final String firstName;
  final Set<int> savedJobs;
  final VoidCallback onOpenJobs;
  final VoidCallback onOpenMap;
  final ValueChanged<Job> onOpenJob;
  final ValueChanged<int> onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1040;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 30 : 18, 26, wide ? 30 : 18, 110),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WelcomeBanner(
                    firstName: firstName,
                    newJobs: allJobs.where((job) {
                      final postedAt = job.postedAt;
                      return postedAt != null &&
                          DateTime.now().difference(postedAt).inHours <= 24;
                    }).length,
                    onOpenJobs: onOpenJobs,
                  ),
                  const SizedBox(height: 22),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: _OpportunityMap(
                            jobs: allJobs,
                            city: profile.city,
                            radiusKm:
                                (profile.preferences['search_radius'] as num?)
                                    ?.round() ??
                                25,
                            onOpenMap: onOpenMap,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 4,
                          child: _ProfileInsightCard(
                            profile: profile,
                            jobs: allJobs,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _OpportunityMap(
                      jobs: allJobs,
                      city: profile.city,
                      radiusKm:
                          (profile.preferences['search_radius'] as num?)
                              ?.round() ??
                          25,
                      onOpenMap: onOpenMap,
                    ),
                    const SizedBox(height: 18),
                    _ProfileInsightCard(profile: profile, jobs: allJobs),
                  ],
                  const SizedBox(height: 26),
                  _SectionTitle(
                    title: context.tr('bestMatches'),
                    subtitle: context.tr('matchesSubtitle'),
                    action: context.trFormat('seeJobs', {
                      'count': allJobs.length,
                    }),
                    onTap: onOpenJobs,
                  ),
                  const SizedBox(height: 14),
                  if (constraints.maxWidth >= 920)
                    SizedBox(
                      height: 285,
                      child: Row(
                        children: [
                          for (var i = 0; i < jobs.length; i++) ...[
                            Expanded(
                              child: _JobCard(
                                job: jobs[i],
                                saved: savedJobs.contains(jobs[i].id),
                                onTap: () => onOpenJob(jobs[i]),
                                onSave: () => onToggleSaved(jobs[i].id),
                              ),
                            ),
                            if (i != jobs.length - 1) const SizedBox(width: 14),
                          ],
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 285,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: jobs.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) => SizedBox(
                          width: math.min(330, constraints.maxWidth * .82),
                          child: _JobCard(
                            job: jobs[index],
                            saved: savedJobs.contains(jobs[index].id),
                            onTap: () => onOpenJob(jobs[index]),
                            onSave: () => onToggleSaved(jobs[index].id),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({
    required this.firstName,
    required this.newJobs,
    required this.onOpenJobs,
  });
  final String firstName;
  final int newJobs;
  final VoidCallback onOpenJobs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _mint,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8DED2)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          return Flex(
            direction: compact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: compact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: compact ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        newJobs == 0
                            ? '✦  ${context.tr('jobsUpdated')}'
                            : '✦  ${context.trFormat('newJobsToday', {'count': newJobs})}',
                        style: const TextStyle(
                          color: _green,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      context.trFormat('welcome', {'name': firstName}),
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('welcomeSubtitle'),
                      style: const TextStyle(
                        color: Color(0xFF50665C),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (compact)
                const SizedBox(height: 20)
              else
                const SizedBox(width: 24),
              FilledButton.icon(
                onPressed: onOpenJobs,
                style: FilledButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                icon: const Icon(Icons.arrow_outward_rounded, size: 18),
                label: Text(context.tr('exploreMatches')),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OpportunityMap extends StatelessWidget {
  const _OpportunityMap({
    required this.jobs,
    required this.city,
    required this.radiusKm,
    required this.onOpenMap,
  });
  final List<Job> jobs;
  final String city;
  final int radiusKm;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    // Pins show each job's compatibility match, so pick the best-scoring
    // jobs rather than whatever happens to be first in the unsorted list --
    // otherwise the pins can show 0% for jobs that just haven't been ranked
    // against the profile yet.
    final ranked = [...jobs]..sort((a, b) => b.match.compareTo(a.match));
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 330,
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _MapPainter())),
            Positioned(
              left: 20,
              top: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 16),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: _green,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${city.trim().isEmpty ? context.tr('countryGermany') : city} · ${context.tr('radius')} $radiusKm km',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            if (ranked.isNotEmpty)
              Positioned(
                left: 25,
                bottom: 25,
                child: _MapPin(label: '${ranked[0].match}', hot: true),
              ),
            if (ranked.length > 1)
              Positioned(
                left: 190,
                top: 105,
                child: _MapPin(label: '${ranked[1].match}'),
              ),
            if (ranked.length > 2)
              Positioned(
                right: 70,
                top: 92,
                child: _MapPin(label: '${ranked[2].match}'),
              ),
            if (ranked.length > 3)
              Positioned(
                right: 140,
                bottom: 62,
                child: _MapPin(label: '${ranked[3].match}', hot: true),
              ),
            Positioned(
              right: 18,
              bottom: 18,
              child: FilledButton.tonalIcon(
                onPressed: onOpenMap,
                icon: const Icon(Icons.fullscreen_rounded, size: 18),
                label: Text(context.tr('openMap')),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.label, this.hot = false});
  final String label;
  final bool hot;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: hot ? 46 : 40,
      height: hot ? 46 : 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hot ? _orange : _green,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: hot ? _ink : Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFFE9EEE8), BlendMode.srcOver);
    final district = Paint()..color = const Color(0xFFDCE6DC);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .06,
          size.height * .12,
          size.width * .30,
          size.height * .45,
        ),
        const Radius.circular(28),
      ),
      district,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .59,
          size.height * .42,
          size.width * .34,
          size.height * .42,
        ),
        const Radius.circular(34),
      ),
      district,
    );

    final river = Paint()
      ..color = const Color(0xFFB7D6DF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
    final riverPath = Path()
      ..moveTo(size.width * .62, -10)
      ..cubicTo(
        size.width * .75,
        size.height * .28,
        size.width * .43,
        size.height * .55,
        size.width * .54,
        size.height + 10,
      );
    canvas.drawPath(riverPath, river);

    final road = Paint()
      ..color = Colors.white.withValues(alpha: .9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final thinRoad = Paint()
      ..color = Colors.white.withValues(alpha: .7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawLine(
      Offset(-10, size.height * .76),
      Offset(size.width + 10, size.height * .16),
      road,
    );
    canvas.drawLine(
      Offset(size.width * .20, -10),
      Offset(size.width * .72, size.height + 10),
      road,
    );
    canvas.drawLine(
      Offset(-10, size.height * .34),
      Offset(size.width + 10, size.height * .54),
      thinRoad,
    );
    canvas.drawLine(
      Offset(size.width * .36, -10),
      Offset(size.width * .18, size.height + 10),
      thinRoad,
    );
    canvas.drawLine(
      Offset(size.width * .82, -10),
      Offset(size.width * .89, size.height + 10),
      thinRoad,
    );

    final center = Offset(size.width * .46, size.height * .44);
    final heatPaint = Paint()
      ..shader = RadialGradient(
        colors: [_orange.withValues(alpha: .25), _orange.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: 85));
    canvas.drawCircle(center, 85, heatPaint);

    final labelStyle = TextStyle(
      color: _muted.withValues(alpha: .75),
      fontSize: 10,
      fontWeight: FontWeight.w700,
    );
    for (final item in <(String, Offset)>[
      ('MAXVORSTADT', Offset(size.width * .24, size.height * .36)),
      ('ALTSTADT', Offset(size.width * .49, size.height * .66)),
      ('BOGENHAUSEN', Offset(size.width * .74, size.height * .32)),
      ('SENDLING', Offset(size.width * .25, size.height * .87)),
    ]) {
      final painter = TextPainter(
        text: TextSpan(text: item.$1, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, item.$2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProfileInsightCard extends StatelessWidget {
  const _ProfileInsightCard({required this.profile, required this.jobs});

  final UserProfileData profile;
  final List<Job> jobs;

  @override
  Widget build(BuildContext context) {
    final demand = <String, int>{};
    for (final job in jobs) {
      for (final tag in job.tags) {
        demand[tag] = (demand[tag] ?? 0) + 1;
      }
    }
    final rankedDemand = demand.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final profileSkills = profile.skills.take(4).toList();
    final displayed = profileSkills.isNotEmpty
        ? profileSkills
              .map((skill) => MapEntry(skill, demand[skill] ?? 0))
              .toList()
        : rankedDemand.take(4).toList();
    final maxDemand = math.max(
      1,
      displayed.fold<int>(0, (value, item) => math.max(value, item.value)),
    );
    final education = [
      profile.degree,
      profile.university,
    ].where((value) => value.trim().isNotEmpty).join(' · ');
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('profileCardTitle'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _ScoreBubble(score: profile.profileCompletion),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              education.isEmpty ? context.tr('profileIncomplete') : education,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 22),
            Text(
              profileSkills.isEmpty
                  ? context.tr('skillsSought')
                  : context.tr('skillsPresence'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (displayed.isEmpty)
              Text(
                context.tr('noData'),
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            for (final skill in displayed) ...[
              Row(
                children: [
                  SizedBox(
                    width: 66,
                    child: Text(
                      skill.key,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: skill.value / maxDemand,
                      color: skill.value == 0 ? _orange : _green,
                      backgroundColor: const Color(0xFFEEF0EB),
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    context.trFormat('jobCount', {'count': skill.value}),
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 13),
            ],
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFFAA681B),
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      profileSkills.isEmpty
                          ? context.tr('addSkillsForScores')
                          : context.tr('scoreUsesProfile'),
                      style: const TextStyle(
                        color: Color(0xFF765127),
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

