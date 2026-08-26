part of '../home_page.dart';

class _ApplicationPrepSheet extends StatefulWidget {
  const _ApplicationPrepSheet({
    required this.job,
    required this.profile,
    required this.initialStatus,
    required this.onGenerateLetter,
    required this.onExportKit,
    required this.onSetReminder,
    required this.onOpenOriginal,
    required this.onEditProfile,
    required this.onStatusChanged,
  });

  final Job job;
  final UserProfileData profile;
  final String initialStatus;
  final Future<void> Function() onGenerateLetter;
  final Future<void> Function() onExportKit;
  final Future<bool> Function() onSetReminder;
  final Future<void> Function() onOpenOriginal;
  final Future<void> Function() onEditProfile;
  final Future<void> Function(String status) onStatusChanged;

  @override
  State<_ApplicationPrepSheet> createState() => _ApplicationPrepSheetState();
}

class _ApplicationPrepSheetState extends State<_ApplicationPrepSheet> {
  late String _status = widget.initialStatus;
  bool _letterPrepared = false;
  bool _kitPrepared = false;
  bool _keywordsCopied = false;
  bool _offerOpened = false;
  bool _reminderSet = false;
  bool _savingStatus = false;

  bool get _profileReady =>
      widget.profile.skills.isNotEmpty &&
      widget.profile.professionalSummary.trim().isNotEmpty;

  bool get _sent => _status != 'preparing';

  double get _progress {
    var completed = 0;
    if (_profileReady) completed++;
    if (_keywordsCopied ||
        missingJobSkills(widget.job, widget.profile.skills).isEmpty) {
      completed++;
    }
    if (_letterPrepared || _kitPrepared) completed++;
    if (_sent) completed++;
    return completed / 4;
  }

  Future<void> _copyKeywords() async {
    final keywords = widget.job.tags.join(', ');
    if (keywords.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: keywords));
    if (!mounted) return;
    setState(() => _keywordsCopied = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr('keywordsCopied'))));
  }

  Future<void> _generateLetter() async {
    await widget.onGenerateLetter();
    if (mounted) setState(() => _letterPrepared = true);
  }

  Future<void> _exportKit() async {
    await widget.onExportKit();
    if (mounted) {
      setState(() {
        _kitPrepared = true;
        _letterPrepared = true;
      });
    }
  }

  Future<void> _openOffer() async {
    await widget.onOpenOriginal();
    if (mounted) setState(() => _offerOpened = true);
  }

  Future<void> _setReminder() async {
    final saved = await widget.onSetReminder();
    if (saved && mounted) setState(() => _reminderSet = true);
  }

  Future<void> _changeStatus(String? status) async {
    if (status == null || status == _status || _savingStatus) return;
    final previous = _status;
    setState(() {
      _status = status;
      _savingStatus = true;
    });
    try {
      await widget.onStatusChanged(status);
    } catch (_) {
      if (mounted) setState(() => _status = previous);
    } finally {
      if (mounted) setState(() => _savingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matched = matchedJobSkills(widget.job, widget.profile.skills);
    final missing = missingJobSkills(widget.job, widget.profile.skills);
    final progressPercent = (_progress * 100).round();
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final statusLabels = <String, String>{
      'preparing': context.tr('statusPreparing'),
      'applied': context.tr('statusApplied'),
      'interview': context.tr('statusInterviewObtained'),
      'offer': context.tr('statusOffer'),
      'rejected': context.tr('statusRejectedFeminine'),
    };
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: math.min(MediaQuery.sizeOf(context).width, 760),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .94,
        ),
        padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + viewPadding.bottom),
        decoration: const BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const _SheetHandle(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CompanyLogo(
                        company: widget.job.company,
                        color: widget.job.color,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('applicationKit'),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${widget.job.title} · ${widget.job.company}',
                              style: const TextStyle(color: _muted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: context.tr('close'),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.tr('readyToSend'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              '$progressPercent%',
                              style: const TextStyle(
                                color: _green,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: _progress,
                          minHeight: 8,
                          color: _green,
                          backgroundColor: const Color(0xFFE5EBE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 14),
                        _PrepChecklistRow(
                          done: _profileReady,
                          label: context.tr('profileSummaryReady'),
                        ),
                        _PrepChecklistRow(
                          done: _keywordsCopied || missing.isEmpty,
                          label: context.tr('cvKeywordsReady'),
                        ),
                        _PrepChecklistRow(
                          done: _letterPrepared || _kitPrepared,
                          label: context.tr('pdfLetterReady'),
                        ),
                        _PrepChecklistRow(
                          done: _sent,
                          label: context.tr('applicationTracked'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PrepSkillBlock(
                    title: context.tr('strengthsForRole'),
                    emptyText: widget.profile.skills.isEmpty
                        ? context.tr('addSkillsAnalysis')
                        : context.tr('noExactMatch'),
                    skills: matched,
                    positive: true,
                  ),
                  const SizedBox(height: 12),
                  _PrepSkillBlock(
                    title: context.tr('keywordsToStrengthen'),
                    emptyText: context.tr('allKeywordsCovered'),
                    skills: missing,
                    positive: false,
                  ),
                  const SizedBox(height: 18),
                  if (!_profileReady)
                    OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await widget.onEditProfile();
                      },
                      icon: const Icon(Icons.person_outline_rounded),
                      label: Text(context.tr('completeMyProfile')),
                    ),
                  if (!_profileReady) const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: widget.job.tags.isEmpty ? null : _copyKeywords,
                    icon: Icon(
                      _keywordsCopied
                          ? Icons.check_rounded
                          : Icons.content_copy_rounded,
                    ),
                    label: Text(
                      _keywordsCopied
                          ? context.tr('keywordsCopied')
                          : context.tr('copyKeywords'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _exportKit,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(
                      _kitPrepared
                          ? context.tr('reopenPdfKit')
                          : context.tr('createPdfKit'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _generateLetter,
                    icon: const Icon(Icons.edit_note_rounded),
                    label: Text(
                      _letterPrepared
                          ? context.tr('reopenLetter')
                          : context.tr('viewLetterOnly'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: widget.job.sourceUrl.isEmpty ? null : _openOffer,
                    icon: Icon(
                      _offerOpened
                          ? Icons.check_rounded
                          : Icons.open_in_new_rounded,
                    ),
                    label: Text(
                      _offerOpened
                          ? context.tr('originalOpened')
                          : context.tr('openOriginal'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _setReminder,
                    icon: Icon(
                      _reminderSet
                          ? Icons.notifications_active_rounded
                          : Icons.add_alarm_rounded,
                    ),
                    label: Text(
                      _reminderSet
                          ? context.tr('editReminder')
                          : context.tr('addReminder'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: InputDecoration(
                      labelText: context.tr('applicationStatus'),
                      prefixIcon: const Icon(Icons.track_changes_rounded),
                    ),
                    items: statusLabels.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: _savingStatus ? null : _changeStatus,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    Supabase.instance.client.auth.currentUser == null
                        ? context.tr('guestProgressSaved')
                        : context.tr('accountProgressSynced'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _muted, fontSize: 11),
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

class _PrepChecklistRow extends StatelessWidget {
  const _PrepChecklistRow({required this.done, required this.label});

  final bool done;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 18,
            color: done ? _green : _muted,
          ),
          const SizedBox(width: 9),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

class _PrepSkillBlock extends StatelessWidget {
  const _PrepSkillBlock({
    required this.title,
    required this.emptyText,
    required this.skills,
    required this.positive,
  });

  final String title;
  final String emptyText;
  final List<String> skills;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? _green : const Color(0xFFA86416);
    final background = positive
        ? const Color(0xFFF0F6F2)
        : const Color(0xFFFFF4E4);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (skills.isEmpty)
            Text(emptyText, style: const TextStyle(color: _muted, fontSize: 12))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final skill in skills)
                  Chip(
                    avatar: Icon(
                      positive ? Icons.check_rounded : Icons.add_rounded,
                      size: 16,
                      color: color,
                    ),
                    label: Text(skill),
                    backgroundColor: Colors.white.withValues(alpha: .85),
                    side: BorderSide(color: color.withValues(alpha: .18)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

