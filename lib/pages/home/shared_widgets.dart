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

// Owns its TextEditingControllers via normal StatefulWidget lifecycle
// (created in initState, disposed in dispose) rather than the caller
// creating them and disposing them right after showDialog's Future
// resolves. That pattern races the dialog route's own exit transition --
// pressing the hardware back button can pop the route and let the caller's
// code run before the AlertDialog's last frame is actually torn down,
// disposing a controller a still-live TextField then tries to read from.
class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.profile});
  final UserProfileData profile;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _name;
  late final TextEditingController _university;
  late final TextEditingController _degree;
  late final TextEditingController _city;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _summary;
  late final TextEditingController _skills;
  late bool _prefersRemote;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.fullName);
    _university = TextEditingController(text: widget.profile.university);
    _degree = TextEditingController(text: widget.profile.degree);
    _city = TextEditingController(text: widget.profile.city);
    _address = TextEditingController(text: widget.profile.address);
    _phone = TextEditingController(text: widget.profile.phone);
    _summary = TextEditingController(text: widget.profile.professionalSummary);
    _skills = TextEditingController(text: widget.profile.skills.join(', '));
    _prefersRemote = widget.profile.preferences['remote'] == true;
  }

  @override
  void dispose() {
    _name.dispose();
    _university.dispose();
    _degree.dispose();
    _city.dispose();
    _address.dispose();
    _phone.dispose();
    _summary.dispose();
    _skills.dispose();
    super.dispose();
  }

  void _save() {
    final parsedSkills = _skills.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    var completion = 20;
    if (_name.text.trim().isNotEmpty) completion += 10;
    if (_university.text.trim().isNotEmpty) completion += 10;
    if (_degree.text.trim().isNotEmpty) completion += 10;
    if (_city.text.trim().isNotEmpty) completion += 5;
    if (_address.text.trim().isNotEmpty) completion += 5;
    if (_phone.text.trim().isNotEmpty) completion += 5;
    if (_summary.text.trim().isNotEmpty) completion += 20;
    if (parsedSkills.isNotEmpty) completion += 15;
    if (widget.profile.cvPath != null) completion += 10;
    Navigator.pop(
      context,
      widget.profile.copyWith(
        fullName: _name.text,
        university: _university.text,
        degree: _degree.text,
        city: _city.text,
        phone: _phone.text,
        address: _address.text,
        professionalSummary: _summary.text,
        skills: parsedSkills,
        preferences: {...widget.profile.preferences, 'remote': _prefersRemote},
        profileCompletion: completion.clamp(0, 100),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('editProfile')),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: InputDecoration(labelText: context.tr('fullName')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _university,
                decoration: InputDecoration(
                  labelText: context.tr('university'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _degree,
                decoration: InputDecoration(labelText: context.tr('education')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _city,
                decoration: InputDecoration(labelText: context.tr('city')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _address,
                decoration: InputDecoration(labelText: context.tr('address')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: context.tr('phone')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _skills,
                decoration: InputDecoration(
                  labelText: context.tr('commaSkills'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _summary,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: context.tr('professionalSummary'),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr('preferFlexibleJobs')),
                value: _prefersRemote,
                onChanged: (value) => setState(() => _prefersRemote = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(onPressed: _save, child: Text(context.tr('save'))),
      ],
    );
  }
}

// Same controller-lifecycle reasoning as _EditProfileDialog -- the
// autofocus here made the underlying crash easier to hit than anywhere
// else in the app, since the keyboard opens the instant this dialog shows.
class _SaveSearchDialog extends StatefulWidget {
  const _SaveSearchDialog({required this.defaultName});
  final String defaultName;

  @override
  State<_SaveSearchDialog> createState() => _SaveSearchDialogState();
}

class _SaveSearchDialogState extends State<_SaveSearchDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.defaultName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('saveThisSearch')),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 60,
        decoration: InputDecoration(labelText: context.tr('searchName')),
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(context.tr('save')),
        ),
      ],
    );
  }
}

// Same controller-lifecycle reasoning as _EditProfileDialog.
class _LetterEditorDialog extends StatefulWidget {
  const _LetterEditorDialog({
    required this.company,
    required this.letter,
    required this.byAi,
    required this.fallbackNote,
    required this.onPreviewPdf,
    required this.onCopied,
  });

  final String company;
  final String letter;
  final bool byAi;
  final String? fallbackNote;
  final ValueChanged<String> onPreviewPdf;
  final VoidCallback onCopied;

  @override
  State<_LetterEditorDialog> createState() => _LetterEditorDialogState();
}

class _LetterEditorDialogState extends State<_LetterEditorDialog> {
  late final TextEditingController _editor;

  @override
  void initState() {
    super.initState();
    _editor = TextEditingController(text: widget.letter);
  }

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        context.trFormat('coverLetterFor', {'company': widget.company}),
      ),
      content: SizedBox(
        width: 680,
        height: math.min(MediaQuery.sizeOf(context).height * .52, 460),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.byAi
                  ? context.tr('letterByNia')
                  : widget.fallbackNote ?? context.tr('letterQuickTemplate'),
              style: TextStyle(
                color: widget.byAi ? _green : _muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: _editor,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  alignLabelWithHint: true,
                  labelText: context.tr('editLetterBeforeDownload'),
                  hintText: context.tr('letterEditorHint'),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('close')),
        ),
        OutlinedButton.icon(
          onPressed: () {
            final editedLetter = _editor.text.trim();
            if (editedLetter.isEmpty) return;
            Navigator.pop(context);
            widget.onPreviewPdf(editedLetter);
          },
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: Text(context.tr('previewPdf')),
        ),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _editor.text));
            if (context.mounted) Navigator.pop(context);
            widget.onCopied();
          },
          icon: const Icon(Icons.copy_rounded),
          label: Text(context.tr('copy')),
        ),
      ],
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
