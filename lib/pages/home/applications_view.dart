part of '../home_page.dart';

class _ApplicationsView extends StatelessWidget {
  const _ApplicationsView({
    required this.jobs,
    required this.savedJobs,
    required this.applicationStatuses,
    required this.onOpenJob,
    required this.onStatusChanged,
  });
  final List<Job> jobs;
  final Set<int> savedJobs;
  final Map<int, String> applicationStatuses;
  final ValueChanged<Job> onOpenJob;
  final void Function(int, String?) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    List<Job> withStatus(String status) =>
        jobs.where((job) => applicationStatuses[job.id] == status).toList();
    final preparing = jobs
        .where(
          (job) =>
              applicationStatuses[job.id] == 'preparing' ||
              (savedJobs.contains(job.id) &&
                  !applicationStatuses.containsKey(job.id)),
        )
        .toList();
    final applied = withStatus('applied');
    final interviews = withStatus('interview');
    final offers = withStatus('offer');
    final activeCount = applicationStatuses.values
        .where((status) => status != 'rejected')
        .length;
    final responseCount = interviews.length + offers.length;
    final responseRate = applied.isEmpty && responseCount == 0
        ? 0
        : ((responseCount / math.max(1, applied.length + responseCount)) * 100)
              .round();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final columns = [
          (context.tr('statusPreparing'), preparing, const Color(0xFFEEE7D7)),
          (context.tr('statusApplied'), applied, const Color(0xFFDDEDE4)),
          (context.tr('statusInterview'), interviews, const Color(0xFFE6E2F1)),
          (context.tr('statusOffer'), offers, const Color(0xFFF3D8CC)),
        ];
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 25, wide ? 28 : 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                title: context.tr('trackingTitle'),
                subtitle: context.tr('trackingSubtitle'),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Metric(
                    value: '$activeCount',
                    label: context.tr('inProgress'),
                    icon: Icons.hourglass_top_rounded,
                  ),
                  _Metric(
                    value: '${interviews.length}',
                    label: context.tr('interviewsMetric'),
                    icon: Icons.forum_outlined,
                  ),
                  _Metric(
                    value: '$responseRate%',
                    label: context.tr('responseRate'),
                    icon: Icons.trending_up_rounded,
                  ),
                  _Metric(
                    value: responseCount == 0 ? '—' : '3 j',
                    label: context.tr('indicativeDelay'),
                    icon: Icons.schedule_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < columns.length; i++) ...[
                      Expanded(
                        child: _ApplicationColumn(
                          title: columns[i].$1,
                          jobs: columns[i].$2,
                          color: columns[i].$3,
                          onOpenJob: onOpenJob,
                          onStatusChanged: onStatusChanged,
                        ),
                      ),
                      if (i != columns.length - 1) const SizedBox(width: 12),
                    ],
                  ],
                )
              else
                for (final column in columns) ...[
                  _ApplicationColumn(
                    title: column.$1,
                    jobs: column.$2,
                    color: column.$3,
                    onOpenJob: onOpenJob,
                    onStatusChanged: onStatusChanged,
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: _green, size: 19),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(label, style: const TextStyle(color: _muted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApplicationColumn extends StatelessWidget {
  const _ApplicationColumn({
    required this.title,
    required this.jobs,
    required this.color,
    required this.onOpenJob,
    required this.onStatusChanged,
  });
  final String title;
  final List<Job> jobs;
  final Color color;
  final ValueChanged<Job> onOpenJob;
  final void Function(int, String?) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '${jobs.length}',
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          if (jobs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                border: Border.all(color: _line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.add_circle_outline_rounded,
                    color: _muted,
                    size: 20,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('dropJobHere'),
                    style: const TextStyle(color: _muted, fontSize: 10),
                  ),
                ],
              ),
            )
          else
            for (final job in jobs) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _CompanyLogo(
                          company: job.company,
                          color: job.color,
                          small: true,
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          tooltip: context.tr('changeStatus'),
                          icon: const Icon(
                            Icons.more_horiz_rounded,
                            color: _muted,
                            size: 18,
                          ),
                          onSelected: (status) => onStatusChanged(
                            job.id,
                            status == 'remove' ? null : status,
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'preparing',
                              child: Text(context.tr('statusPreparing')),
                            ),
                            PopupMenuItem(
                              value: 'applied',
                              child: Text(context.tr('statusApplied')),
                            ),
                            PopupMenuItem(
                              value: 'interview',
                              child: Text(context.tr('statusInterview')),
                            ),
                            PopupMenuItem(
                              value: 'offer',
                              child: Text(context.tr('statusOffer')),
                            ),
                            PopupMenuItem(
                              value: 'rejected',
                              child: Text(context.tr('statusRejected')),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'remove',
                              child: Text(context.tr('removeTracking')),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => onOpenJob(job),
                      child: Text(
                        job.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.company,
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: _muted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          title == context.tr('statusInterview')
                              ? context.tr('prepareQuestions')
                              : title == context.tr('statusOffer')
                              ? context.tr('replyCompany')
                              : title == context.tr('statusPreparing')
                              ? context.tr('completeApplication')
                              : context.tr('followUp'),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
            ],
        ],
      ),
    );
  }
}

