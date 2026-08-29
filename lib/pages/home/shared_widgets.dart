part of '../home_page.dart';

class _ScoreBubble extends StatelessWidget {
  const _ScoreBubble({
    required this.score,
    this.small = false,
    this.unscored = false,
  });
  final int score;
  final bool small;
  final bool unscored;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: small ? 46 : 54,
      height: small ? 46 : 54,
      decoration: BoxDecoration(
        color: unscored
            ? const Color(0xFFF0F2EF)
            : score >= 90
            ? _mint
            : const Color(0xFFFFF1DD),
        shape: BoxShape.circle,
        border: Border.all(
          color: unscored
              ? _line
              : score >= 90
              ? const Color(0xFFBDD8C8)
              : const Color(0xFFF1D1A6),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        unscored ? '—' : '$score%',
        style: TextStyle(
          color: unscored
              ? _muted
              : score >= 90
              ? _green
              : const Color(0xFF9C5E19),
          fontWeight: FontWeight.w900,
          fontSize: small ? 12 : 14,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.action,
    this.onTap,
  });
  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onTap,
            child: Text(
              action!,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.saved,
    required this.onTap,
    required this.onSave,
    this.compact = false,
    this.selected = false,
  });

  final Job job;
  final bool saved;
  final VoidCallback onTap;
  final VoidCallback onSave;
  final bool compact;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${job.title}, ${job.company}',
      child: Card(
        margin: EdgeInsets.zero,
        color: selected ? const Color(0xFFF5FAF7) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? _green : _line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(compact ? 16 : 19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CompanyLogo(
                      company: job.company,
                      color: job.color,
                      small: compact,
                    ),
                    const Spacer(),
                    _ScoreBubble(
                      score: job.match,
                      small: true,
                      unscored: !job.compatibility.scored,
                    ),
                  ],
                ),
                SizedBox(height: compact ? 12 : 16),
                Text(
                  job.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 14 : 16,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${job.company}  ·  ${_localizedPosted(context, job)}',
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: _muted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.directions_transit_rounded,
                      size: 15,
                      color: _muted,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        job.commute,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.payments_outlined,
                      size: 15,
                      color: _muted,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        job.salary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: job.tags
                            .take(2)
                            .map((tag) => _Tag(label: tag))
                            .toList(),
                      ),
                    ),
                    IconButton(
                      tooltip: saved
                          ? context.tr('removeFavorite')
                          : context.tr('addFavorite'),
                      onPressed: onSave,
                      icon: Icon(
                        saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: saved ? _green : _muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  const _CompanyLogo({
    required this.company,
    required this.color,
    this.small = false,
  });
  final String company;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 38.0 : 44.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        company.trim().isEmpty ? '?' : company.trim().substring(0, 1),
        style: TextStyle(
          color: color,
          fontSize: small ? 16 : 19,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF55635D),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFCDD3CE),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
