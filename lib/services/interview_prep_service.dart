import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_language.dart';

class InterviewQuestion {
  const InterviewQuestion({
    required this.id,
    required this.question,
    required this.purpose,
    required this.guidance,
    required this.suggestedPoints,
  });

  final String id;
  final String question;
  final String purpose;
  final String guidance;
  final List<String> suggestedPoints;
}

class InterviewSession {
  const InterviewSession({
    required this.jobId,
    required this.answers,
    required this.rehearsedQuestionIds,
    required this.updatedAt,
  });

  factory InterviewSession.empty(int jobId) => InterviewSession(
    jobId: jobId,
    answers: const {},
    rehearsedQuestionIds: const {},
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  final int jobId;
  final Map<String, String> answers;
  final Set<String> rehearsedQuestionIds;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'job_id': jobId,
    'answers': answers,
    'rehearsed': rehearsedQuestionIds.toList(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  factory InterviewSession.fromJson(Map<String, dynamic> json) =>
      InterviewSession(
        jobId: (json['job_id'] as num?)?.toInt() ?? 0,
        answers: json['answers'] is Map
            ? Map<String, String>.from(
                (json['answers'] as Map).map(
                  (key, value) => MapEntry(key.toString(), value.toString()),
                ),
              )
            : const {},
        rehearsedQuestionIds: (json['rehearsed'] as List? ?? const [])
            .map((value) => value.toString())
            .toSet(),
        updatedAt:
            DateTime.tryParse(json['updated_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
}

class InterviewPrepService {
  const InterviewPrepService();

  static const _storagePrefix = 'werkly_interview_v1_';

  List<InterviewQuestion> buildQuestions({
    required AppLanguage language,
    required String jobTitle,
    required String company,
    required List<String> jobSkills,
    required List<String> matchedSkills,
    required String degree,
    required String summary,
  }) {
    final strings = AppStrings(language);
    String tr(String key, [Map<String, Object> values = const {}]) =>
        values.isEmpty ? strings.get(key) : strings.format(key, values);
    final prioritySkills = matchedSkills.isNotEmpty
        ? matchedSkills.take(3).toList()
        : jobSkills.take(3).toList();
    final skillLabel = prioritySkills.isEmpty
        ? tr('interviewRoleSkillsFallback')
        : prioritySkills.join(', ');
    final studyLabel = degree.trim().isEmpty
        ? tr('interviewStudyFallback')
        : degree.trim();
    return [
      InterviewQuestion(
        id: 'pitch',
        question: tr('interviewPitchQuestion'),
        purpose: tr('interviewPitchPurpose'),
        guidance: tr('interviewPitchGuidance'),
        suggestedPoints: [
          studyLabel,
          if (prioritySkills.isNotEmpty) skillLabel,
          tr('interviewLearnAtCompany', {'company': company}),
        ],
      ),
      InterviewQuestion(
        id: 'motivation',
        question: tr('interviewMotivationQuestion', {
          'company': company,
          'job': jobTitle,
        }),
        purpose: tr('interviewMotivationPurpose'),
        guidance: tr('interviewMotivationGuidance'),
        suggestedPoints: [
          tr('interviewSpecificTask'),
          tr('interviewSkillInterest', {'skills': skillLabel}),
          tr('interviewEarlyContribution'),
        ],
      ),
      InterviewQuestion(
        id: 'star',
        question: tr('interviewStarQuestion', {'skills': skillLabel}),
        purpose: tr('interviewStarPurpose'),
        guidance: tr('interviewStarGuidance'),
        suggestedPoints: [
          tr('interviewContextProblem'),
          tr('interviewExactResponsibility'),
          tr('interviewDecisionsTools'),
          tr('interviewResultLesson'),
        ],
      ),
      InterviewQuestion(
        id: 'teamwork',
        question: tr('interviewTeamworkQuestion'),
        purpose: tr('interviewTeamworkPurpose'),
        guidance: tr('interviewTeamworkGuidance'),
        suggestedPoints: [
          tr('interviewFactsNoBlame'),
          tr('interviewCommunicationUsed'),
          tr('interviewSharedSolution'),
          tr('interviewResult'),
        ],
      ),
      InterviewQuestion(
        id: 'gap',
        question: tr('interviewGapQuestion'),
        purpose: tr('interviewGapPurpose'),
        guidance: tr('interviewGapGuidance'),
        suggestedPoints: [
          if (jobSkills.isNotEmpty) jobSkills.last,
          tr('interviewLearningResource'),
          tr('interviewMeasureProgress'),
        ],
      ),
      InterviewQuestion(
        id: 'availability',
        question: tr('interviewAvailabilityQuestion'),
        purpose: tr('interviewAvailabilityPurpose'),
        guidance: tr('interviewAvailabilityGuidance'),
        suggestedPoints: [
          tr('interviewWeeklyHours'),
          tr('interviewPreferredDays'),
          tr('interviewExamNotice'),
          if (summary.trim().isNotEmpty) tr('interviewCurrentSchedule'),
        ],
      ),
    ];
  }

  Future<InterviewSession> load(int jobId) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString('$_storagePrefix$jobId');
    if (encoded == null || encoded.isEmpty) {
      return InterviewSession.empty(jobId);
    }
    try {
      final value = jsonDecode(encoded);
      return value is Map
          ? InterviewSession.fromJson(Map<String, dynamic>.from(value))
          : InterviewSession.empty(jobId);
    } catch (_) {
      return InterviewSession.empty(jobId);
    }
  }

  Future<InterviewSession> save({
    required int jobId,
    required Map<String, String> answers,
    required Set<String> rehearsedQuestionIds,
  }) async {
    final session = InterviewSession(
      jobId: jobId,
      answers: Map<String, String>.from(answers),
      rehearsedQuestionIds: Set<String>.from(rehearsedQuestionIds),
      updatedAt: DateTime.now().toUtc(),
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      '$_storagePrefix$jobId',
      jsonEncode(session.toJson()),
    );
    return session;
  }

  int answerQuality(String answer) {
    final value = answer.trim();
    if (value.isEmpty) return 0;
    var score = value.length >= 220
        ? 55
        : value.length >= 120
        ? 40
        : value.length >= 60
        ? 25
        : 10;
    final normalized = value.toLowerCase();
    if (RegExp(
      r"\b(j’ai|j'ai|ich|nous|wir|mon|mein|i|we|my)\b",
    ).hasMatch(normalized)) {
      score += 15;
    }
    if (RegExp(
      r'\b(résultat|resultat|ergebnis|result|outcome|%|augment|increas|réduit|reduziert|reduc|livré|geliefert|delivered)\b',
    ).hasMatch(normalized)) {
      score += 20;
    }
    if (RegExp(
      r'\b(appris|gelernt|learned|learnt|amélior|verbessert|improv|feedback)\b',
    ).hasMatch(normalized)) {
      score += 10;
    }
    return score.clamp(0, 100);
  }
}
