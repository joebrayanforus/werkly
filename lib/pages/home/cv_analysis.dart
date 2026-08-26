part of '../home_page.dart';

class _CvAnalysisCard extends StatelessWidget {
  const _CvAnalysisCard({
    required this.profile,
    required this.isAnalyzing,
    required this.onAnalyze,
    required this.onView,
    required this.onUpload,
  });

  final UserProfileData profile;
  final bool isAnalyzing;
  final VoidCallback onAnalyze;
  final VoidCallback onView;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final analysis = profile.cvAnalysis;
    final skills = _analysisItems(analysis['skills']);
    final languages = _analysisItems(analysis['languages']);
    final experiences = _analysisItems(analysis['experiences']);
    final warnings = (analysis['warnings'] as List? ?? const [])
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .toList();
    final complete = profile.cvAnalysisStatus == 'complete';
    final failed = profile.cvAnalysisStatus == 'failed';
    final analyzedAt = profile.cvAnalyzedAt;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: complete ? _mint : const Color(0xFFFFF1DD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    complete
                        ? Icons.document_scanner_rounded
                        : Icons.auto_awesome_rounded,
                    color: complete ? _green : const Color(0xFF9C5E19),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('cvAnalysis'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAnalyzing
                            ? context.tr('extractingCv')
                            : complete
                            ? context.tr('cvResultsVerify')
                            : failed
                            ? context.tr('cvLastFailed')
                            : profile.cvPath == null
                            ? context.tr('cvAddPdf')
                            : context.tr('cvStored'),
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: isAnalyzing
                      ? const SizedBox(
                          key: ValueKey('cv-analyzing'),
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : FilledButton.icon(
                          key: const ValueKey('cv-action'),
                          onPressed: profile.cvPath == null
                              ? onUpload
                              : onAnalyze,
                          icon: Icon(
                            profile.cvPath == null
                                ? Icons.upload_file_rounded
                                : Icons.refresh_rounded,
                            size: 17,
                          ),
                          label: Text(
                            profile.cvPath == null
                                ? context.tr('addMyCv')
                                : complete
                                ? context.tr('reanalyze')
                                : context.tr('analyze'),
                          ),
                        ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              child: isAnalyzing
                  ? const Padding(
                      padding: EdgeInsets.only(top: 18),
                      child: _CvAnalysisProgress(),
                    )
                  : const SizedBox.shrink(),
            ),
            if (!isAnalyzing && profile.cvPath != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                  label: Text(context.tr('viewMyCv')),
                ),
              ),
            ],
            if (!isAnalyzing &&
                failed &&
                profile.cvAnalysisError.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                profile.cvAnalysisError,
                style: TextStyle(color: Colors.red.shade700, fontSize: 11),
              ),
            ],
            if (!isAnalyzing && complete) ...[
              const SizedBox(height: 20),
              Wrap(
                spacing: 24,
                runSpacing: 18,
                children: [
                  _AnalysisGroup(
                    title: '${context.tr('skills')} (${skills.length})',
                    items: skills
                        .take(8)
                        .map((item) => item['name']?.toString() ?? '')
                        .where((value) => value.isNotEmpty)
                        .toList(),
                  ),
                  _AnalysisGroup(
                    title: '${context.tr('languages')} (${languages.length})',
                    items: languages
                        .map(
                          (item) => [item['language'], item['level']]
                              .whereType<String>()
                              .where((v) => v.isNotEmpty)
                              .join(' '),
                        )
                        .where((value) => value.isNotEmpty)
                        .toList(),
                  ),
                  _AnalysisGroup(
                    title:
                        '${context.tr('experiences')} (${experiences.length})',
                    items: experiences
                        .take(4)
                        .map((item) => item['title']?.toString() ?? '')
                        .where((value) => value.isNotEmpty)
                        .toList(),
                  ),
                ],
              ),
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  context.trFormat('cvWarnings', {
                    'items': warnings.take(3).join(' · '),
                  }),
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
              if (analyzedAt != null) ...[
                const SizedBox(height: 10),
                Text(
                  context.trFormat('cvLastAnalysis', {
                    'date': MaterialLocalizations.of(
                      context,
                    ).formatShortDate(analyzedAt.toLocal()),
                  }),
                  style: const TextStyle(color: _muted, fontSize: 9),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  static List<Map<String, dynamic>> _analysisItems(Object? value) =>
      (value as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
}

class _CvAnalysisProgress extends StatefulWidget {
  const _CvAnalysisProgress();

  @override
  State<_CvAnalysisProgress> createState() => _CvAnalysisProgressState();
}

class _CvAnalysisProgressState extends State<_CvAnalysisProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = <String>[
      context.tr('cvScanPreparing'),
      context.tr('cvScanReading'),
      context.tr('cvScanSkills'),
      context.tr('cvScanProfile'),
    ];
    return Semantics(
      liveRegion: true,
      label: context.tr('extractingCv'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _green.withValues(alpha: .055),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _green.withValues(alpha: .14)),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final current = (_controller.value * steps.length)
                .floor()
                .clamp(0, steps.length - 1)
                .toInt();
            final pulse = 1 + math.sin(_controller.value * math.pi * 8) * .06;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Transform.scale(
                      scale: pulse,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: _mint,
                          shape: BoxShape.circle,
                        ),
                        child: Transform.rotate(
                          angle: _controller.value * math.pi * 2,
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: _green,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 380),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, .25),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Text(
                          steps[current],
                          key: ValueKey(current),
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const LinearProgressIndicator(
                  minHeight: 6,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  color: _green,
                  backgroundColor: Color(0xFFDDE6E0),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(
                    steps.length,
                    (index) => Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        margin: EdgeInsets.only(
                          right: index == steps.length - 1 ? 0 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: index <= current
                              ? _green
                              : _green.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  context.tr('cvScanWait'),
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AnalysisGroup extends StatelessWidget {
  const _AnalysisGroup({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 275,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              context.tr('nothingFound'),
              style: const TextStyle(color: _muted, fontSize: 10),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: items
                  .map(
                    (item) => Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(item, style: const TextStyle(fontSize: 10)),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _CvChecklist extends StatelessWidget {
  const _CvChecklist({required this.profile, required this.onOptimize});
  final UserProfileData profile;
  final VoidCallback onOptimize;

  @override
  Widget build(BuildContext context) {
    final score = profile.profileCompletion.clamp(0, 100);
    final hasSummary = profile.professionalSummary.trim().isNotEmpty;
    final hasSkills = profile.skills.isNotEmpty;
    final hasStudy =
        profile.degree.trim().isNotEmpty ||
        profile.university.trim().isNotEmpty;
    return Column(
      children: [
        Card(
          margin: EdgeInsets.zero,
          color: _ink,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: _orange,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('cvScore'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$score/100',
                      style: const TextStyle(
                        color: _orange,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 8,
                  color: _orange,
                  backgroundColor: Color(0xFF3D4844),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                const SizedBox(height: 14),
                Text(
                  score >= 80
                      ? context.tr('profileSolid')
                      : context.tr('completeProfile'),
                  style: const TextStyle(
                    color: Color(0xFFC9D1CE),
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onOptimize,
                  style: FilledButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: _ink,
                  ),
                  child: Text(context.tr('optimizeAi')),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('nextImprovements'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                _ChecklistItem(
                  done: hasSummary,
                  title: context.tr('clearProfile'),
                  detail: hasSummary
                      ? context.tr('summaryProvided')
                      : context.trFormat('potentialPoints', {'count': 20}),
                ),
                _ChecklistItem(
                  done: hasSkills,
                  title: context.tr('skillsProvided'),
                  detail: hasSkills
                      ? context.trFormat('skillCount', {
                          'count': profile.skills.length,
                        })
                      : context.trFormat('potentialPoints', {'count': 15}),
                ),
                _ChecklistItem(
                  done: hasStudy,
                  title: context.tr('educationUniversity'),
                  detail: hasStudy
                      ? context.tr('informationPresent')
                      : context.trFormat('potentialPoints', {'count': 20}),
                ),
                _ChecklistItem(
                  done: profile.skills.any(
                    (skill) => skill.toLowerCase().contains('deutsch'),
                  ),
                  title: context.tr('germanLevel'),
                  detail: context.trFormat('potentialPoints', {'count': 5}),
                ),
                _ChecklistItem(
                  done: profile.cvPath != null,
                  title: context.tr('cvAdded'),
                  detail: profile.cvPath == null
                      ? context.trFormat('potentialPoints', {'count': 10})
                      : context.tr('secureSupabaseDocument'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.done,
    required this.title,
    required this.detail,
  });
  final bool done;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: done ? _green : _orange,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(color: _muted, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

