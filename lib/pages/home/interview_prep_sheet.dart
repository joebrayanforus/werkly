part of '../home_page.dart';

class _InterviewPrepSheet extends StatefulWidget {
  const _InterviewPrepSheet({required this.job, required this.profile});

  final Job job;
  final UserProfileData profile;

  @override
  State<_InterviewPrepSheet> createState() => _InterviewPrepSheetState();
}

class _InterviewPrepSheetState extends State<_InterviewPrepSheet> {
  final _service = const InterviewPrepService();
  late final List<InterviewQuestion> _questions;
  final Map<String, TextEditingController> _controllers = {};
  final Set<String> _rehearsed = {};
  var _index = 0;
  var _loading = true;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _questions = _service.buildQuestions(
      language: AppLanguageController.language.value,
      jobTitle: widget.job.title,
      company: widget.job.company,
      jobSkills: widget.job.tags,
      matchedSkills: widget.job.compatibility.matchedSkills,
      degree: widget.profile.degree,
      summary: widget.profile.professionalSummary,
    );
    for (final question in _questions) {
      _controllers[question.id] = TextEditingController();
    }
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final session = await _service.load(widget.job.id);
    if (!mounted) return;
    for (final question in _questions) {
      _controllers[question.id]!.text = session.answers[question.id] ?? '';
    }
    setState(() {
      _rehearsed.addAll(session.rehearsedQuestionIds);
      _loading = false;
    });
  }

  Map<String, String> get _answers => {
    for (final question in _questions)
      question.id: _controllers[question.id]!.text.trim(),
  };

  double get _progress {
    if (_questions.isEmpty) return 0;
    final answered = _answers.values
        .where((answer) => answer.isNotEmpty)
        .length;
    return ((answered + _rehearsed.length) / (_questions.length * 2)).clamp(
      0,
      1,
    );
  }

  Future<void> _save({bool close = false}) async {
    if (_saving) return;
    setState(() => _saving = true);
    await _service.save(
      jobId: widget.job.id,
      answers: _answers,
      rehearsedQuestionIds: _rehearsed,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (close) {
      Navigator.pop(context);
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr('interviewPrepSaved'))));
  }

  Future<void> _move(int nextIndex) async {
    await _save();
    if (!mounted) return;
    setState(() => _index = nextIndex.clamp(0, _questions.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final question = _questions[_index];
    final answer = _controllers[question.id]!.text;
    final quality = _service.answerQuality(answer);
    return Container(
      height: MediaQuery.sizeOf(context).height * .94,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const _SheetHandle(),
          Padding(
            padding: EdgeInsets.fromLTRB(width > 700 ? 34 : 18, 8, 10, 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _mint,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.record_voice_over_outlined,
                    color: _green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.trFormat('interviewTitleCompany', {
                          'company': widget.job.company,
                        }),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        context.trFormat('interviewProgressPrivate', {
                          'progress': (_progress * 100).round(),
                        }),
                        style: const TextStyle(color: _muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _save(close: true),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: _progress,
            minHeight: 5,
            color: _green,
            backgroundColor: _line,
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 780),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          width > 700 ? 34 : 18,
                          24,
                          width > 700 ? 34 : 18,
                          120,
                        ),
                        children: [
                          Row(
                            children: [
                              Text(
                                context.trFormat('questionProgress', {
                                  'current': _index + 1,
                                  'total': _questions.length,
                                }),
                                style: const TextStyle(
                                  color: _green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                context.trFormat('answerQuality', {
                                  'score': quality,
                                }),
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            question.question,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            question.purpose,
                            style: const TextStyle(color: _muted, height: 1.45),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F6F2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  question.guidance,
                                  style: const TextStyle(
                                    color: _green,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                for (final point in question.suggestedPoints)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '• $point',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _controllers[question.id],
                            minLines: 6,
                            maxLines: 10,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: context.tr('buildAnswerHere'),
                              hintText: context.tr('answerHint'),
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _rehearsed.contains(question.id),
                            onChanged: (selected) => setState(() {
                              selected == true
                                  ? _rehearsed.add(question.id)
                                  : _rehearsed.remove(question.id);
                            }),
                            title: Text(
                              context.tr('rehearsedAnswer'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(context.tr('rehearsalGoal')),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _index == 0
                                    ? null
                                    : () => _move(_index - 1),
                                icon: const Icon(Icons.arrow_back_rounded),
                                label: Text(context.tr('previous')),
                              ),
                              const Spacer(),
                              if (_index < _questions.length - 1)
                                FilledButton.icon(
                                  onPressed: _saving
                                      ? null
                                      : () => _move(_index + 1),
                                  icon: const Icon(Icons.arrow_forward_rounded),
                                  label: Text(context.tr('next')),
                                )
                              else
                                FilledButton.icon(
                                  onPressed: _saving
                                      ? null
                                      : () => _save(close: true),
                                  icon: const Icon(Icons.check_rounded),
                                  label: Text(context.tr('finish')),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

