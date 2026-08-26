part of '../home_page.dart';

class _AssistantSheet extends StatefulWidget {
  const _AssistantSheet({
    required this.jobs,
    required this.profile,
    required this.selectedJob,
    this.initialPrompt,
  });

  final List<Job> jobs;
  final UserProfileData profile;
  final Job selectedJob;
  final String? initialPrompt;

  @override
  State<_AssistantSheet> createState() => _AssistantSheetState();
}

class _AssistantSheetState extends State<_AssistantSheet> {
  final _controller = TextEditingController();
  final _repository = WerklyRepository();
  final List<(bool, String)> _messages = [];
  bool _loading = false;
  int? _remainingHourlyRequests;

  @override
  void initState() {
    super.initState();
    final name = widget.profile.fullName.trim();
    final greetingName = _isGuestProfileName(name)
        ? ''
        : ' ${name.split(' ').first}';
    _messages.add((
      false,
      context.trFormat('assistantGreeting', {'name': greetingName}),
    ));
    final prompt = widget.initialPrompt?.trim();
    if (prompt != null && prompt.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(prompt));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send([String? quickMessage]) async {
    final message = (quickMessage ?? _controller.text).trim();
    if (message.isEmpty || _loading) return;
    setState(() {
      _messages.add((true, message));
      _controller.clear();
    });

    if (_repository.currentUser == null) {
      setState(() => _messages.add((false, _reply(message))));
      return;
    }

    var privacyChoice = await _repository.getAiPrivacyChoice();
    if (privacyChoice == null && mounted) {
      privacyChoice = await _askForAiConsent();
      if (privacyChoice != null) {
        await _repository.setAiPrivacyChoice(privacyChoice);
      }
    }
    if (privacyChoice != true) {
      if (mounted) {
        setState(() => _messages.add((false, _reply(message))));
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final ranked = [...widget.jobs]
        ..sort((a, b) => b.match.compareTo(a.match));
      final (reply, remaining) = await _repository.askAi(
        message: message,
        profile: widget.profile,
        selectedJob: _jobContext(widget.selectedJob),
        bestMatches: ranked.take(5).map(_matchContext).toList(),
      );
      if (mounted) {
        setState(() {
          _messages.add((false, reply));
          if (remaining != null) _remainingHourlyRequests = remaining;
        });
      }
    } on AiQuotaExceededException catch (error) {
      if (mounted) {
        setState(() {
          _messages.add((false, error.message));
          _remainingHourlyRequests = 0;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add((
            false,
            '${context.tr('assistantLocalFallback')}\n\n${_reply(message)}',
          ));
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reportAiMessage(String content) async {
    var reason = 'inaccurate';
    final detailsController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(dialogContext.tr('reportAiTitle')),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  dialogContext.tr('reportAiExplanation'),
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: reason,
                  decoration: InputDecoration(
                    labelText: dialogContext.tr('reportAiReason'),
                  ),
                  items:
                      [
                            (
                              'inaccurate',
                              dialogContext.tr('reportAiInaccurate'),
                            ),
                            (
                              'offensive',
                              dialogContext.tr('reportAiOffensive'),
                            ),
                            ('unsafe', dialogContext.tr('reportAiUnsafe')),
                            ('other', dialogContext.tr('reportAiOther')),
                          ]
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item.$1,
                              child: Text(item.$2),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => reason = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: detailsController,
                  maxLength: 1000,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: dialogContext.tr('reportAiDetails'),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dialogContext.tr('cancel')),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: Text(dialogContext.tr('sendReport')),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) {
      detailsController.dispose();
      return;
    }
    final details = detailsController.text;
    detailsController.dispose();
    try {
      await _repository.reportAiContent(
        content: content,
        reason: reason,
        details: details,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('reportAiSent'))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('reportAiFailed'))));
      }
    }
  }

  Map<String, dynamic> _jobContext(Job job) => {
    'title': job.title,
    'company': job.company,
    'location': job.location,
    'tags': job.tags,
    'description': job.description,
  };

  Map<String, dynamic> _matchContext(Job job) => {
    'title': job.title,
    'company': job.company,
    'match': job.match,
    'tags': job.tags,
  };

  Future<bool?> _askForAiConsent() => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr('aiConsentTitle')),
      content: Text(context.tr('aiConsentBody')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr('stayLocal')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.tr('continue')),
        ),
      ],
    ),
  );

  String _reply(String message) {
    final normalized = message.toLowerCase();
    final job = widget.selectedJob;
    final language = AppLanguageController.language.value;
    final asksInterview = [
      'entretien',
      'interview',
      'vorstellungsgespräch',
      'gespräch',
    ].any(normalized.contains);
    final asksLetter = [
      'lettre',
      'anschreiben',
      'cover letter',
      'motivation',
    ].any(normalized.contains);
    final asksProfile = [
      'cv',
      'profil',
      'lebenslauf',
      'resume',
      'résumé',
    ].any(normalized.contains);
    if (asksInterview) {
      final skills = job.tags.take(3).join(', ');
      return switch (language) {
        AppLanguage.fr =>
          '''Préparation pour ${job.company} — ${job.title}

1. Prépare une présentation de 60 secondes.
2. Donne un exemple STAR lié à $skills.
3. Explique pourquoi ce poste complète ta formation.
4. Prépare une question sur les missions des Werkstudierenden.
5. Demande les prochaines étapes du recrutement.

Question d’entraînement : « Parle-moi d’un projet où tu as dû apprendre rapidement une nouvelle compétence. »''',
        AppLanguage.de =>
          '''Vorbereitung für ${job.company} — ${job.title}

1. Bereite eine 60-sekündige Selbstvorstellung vor.
2. Nenne ein STAR-Beispiel zu $skills.
3. Erkläre, wie diese Stelle dein Studium ergänzt.
4. Bereite eine Frage zu den Aufgaben der Werkstudierenden vor.
5. Frage nach den nächsten Schritten im Auswahlprozess.

Übungsfrage: „Erzähle von einem Projekt, bei dem du schnell eine neue Fähigkeit lernen musstest.“''',
        AppLanguage.en =>
          '''Preparation for ${job.company} — ${job.title}

1. Prepare a 60-second introduction.
2. Give a STAR example related to $skills.
3. Explain how this role complements your studies.
4. Prepare a question about working-student responsibilities.
5. Ask about the next steps in the hiring process.

Practice question: “Tell me about a project where you had to learn a new skill quickly.”''',
      };
    }
    if (asksLetter) {
      return _applicationLetter(
        job: job,
        profile: widget.profile,
        language: language,
      );
    }
    if (asksProfile) {
      final missing = <String>[];
      if (widget.profile.professionalSummary.trim().isEmpty) {
        missing.add(switch (language) {
          AppLanguage.fr => 'ajouter un résumé professionnel de 3 à 4 lignes',
          AppLanguage.de =>
            'eine berufliche Zusammenfassung mit 3 bis 4 Zeilen ergänzen',
          AppLanguage.en => 'add a 3 to 4-line professional summary',
        });
      }
      if (widget.profile.skills.isEmpty) {
        missing.add(switch (language) {
          AppLanguage.fr =>
            'renseigner tes compétences techniques et linguistiques',
          AppLanguage.de =>
            'deine technischen und sprachlichen Kompetenzen angeben',
          AppLanguage.en => 'list your technical and language skills',
        });
      }
      if (widget.profile.degree.trim().isEmpty) {
        missing.add(switch (language) {
          AppLanguage.fr => 'préciser ta formation actuelle',
          AppLanguage.de => 'dein aktuelles Studium angeben',
          AppLanguage.en => 'specify your current education',
        });
      }
      if (widget.profile.cvPath == null) {
        missing.add(switch (language) {
          AppLanguage.fr => 'ajouter ton CV au profil',
          AppLanguage.de => 'deinen Lebenslauf zum Profil hinzufügen',
          AppLanguage.en => 'add your CV to the profile',
        });
      }
      if (missing.isNotEmpty) {
        return switch (language) {
          AppLanguage.fr =>
            'Priorités pour ton profil :\n• ${missing.join('\n• ')}',
          AppLanguage.de =>
            'Prioritäten für dein Profil:\n• ${missing.join('\n• ')}',
          AppLanguage.en =>
            'Priorities for your profile:\n• ${missing.join('\n• ')}',
        };
      }
      return switch (language) {
        AppLanguage.fr =>
          'Ton profil est complet à ${widget.profile.profileCompletion} %. Pour le renforcer, ajoute des résultats chiffrés à chaque expérience et adapte les mots-clés à l’offre ${job.title}.',
        AppLanguage.de =>
          'Dein Profil ist zu ${widget.profile.profileCompletion} % vollständig. Ergänze messbare Ergebnisse zu jeder Erfahrung und passe die Schlüsselwörter an ${job.title} an.',
        AppLanguage.en =>
          'Your profile is ${widget.profile.profileCompletion}% complete. Add measurable results to each experience and tailor the keywords to ${job.title}.',
      };
    }
    final ranked = [...widget.jobs]..sort((a, b) => b.match.compareTo(a.match));
    if (ranked.isEmpty) {
      return switch (language) {
        AppLanguage.fr =>
          'Aucune offre active n’est disponible pour le moment. Modifie tes filtres ou reviens après la prochaine synchronisation.',
        AppLanguage.de =>
          'Derzeit sind keine aktiven Jobs verfügbar. Ändere deine Filter oder versuche es nach der nächsten Synchronisierung erneut.',
        AppLanguage.en =>
          'No active jobs are available right now. Change your filters or return after the next sync.',
      };
    }
    final recommendations = ranked
        .take(3)
        .map((item) => '• ${item.title} — ${item.company} — ${item.match} %')
        .join('\n');
    return switch (language) {
      AppLanguage.fr =>
        'Tes meilleures pistes actuelles :\n$recommendations\n\nJe peux préparer une lettre ou un entretien pour l’une de ces offres.',
      AppLanguage.de =>
        'Deine aktuell besten Optionen:\n$recommendations\n\nIch kann für einen dieser Jobs ein Anschreiben oder ein Gespräch vorbereiten.',
      AppLanguage.en =>
        'Your best current options:\n$recommendations\n\nI can prepare a letter or an interview for one of these jobs.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        width: width > 620 ? 500 : width,
        height: MediaQuery.sizeOf(context).height * .86,
        margin: EdgeInsets.all(width > 620 ? 18 : 0),
        decoration: BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(26),
            bottom: Radius.circular(width > 620 ? 26 : 0),
          ),
        ),
        child: Column(
          children: [
            const _SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 15),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _ink,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: _orange,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nia',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _repository.currentUser == null
                              ? context.tr('assistantLocalMode')
                              : _remainingHourlyRequests == null
                              ? context.tr('assistantGeminiMode')
                              : context.trFormat('assistantQuotaRemaining', {
                                  'count': _remainingHourlyRequests!,
                                }),
                          style: const TextStyle(color: _green, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _line),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  for (final message in _messages)
                    _MessageBubble(
                      user: message.$1,
                      text: message.$2,
                      onReport: !message.$1 && _repository.currentUser != null
                          ? () => _reportAiMessage(message.$2)
                          : null,
                    ),
                  if (_loading)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(14, 8, 14, 16),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  if (_messages.length == 1) ...[
                    const SizedBox(height: 8),
                    Text(
                      context.tr('assistantSuggestions'),
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _QuickPrompt(
                          label: context.tr('assistantInterviewPrompt'),
                          onTap: () =>
                              _send(context.tr('assistantInterviewPrompt')),
                        ),
                        _QuickPrompt(
                          label: context.tr('assistantLetterPrompt'),
                          onTap: () =>
                              _send(context.tr('assistantLetterPrompt')),
                        ),
                        _QuickPrompt(
                          label: context.tr('assistantCvPrompt'),
                          onTap: () => _send(context.tr('assistantCvPrompt')),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                15,
                10,
                15,
                15 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_loading,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: context.tr('assistantHint'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  IconButton.filled(
                    onPressed: _loading ? null : () => _send(),
                    style: IconButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded),
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.user, required this.text, this.onReport});
  final bool user;
  final String text;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 350),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: user ? _green : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(user ? 16 : 4),
            bottomRight: Radius.circular(user ? 4 : 16),
          ),
          border: user ? null : Border.all(color: _line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: user ? Colors.white : _ink,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            if (onReport != null) ...[
              const SizedBox(height: 8),
              Semantics(
                button: true,
                label: context.tr('reportAiContent'),
                child: InkWell(
                  onTap: onReport,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.flag_outlined,
                          size: 14,
                          color: _muted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          context.tr('reportAiContent'),
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickPrompt extends StatelessWidget {
  const _QuickPrompt({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onTap, child: Text(label));
  }
}

