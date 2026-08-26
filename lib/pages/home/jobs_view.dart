part of '../home_page.dart';

class _JobsView extends StatelessWidget {
  const _JobsView({
    required this.jobs,
    required this.selectedJob,
    required this.profile,
    required this.query,
    required this.filter,
    required this.sort,
    required this.isRefreshing,
    required this.lastUpdated,
    required this.savedJobs,
    required this.appliedJobs,
    required this.onSearch,
    required this.onFilter,
    required this.onSort,
    required this.onRefresh,
    required this.onMoreFilters,
    required this.onSaveSearch,
    required this.onManageSearches,
    required this.savedSearchCount,
    required this.onOpenJob,
    required this.onApply,
    required this.onToggleSaved,
    required this.onLetter,
    required this.onInterview,
    required this.onExternalSearch,
    required this.onSubmitJob,
  });

  final List<Job> jobs;
  final Job selectedJob;
  final UserProfileData profile;
  final String query;
  final String filter;
  final JobSortOption sort;
  final bool isRefreshing;
  final DateTime? lastUpdated;
  final Set<int> savedJobs;
  final Set<int> appliedJobs;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onFilter;
  final ValueChanged<JobSortOption> onSort;
  final Future<void> Function() onRefresh;
  final VoidCallback onMoreFilters;
  final VoidCallback onSaveSearch;
  final VoidCallback onManageSearches;
  final int savedSearchCount;
  final ValueChanged<Job> onOpenJob;
  final ValueChanged<Job> onApply;
  final ValueChanged<int> onToggleSaved;
  final ValueChanged<Job> onLetter;
  final ValueChanged<Job> onInterview;
  final ValueChanged<String> onExternalSearch;
  final VoidCallback onSubmitJob;

  @override
  Widget build(BuildContext context) {
    final showDetail = usesEmbeddedJobDetails(
      pageIndex: 1,
      viewportWidth: MediaQuery.sizeOf(context).width,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final showMobileSearch = constraints.maxWidth < 760;
        final sourceCount = jobs.map((job) => job.source).toSet().length;
        final updateLabel = lastUpdated == null
            ? context.tr('syncPending')
            : context.trFormat('updatedAt', {
                'time':
                    '${lastUpdated!.hour.toString().padLeft(2, '0')}:${lastUpdated!.minute.toString().padLeft(2, '0')}',
              });
        return Padding(
          padding: EdgeInsets.fromLTRB(
            showDetail ? 28 : 16,
            22,
            showDetail ? 28 : 16,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                title: context.trFormat('jobsForYou', {'count': jobs.length}),
                subtitle: jobs.isEmpty
                    ? context.tr('changeFilters')
                    : '${context.trFormat('sourcesActive', {'count': sourceCount})} · $updateLabel',
                action: context.tr('publishJob'),
                onTap: onSubmitJob,
              ),
              if (showMobileSearch) ...[
                const SizedBox(height: 14),
                TextFormField(
                  key: const ValueKey('mobile-job-search'),
                  initialValue: query,
                  onChanged: onSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: context.tr('searchHint'),
                    prefixIcon: const Icon(Icons.search_rounded, size: 21),
                    isDense: true,
                  ),
                ),
              ],
              const SizedBox(height: 15),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final item in [
                      'Pour toi',
                      'Nouvelles',
                      'Remote',
                      'Sauvegardées',
                    ]) ...[
                      _FilterChip(
                        label: _localizedFilterLabel(context, item),
                        selected: filter == item,
                        onTap: () => onFilter(item),
                      ),
                      const SizedBox(width: 8),
                    ],
                    OutlinedButton.icon(
                      onPressed: onMoreFilters,
                      icon: const Icon(Icons.tune_rounded, size: 17),
                      label: Text(context.tr('moreFilters')),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onSaveSearch,
                      icon: const Icon(Icons.bookmark_add_outlined, size: 17),
                      label: Text(context.tr('save')),
                    ),
                    const SizedBox(width: 8),
                    if (savedSearchCount > 0) ...[
                      TextButton.icon(
                        onPressed: onManageSearches,
                        icon: const Icon(Icons.saved_search_rounded, size: 18),
                        label: Text(
                          context.trFormat('savedSearches', {
                            'count': savedSearchCount,
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _JobSortMenu(value: sort, onChanged: onSort),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: context.tr('refreshJobs'),
                      onPressed: isRefreshing ? null : onRefresh,
                      icon: isRefreshing
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _PartnerSearches(onOpen: onExternalSearch),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: jobs.isEmpty
                          ? const _EmptyJobs()
                          : RefreshIndicator(
                              onRefresh: onRefresh,
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 110),
                                itemCount: jobs.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 11),
                                itemBuilder: (context, index) => SizedBox(
                                  height: 240,
                                  child: _JobCard(
                                    job: jobs[index],
                                    saved: savedJobs.contains(jobs[index].id),
                                    selected: jobs[index].id == selectedJob.id,
                                    compact: true,
                                    onTap: () => onOpenJob(jobs[index]),
                                    onSave: () => onToggleSaved(jobs[index].id),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    if (showDetail) ...[
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 7,
                        child: _JobDetail(
                          job: selectedJob,
                          profileSkills: profile.skills,
                          applied: appliedJobs.contains(selectedJob.id),
                          onApply: () => onApply(selectedJob),
                          onLetter: () => onLetter(selectedJob),
                          onInterview: () => onInterview(selectedJob),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PartnerSearches extends StatelessWidget {
  const _PartnerSearches({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E7DE)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            context.tr('searchAlsoOn'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          for (final provider in ['LinkedIn', 'Indeed', 'StepStone'])
            ActionChip(
              avatar: const Icon(Icons.open_in_new_rounded, size: 14),
              label: Text(provider),
              onPressed: () => onOpen(provider),
              backgroundColor: Colors.white,
              side: const BorderSide(color: _line),
            ),
        ],
      ),
    );
  }
}

class _JobSortMenu extends StatelessWidget {
  const _JobSortMenu({required this.value, required this.onChanged});

  final JobSortOption value;
  final ValueChanged<JobSortOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<JobSortOption>(
      initialValue: value,
      tooltip: context.tr('sortJobs'),
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final option in JobSortOption.values)
          PopupMenuItem<JobSortOption>(
            value: option,
            child: Row(
              children: [
                Icon(
                  option == value ? Icons.check_rounded : Icons.sort_rounded,
                  size: 18,
                  color: option == value ? _green : _muted,
                ),
                const SizedBox(width: 9),
                Text(_localizedJobSortLabel(context, option)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, size: 17),
            const SizedBox(width: 7),
            Text(
              _localizedJobSortLabel(context, value),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _ink : Colors.white,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: selected ? _ink : _line),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _ink,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyJobs extends StatelessWidget {
  const _EmptyJobs();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 42, color: _muted),
          const SizedBox(height: 12),
          Text(
            context.tr('noJobsFound'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(context.tr('tryOtherSearch')),
        ],
      ),
    );
  }
}

class _JobDetail extends StatelessWidget {
  const _JobDetail({
    required this.job,
    required this.profileSkills,
    required this.applied,
    required this.onApply,
    required this.onLetter,
    required this.onInterview,
  });
  final Job job;
  final List<String> profileSkills;
  final bool applied;
  final VoidCallback onApply;
  final VoidCallback onLetter;
  final VoidCallback onInterview;

  @override
  Widget build(BuildContext context) {
    final missingKeywords = missingJobSkills(job, profileSkills);
    return Card(
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompanyLogo(company: job.company, color: job.color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${job.company} · ${job.location}',
                        style: const TextStyle(color: _muted),
                      ),
                    ],
                  ),
                ),
                _ScoreBubble(
                  score: job.match,
                  unscored: !job.compatibility.scored,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                _Fact(
                  icon: Icons.schedule_rounded,
                  label: context.tr('hoursPerWeek'),
                ),
                _Fact(icon: Icons.payments_outlined, label: job.salary),
                _Fact(
                  icon: Icons.directions_transit_rounded,
                  label: context.trFormat('fromHome', {'time': job.commute}),
                ),
                if (job.remote)
                  _Fact(
                    icon: Icons.home_work_outlined,
                    label: context.tr('hybrid'),
                  ),
              ],
            ),
            if (job.routeUrl != null) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () => launchUrl(
                  job.routeUrl!,
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.route_rounded, size: 17),
                label: Text(context.tr('realRoute')),
              ),
            ],
            const SizedBox(height: 26),
            _CompatibilityBlock(job: job),
            const SizedBox(height: 24),
            Text(
              context.tr('aboutRole'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SelectableText(job.description),
            const SizedBox(height: 18),
            Text(
              context.tr('requiredSkills'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: job.tags.map((tag) => _Tag(label: tag)).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('keywordsToStrengthen'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (missingKeywords.isEmpty)
              Text(
                context.tr('allKeywordsCovered'),
                style: const TextStyle(color: _muted),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: missingKeywords
                    .map(
                      (keyword) => Chip(
                        avatar: const Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: Color(0xFF9A5A12),
                        ),
                        label: Text(keyword),
                        backgroundColor: const Color(0xFFFFF1DD),
                        side: const BorderSide(color: Color(0xFFF2C98F)),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApply,
                    style: FilledButton.styleFrom(
                      backgroundColor: applied ? _mint : _green,
                      foregroundColor: applied ? _green : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: Icon(
                      applied
                          ? Icons.assignment_turned_in_outlined
                          : Icons.arrow_outward_rounded,
                    ),
                    label: Text(
                      applied
                          ? context.tr('continueApplication')
                          : context.tr('prepareApplication'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onLetter,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(context.tr('aiLetter')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onInterview,
                icon: const Icon(Icons.record_voice_over_outlined, size: 18),
                label: Text(context.tr('prepareInterview')),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: _Tag(
                label: _localizedSourceTrust(context, jobSourceTrust(job.source)),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: job.sourceUrl.isEmpty
                    ? null
                    : () => launchUrl(
                        Uri.parse(job.sourceUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: Text(
                  '${context.trFormat('originalJobOn', {'source': job.source})} · ${_localizedPosted(context, job)}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompatibilityBlock extends StatelessWidget {
  const _CompatibilityBlock({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    final result = job.compatibility;
    if (!result.scored) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8F5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.person_search_rounded, color: _green, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tr('scoreNeedsProfile'),
                style: const TextStyle(fontSize: 11, height: 1.45),
              ),
            ),
          ],
        ),
      );
    }
    final rows = <(String, double, String)>[
      if (result.evaluates('skills'))
        (
          context.tr('criterionSkills'),
          result.skills / 100,
          '${result.skills}%',
        ),
      if (result.evaluates('relevance'))
        (
          context.tr('criterionRelevance'),
          result.relevance / 100,
          '${result.relevance}%',
        ),
      if (result.evaluates('work'))
        (
          context.tr('criterionWork'),
          result.workConditions / 100,
          '${result.workConditions}%',
        ),
      if (result.evaluates('language'))
        (
          context.tr('criterionGerman'),
          result.language / 100,
          '${result.language}%',
        ),
      if (result.evaluates('education'))
        (
          context.tr('criterionEducation'),
          result.education / 100,
          '${result.education}%',
        ),
      if (result.evaluates('experience'))
        (
          context.tr('criterionExperience'),
          result.experience / 100,
          '${result.experience}%',
        ),
      if (result.evaluates('compensation'))
        (
          context.tr('criterionSalary'),
          result.compensation / 100,
          '${result.compensation}%',
        ),
      if (result.evaluates('distance'))
        (
          context.tr('criterionDistance'),
          result.distance / 100,
          '${result.distance}%',
        ),
      if (result.evaluates('freshness'))
        (
          context.tr('criterionFreshness'),
          result.freshness / 100,
          '${result.freshness}%',
        ),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: _green, size: 18),
              const SizedBox(width: 8),
              Text(
                context.tr('whyMatch'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final row in rows) ...[
            Row(
              children: [
                SizedBox(
                  width: 145,
                  child: Text(
                    row.$1,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: row.$2,
                    minHeight: 6,
                    color: _green,
                    backgroundColor: const Color(0xFFDCE6DF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 48,
                  child: Text(
                    row.$3,
                    style: const TextStyle(
                      fontSize: 10,
                      color: _green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (row != rows.last) const SizedBox(height: 11),
          ],
          const SizedBox(height: 16),
          Text(
            context.trFormat('scoreReliability', {'score': result.confidence}),
            style: const TextStyle(color: _muted, fontSize: 10),
          ),
          if (result.matchedSkills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              context.trFormat('matchesLabel', {
                'items': result.matchedSkills.join(', '),
              }),
              style: const TextStyle(
                color: _green,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (result.missingSkills.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              context.trFormat('developLabel', {
                'items': result.missingSkills.take(5).join(', '),
              }),
              style: const TextStyle(color: _muted, fontSize: 10),
            ),
          ],
          if (result.languageDetail.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              context.trFormat('languageLabel', {
                'value': result.languageDetail,
              }),
              style: const TextStyle(color: _muted, fontSize: 10),
            ),
          ],
          if (result.reasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final reason in result.reasons.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '✓ $reason',
                  style: const TextStyle(color: _green, fontSize: 10),
                ),
              ),
          ],
          if (result.cautions.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final caution in result.cautions.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  context.trFormat('verifyLabel', {'value': caution}),
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _muted),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _JobDetailSheet extends StatelessWidget {
  const _JobDetailSheet({
    required this.job,
    required this.profileSkills,
    required this.applied,
    required this.onApply,
    required this.onLetter,
    required this.onInterview,
  });
  final Job job;
  final List<String> profileSkills;
  final bool applied;
  final VoidCallback onApply;
  final VoidCallback onLetter;
  final VoidCallback onInterview;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * .88,
      decoration: const BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        children: [
          const _SheetHandle(),
          Expanded(
            child: _JobDetail(
              job: job,
              profileSkills: profileSkills,
              applied: applied,
              onApply: onApply,
              onLetter: onLetter,
              onInterview: onInterview,
            ),
          ),
        ],
      ),
    );
  }
}

