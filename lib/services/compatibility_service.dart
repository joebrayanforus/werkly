import '../data/werkly_repository.dart';
import '../l10n/app_language.dart';

class CompatibilityBreakdown {
  const CompatibilityBreakdown({
    required this.scored,
    required this.overall,
    required this.skills,
    required this.relevance,
    required this.workConditions,
    required this.language,
    required this.education,
    required this.experience,
    required this.compensation,
    required this.distance,
    required this.freshness,
    required this.confidence,
    required this.evaluatedCriteria,
    required this.matchedSkills,
    required this.missingSkills,
    required this.reasons,
    required this.cautions,
    this.languageDetail = '',
  });

  const CompatibilityBreakdown.unscored({
    this.matchedSkills = const [],
    this.missingSkills = const [],
    this.cautions = const [],
  }) : scored = false,
       overall = 0,
       skills = 0,
       relevance = 0,
       workConditions = 0,
       language = 0,
       education = 0,
       experience = 0,
       compensation = 0,
       distance = 0,
       freshness = 0,
       confidence = 0,
       evaluatedCriteria = const {},
       reasons = const [],
       languageDetail = '';

  final bool scored;
  final int overall;
  final int skills;
  final int relevance;
  final int workConditions;
  final int language;
  final int education;
  final int experience;
  final int compensation;
  final int distance;
  final int freshness;
  final int confidence;
  final Set<String> evaluatedCriteria;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final List<String> reasons;
  final List<String> cautions;
  final String languageDetail;

  bool evaluates(String criterion) => evaluatedCriteria.contains(criterion);
}

CompatibilityBreakdown calculateJobCompatibility({
  required UserProfileData profile,
  required List<String> jobTags,
  required String jobTitle,
  required String jobDescription,
  required String jobLocation,
  required bool remote,
  required DateTime? postedAt,
  String? remoteType,
  double? hourlyMin,
  double minimumDesiredSalary = 0,
  double? distanceKm,
  int? searchRadiusKm,
  DateTime? now,
  AppLanguage language = AppLanguage.fr,
}) {
  final strings = AppStrings(language);
  String tr(String key, [Map<String, Object> values = const {}]) =>
      values.isEmpty ? strings.get(key) : strings.format(key, values);
  final reference = (now ?? DateTime.now()).toUtc();
  final profileSkills = _profileSkills(profile);
  final jobText = '$jobTitle ${jobTags.join(' ')} $jobDescription';
  final requirements = _jobSkills(jobTags, jobText);
  final matched = requirements
      .where(
        (requirement) =>
            profileSkills.any((skill) => _skillMatches(skill, requirement)),
      )
      .toList();
  final missing = requirements
      .where((requirement) => !matched.contains(requirement))
      .toList();

  final hasUsefulProfile =
      profileSkills.isNotEmpty ||
      profile.professionalSummary.trim().isNotEmpty ||
      profile.degree.trim().isNotEmpty ||
      _analysisItems(profile.cvAnalysis['education']).isNotEmpty ||
      _analysisItems(profile.cvAnalysis['experiences']).isNotEmpty;
  if (!hasUsefulProfile) {
    return CompatibilityBreakdown.unscored(
      matchedSkills: matched,
      missingSkills: missing,
      cautions: [tr('compatAddProfile')],
    );
  }

  final evaluated = <String>{};
  final components = <({int score, double weight})>[];
  void add(String name, int score, double weight) {
    evaluated.add(name);
    components.add((score: score.clamp(0, 100), weight: weight));
  }

  final skillScore = requirements.isEmpty
      ? 0
      : ((matched.length / requirements.length) * 100).round();
  if (requirements.isNotEmpty) add('skills', skillScore, 32);

  final profileText = [
    profile.degree,
    profile.professionalSummary,
    ...profileSkills,
    ..._analysisItems(profile.cvAnalysis['experiences'])
        .expand((item) => [item['title'], item['organization']])
        .whereType<String>(),
  ].join(' ');
  final profileTokens = _tokens(profileText);
  final jobTokens = _tokens(jobText);
  final relevantTokens = profileTokens.intersection(jobTokens);
  final textRelevanceScore = profileTokens.isEmpty
      ? 0
      : ((relevantTokens.length / profileTokens.length.clamp(1, 14)) * 100)
            .round()
            .clamp(0, 100);
  final fieldPreferenceScore = _fieldPreferenceScore(
    profile.preferences['fields'],
    jobText,
  );
  final careerFitScore = _careerFitScore(
    profileText: profileText,
    jobTitle: jobTitle,
    jobTags: jobTags,
    jobDescription: jobDescription,
  );
  final relevanceScore = fieldPreferenceScore == null
      ? (textRelevanceScore * .3 + careerFitScore * .7).round()
      : (textRelevanceScore * .2 +
                careerFitScore * .6 +
                fieldPreferenceScore * .2)
            .round();
  add('relevance', relevanceScore, 28);

  final workScores = <int>[];
  final preferredMode = profile.preferences['work_mode'] as String?;
  final normalizedRemoteType = _normalizedRemoteType(remoteType, remote);
  if (preferredMode != null && preferredMode.isNotEmpty) {
    workScores.add(_workModeFit(preferredMode, normalizedRemoteType));
  } else if (profile.preferences['remote'] is bool) {
    final wantsRemote = profile.preferences['remote'] as bool;
    workScores.add(
      wantsRemote
          ? (normalizedRemoteType == 'onsite' ? 25 : 100)
          : (normalizedRemoteType == 'remote' ? 65 : 95),
    );
  }
  final weeklyHours = profile.preferences['weekly_hours'];
  if (weeklyHours is String && weeklyHours.isNotEmpty) {
    workScores.add(_weeklyHoursFit(weeklyHours, jobText));
  }
  final workScore = workScores.isEmpty
      ? 0
      : (workScores.reduce((a, b) => a + b) / workScores.length).round();
  if (workScores.isNotEmpty) add('work', workScore, 14);

  final requiredGerman = _requiredGermanLevel(jobText);
  final profileGerman = _profileGermanLevel(profile);
  final languageScore = requiredGerman == null
      ? 0
      : _levelFit(profileGerman, requiredGerman);
  if (requiredGerman != null) add('language', languageScore, 10);
  final languageDetail = requiredGerman == null
      ? ''
      : tr('compatLanguageDetail', {
          'profile': _levelName(profileGerman, tr('compatUnknownLevel')),
          'required': _levelName(requiredGerman, tr('compatUnknownLevel')),
        });

  final educationRequirement = _educationRequirement(jobText);
  final hasEducation =
      profile.degree.trim().isNotEmpty ||
      _analysisItems(profile.cvAnalysis['education']).isNotEmpty;
  final educationScore = educationRequirement == null
      ? 0
      : _educationFit(profile, educationRequirement, hasEducation);
  if (educationRequirement != null) add('education', educationScore, 7);

  final experienceRequirement = _experienceRequirement(jobText);
  final experienceMonths = _estimatedExperienceMonths(profile, reference);
  final experienceScore = experienceRequirement == null
      ? 0
      : _experienceFit(experienceRequirement, experienceMonths);
  if (experienceRequirement != null) add('experience', experienceScore, 7);

  final compensationScore = minimumDesiredSalary <= 0 || hourlyMin == null
      ? 0
      : hourlyMin >= minimumDesiredSalary
      ? 100
      : (minimumDesiredSalary - hourlyMin <= 2 ? 65 : 20);
  if (minimumDesiredSalary > 0 && hourlyMin != null) {
    add('compensation', compensationScore, 5);
  }

  final effectiveRadius =
      searchRadiusKm ?? (profile.preferences['search_radius'] as num?)?.toInt();
  final distanceScore = normalizedRemoteType == 'remote'
      ? 100
      : distanceKm == null || effectiveRadius == null || effectiveRadius <= 0
      ? 0
      : distanceKm <= effectiveRadius
      ? 100
      : distanceKm <= effectiveRadius * 1.5
      ? 60
      : 15;
  if (normalizedRemoteType == 'remote' ||
      (distanceKm != null && effectiveRadius != null && effectiveRadius > 0)) {
    add('distance', distanceScore, 4);
  }

  final ageDays = postedAt == null
      ? null
      : reference.difference(postedAt.toUtc()).inHours / 24;
  final freshnessScore = ageDays == null
      ? 0
      : ageDays <= 3
      ? 100
      : ageDays <= 7
      ? 85
      : ageDays <= 14
      ? 70
      : ageDays <= 30
      ? 50
      : 20;
  if (ageDays != null) add('freshness', freshnessScore, 5);

  final overall = _weightedAverage(components);
  final evaluatedWeight = components.fold<double>(
    0,
    (sum, item) => sum + item.weight,
  );
  final profileEvidence =
      (profileSkills.isNotEmpty ? 25 : 0) +
      (profile.professionalSummary.trim().isNotEmpty ? 15 : 0) +
      (hasEducation ? 15 : 0) +
      (profile.cvAnalysisStatus == 'complete' ? 25 : 0) +
      (profile.preferences.isNotEmpty ? 20 : 0);
  final confidence =
      (profileEvidence * .65 + evaluatedWeight.clamp(0, 100) * .35)
          .round()
          .clamp(0, 100);

  final reasons = <String>[
    if (matched.isNotEmpty)
      tr('compatMatchedSkills', {'count': matched.length}),
    if (requiredGerman != null && languageScore >= 70)
      tr('compatGermanMatches'),
    if (evaluated.contains('distance') && distanceScore >= 60)
      normalizedRemoteType == 'remote'
          ? tr('compatFullyRemote')
          : tr('compatWithinRadius'),
    if (evaluated.contains('compensation') && compensationScore >= 65)
      tr('compatSalaryMatches'),
  ];
  final cautions = <String>[
    if (requirements.isEmpty) tr('compatNoStructuredSkills'),
    if (missing.isNotEmpty)
      tr('compatMissingSkills', {'skills': missing.join(', ')}),
    if (requiredGerman != null && languageScore < 70)
      tr('compatGermanReview', {'detail': languageDetail}),
    if (minimumDesiredSalary > 0 && hourlyMin == null)
      tr('compatSalaryNotPublished'),
    if (evaluated.contains('distance') && distanceScore < 60)
      tr('compatOutsideRadius'),
  ];

  return CompatibilityBreakdown(
    scored: components.isNotEmpty,
    overall: overall,
    skills: skillScore,
    relevance: relevanceScore,
    workConditions: workScore,
    language: languageScore,
    education: educationScore,
    experience: experienceScore,
    compensation: compensationScore,
    distance: distanceScore,
    freshness: freshnessScore,
    confidence: confidence,
    evaluatedCriteria: evaluated,
    matchedSkills: matched,
    missingSkills: missing,
    reasons: reasons,
    cautions: cautions,
    languageDetail: languageDetail,
  );
}

List<String> _profileSkills(UserProfileData profile) {
  final values = <String>{...profile.skills};
  for (final item in _analysisItems(profile.cvAnalysis['skills'])) {
    final name = item['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) values.add(name);
  }
  return values.where((value) => value.trim().isNotEmpty).toList();
}

/// Whether [tag] is boilerplate ("Werkstudent", "IT", "Sales"...) rather than
/// an actual skill -- useful whenever a caller falls back to a job's raw tags
/// instead of a real skill match, so it doesn't present noise as a skill.
bool isGenericJobTag(String tag) => _genericJobTags.contains(normalizeText(tag));

List<String> _jobSkills(List<String> tags, String jobText) {
  final result = <String>{};
  for (final tag in tags) {
    final value = tag.trim();
    if (value.isNotEmpty && !_genericJobTags.contains(normalizeText(value))) {
      result.add(value);
    }
  }
  final normalized = normalizeText(jobText);
  for (final entry in _skillAliases.entries) {
    if (entry.value.any((alias) => normalized.contains(alias))) {
      result.add(entry.key);
    }
  }
  return result.toList();
}

int _weightedAverage(List<({int score, double weight})> values) {
  if (values.isEmpty) return 0;
  final totalWeight = values.fold<double>(0, (sum, item) => sum + item.weight);
  final total = values.fold<double>(
    0,
    (sum, item) => sum + item.score * item.weight,
  );
  return (total / totalWeight).round().clamp(0, 100);
}

String _normalizedRemoteType(String? value, bool remote) {
  final normalized = normalizeText(value ?? '');
  if (normalized.contains('hybrid')) return 'hybrid';
  if (normalized.contains('remote')) return 'remote';
  if (normalized.contains('onsite') || normalized.contains('on-site')) {
    return 'onsite';
  }
  return remote ? 'hybrid' : 'onsite';
}

int _workModeFit(String preferredMode, String remoteType) {
  final preferred = normalizeText(preferredMode);
  if (preferred.contains('teletravail')) {
    return remoteType == 'remote'
        ? 100
        : remoteType == 'hybrid'
        ? 75
        : 20;
  }
  if (preferred.contains('hybride')) {
    return remoteType == 'hybrid' ? 100 : 70;
  }
  if (preferred.contains('site')) {
    return remoteType == 'onsite'
        ? 100
        : remoteType == 'hybrid'
        ? 80
        : 55;
  }
  return 70;
}

int? _requiredGermanLevel(String jobText) {
  final text = normalizeText(jobText);
  if (!RegExp(r'\b(deutsch|german)\w*\b').hasMatch(text)) return null;
  final explicit = RegExp(
    r'(?:deutsch\w*|german)\s*(?:auf\s*)?(a1|a2|b1|b2|c1|c2)|\b(a1|a2|b1|b2|c1|c2)\b\s*(?:deutsch\w*|german)',
  ).firstMatch(text);
  final level = explicit?.group(1) ?? explicit?.group(2);
  if (level != null) return _levelValue(level);
  if (text.contains('verhandlungssicher') ||
      text.contains('fliessend') ||
      text.contains('fluent')) {
    return 5;
  }
  if (text.contains('sehr gut') || text.contains('gute deutsch')) return 4;
  if (text.contains('grundkennt') || text.contains('basic german')) return 2;
  return 3;
}

int? _profileGermanLevel(UserProfileData profile) {
  final candidates = <String>[
    if (profile.preferences['german_level'] is String)
      profile.preferences['german_level'] as String,
    ...profile.skills.where((skill) {
      final value = normalizeText(skill);
      return value.contains('deutsch') || value.contains('german');
    }),
  ];
  final levels = candidates.map(_levelFromText).whereType<int>().toList();
  // A CEFR level the CV analysis only inferred or found unclear is a
  // weaker signal than one written verbatim in the CV, or one the student
  // entered directly as a skill/preference -- discount it by one notch
  // instead of trusting it exactly as much as a stated level.
  for (final item in _analysisItems(profile.cvAnalysis['languages'])) {
    final language = normalizeText(item['language']?.toString() ?? '');
    if (!language.contains('deutsch') && !language.contains('german')) {
      continue;
    }
    final level = _levelFromText(item['level']?.toString() ?? '');
    if (level == null) continue;
    final confidence = item['confidence']?.toString();
    levels.add(
      confidence == 'inferred' || confidence == 'unclear'
          ? (level - 1).clamp(1, 6)
          : level,
    );
  }
  if (levels.isEmpty) return null;
  return levels.reduce((a, b) => a > b ? a : b);
}

int _levelFit(int? profileLevel, int requiredLevel) {
  if (profileLevel == null) return 0;
  final difference = requiredLevel - profileLevel;
  if (difference <= 0) return 100;
  if (difference == 1) return 70;
  if (difference == 2) return 35;
  return 10;
}

int? _levelFromText(String value) {
  final match = RegExp(
    r'\b(a1|a2|b1|b2|c1|c2)\b',
  ).firstMatch(normalizeText(value));
  return match == null ? null : _levelValue(match.group(1)!);
}

int _levelValue(String value) => switch (value.toLowerCase()) {
  'a1' => 1,
  'a2' => 2,
  'b1' => 3,
  'b2' => 4,
  'c1' => 5,
  'c2' => 6,
  _ => 0,
};

String _levelName(int? level, String unknown) => switch (level) {
  1 => 'A1',
  2 => 'A2',
  3 => 'B1',
  4 => 'B2',
  5 => 'C1',
  6 => 'C2',
  _ => unknown,
};

String? _educationRequirement(String jobText) {
  final text = normalizeText(jobText);
  if (RegExp(r'\bmaster\b').hasMatch(text)) return 'master';
  if (RegExp(r'\bbachelor\b').hasMatch(text)) return 'bachelor';
  if (text.contains('immatrikul') ||
      text.contains('eingeschrieb') ||
      text.contains('studium') ||
      text.contains('university student') ||
      text.contains('werkstudent')) {
    return 'student';
  }
  return null;
}

int _educationFit(
  UserProfileData profile,
  String requirement,
  bool hasEducation,
) {
  if (!hasEducation) return 0;
  final text = normalizeText(
    [
      profile.degree,
      ..._analysisItems(profile.cvAnalysis['education'])
          .expand((item) => [item['degree'], item['institution']])
          .whereType<String>(),
    ].join(' '),
  );
  if (requirement == 'master') {
    return text.contains('master')
        ? 100
        : text.contains('bachelor')
        ? 60
        : 45;
  }
  if (requirement == 'bachelor') {
    return text.contains('master') || text.contains('bachelor') ? 100 : 70;
  }
  return 100;
}

int? _experienceRequirement(String jobText) {
  final text = normalizeText(jobText);
  final years = RegExp(
    r'(\d{1,2})\+?\s*(?:jahre|years|ans)\s+(?:berufs)?erfahrung',
  ).firstMatch(text);
  if (years != null) return (int.tryParse(years.group(1) ?? '') ?? 0) * 12;
  if (text.contains('erste erfahrung') ||
      text.contains('first experience') ||
      text.contains('premiere experience')) {
    return 3;
  }
  return null;
}

int _estimatedExperienceMonths(UserProfileData profile, DateTime now) {
  var total = 0;
  final experiences = _analysisItems(profile.cvAnalysis['experiences']);
  for (final item in experiences) {
    final period = normalizeText(item['period']?.toString() ?? '');
    final years = RegExp(r'(20\d{2}).*?(20\d{2})').firstMatch(period);
    if (years != null) {
      final start = int.tryParse(years.group(1) ?? '');
      final end = int.tryParse(years.group(2) ?? '');
      if (start != null && end != null && end >= start) {
        total += (end - start + 1) * 12;
        continue;
      }
    }
    final startOnly = RegExp(r'(20\d{2})').firstMatch(period);
    if (startOnly != null &&
        (period.contains('heute') ||
            period.contains('present') ||
            period.contains('actuel'))) {
      final start = int.tryParse(startOnly.group(1) ?? '');
      if (start != null && now.year >= start) {
        total += (now.year - start) * 12 + now.month;
        continue;
      }
    }
    total += 6;
  }
  if (total == 0 &&
      normalizeText(profile.professionalSummary).contains('experience')) {
    return 3;
  }
  return total;
}

int _experienceFit(int requiredMonths, int profileMonths) {
  if (profileMonths <= 0) return 0;
  if (requiredMonths <= 3) return 100;
  return ((profileMonths / requiredMonths) * 100).round().clamp(0, 100);
}

/// Keywords that identify which professional field a job posting belongs to,
/// keyed by the same canonical field names used throughout the app (job
/// search preferences, CV versions). Shared so every place that needs "does
/// this job text belong to field X" uses one definition instead of drifting
/// copies.
const domainKeywords = <String, List<String>>{
  'Informatique': [
    'informatik',
    'software',
    'developer',
    'entwicklung',
    'flutter',
    'java',
  ],
  'Data & IA': [
    'data',
    'analytics',
    'machine learning',
    'kunstliche intelligenz',
    'python',
    'sql',
  ],
  'Ingénierie': ['ingenieur', 'engineering', 'technik', 'elektro', 'maschinenbau'],
  'Business & Finance': [
    'business',
    'finance',
    'controlling',
    'consulting',
    'wirtschaft',
  ],
  'Marketing & Design': [
    'marketing',
    'design',
    'content',
    'communication',
    'ux',
  ],
};

int? _fieldPreferenceScore(Object? rawFields, String jobText) {
  if (rawFields is! List || rawFields.isEmpty) return null;
  if (rawFields.whereType<String>().contains('Tous domaines')) return null;
  final normalizedJob = normalizeText(jobText);
  for (final field in rawFields.whereType<String>()) {
    if ((domainKeywords[field] ?? const []).any(normalizedJob.contains)) {
      return 100;
    }
  }
  return 15;
}

int _weeklyHoursFit(Object? rawPreference, String jobText) {
  if (rawPreference is! String || rawPreference.isEmpty) return 70;
  final match = RegExp(
    r'(\d{1,2})(?:\s*[-–]\s*(\d{1,2}))?\s*(?:h|stunden)',
  ).firstMatch(normalizeText(jobText));
  if (match == null) return 70;
  final jobMin = int.tryParse(match.group(1) ?? '') ?? 0;
  final jobMax = int.tryParse(match.group(2) ?? '') ?? jobMin;
  final preferred = switch (rawPreference) {
    '10–15 h' => (10, 15),
    '16–20 h' => (16, 20),
    'Plus de 20 h' => (21, 40),
    _ => (0, 40),
  };
  final overlaps = jobMin <= preferred.$2 && jobMax >= preferred.$1;
  return overlaps ? 100 : 25;
}

bool _skillMatches(String profileSkill, String jobSkill) {
  final profileValue = _canonicalSkill(profileSkill);
  final jobValue = _canonicalSkill(jobSkill);
  if (profileValue.isEmpty || jobValue.isEmpty) return false;
  return profileValue == jobValue ||
      profileValue.contains(jobValue) ||
      jobValue.contains(profileValue);
}

String _canonicalSkill(String value) {
  final normalized = normalizeText(value);
  for (final entry in _skillAliases.entries) {
    if (entry.value.any((alias) => normalized == alias)) {
      return normalizeText(entry.key);
    }
  }
  for (final entry in _skillAliases.entries) {
    if (entry.value.any((alias) => normalized.contains(alias))) {
      return normalizeText(entry.key);
    }
  }
  return normalized;
}

int _careerFitScore({
  required String profileText,
  required String jobTitle,
  required List<String> jobTags,
  required String jobDescription,
}) {
  final profileDomains = _careerDomains(profileText);
  if (profileDomains.isEmpty) return 50;

  // The title and structured tags describe the role more reliably than a
  // company introduction in the body of the advert.
  final roleDomains = _careerDomains('$jobTitle ${jobTags.join(' ')}');
  if (roleDomains.isNotEmpty) {
    final overlap = profileDomains.intersection(roleDomains);
    if (overlap.isNotEmpty) {
      return (82 + (overlap.length - 1) * 9).clamp(0, 100);
    }
    return 8;
  }

  final descriptionDomains = _careerDomains(jobDescription);
  if (descriptionDomains.isEmpty) return 35;
  final overlap = profileDomains.intersection(descriptionDomains);
  if (overlap.isNotEmpty) {
    return (68 + (overlap.length - 1) * 8).clamp(0, 92);
  }
  return 18;
}

Set<String> _careerDomains(String input) {
  final text = normalizeText(input);
  final result = <String>{};

  bool containsAny(Iterable<String> terms) => terms.any(text.contains);

  if (containsAny(const [
    'software',
    'softwareentwicklung',
    'anwendungsentwicklung',
    'webentwicklung',
    'app-entwicklung',
    'backend',
    'frontend',
    'fullstack',
    'developer',
    'informatik',
    'programmierung',
    'python',
    'java',
    'typescript',
    'javascript',
    'node.js',
    'nodejs',
    'html',
    'css',
    'docker',
    'kubernetes',
    'linux',
  ])) {
    result.add('software');
  }
  if (containsAny(const [
    'data engineering',
    'data engineer',
    'datenanalyse',
    'data analysis',
    'analytics',
    'machine learning',
    'kunstliche intelligenz',
    'artificial intelligence',
    'python',
    'pandas',
    'numpy',
    'matplotlib',
    'sql',
    'postgresql',
    'mysql',
  ])) {
    result.add('data');
  }
  if (containsAny(const [
    'fpga',
    'verilog',
    'vivado',
    'embedded',
    'firmware',
    'hardware',
    'elektrotechnik',
    'electronics',
  ])) {
    result.add('hardware');
  }
  if (containsAny(const [
    'maschinenbau',
    'bauingenieur',
    'construction',
    'montageplanung',
    'fahrzeugtechnik',
    'batteriesystem',
  ])) {
    result.add('engineering');
  }
  if (containsAny(const [
    'finance',
    'accounting',
    'controlling',
    'kaufmann',
    'kaufm.',
    'betriebswirt',
    'buchhaltung',
  ])) {
    result.add('finance');
  }
  if (containsAny(const [
    'kundenservice',
    'customer service',
    'sales',
    'vertrieb',
    'verkauf',
    'outbound',
  ])) {
    result.add('sales');
  }
  if (containsAny(const [
    'marketing',
    'kommunikation',
    'redaktion',
    'social media',
    'content',
  ])) {
    result.add('marketing');
  }
  if (containsAny(const ['legal', 'recht', 'law', 'jurist'])) {
    result.add('legal');
  }
  if (containsAny(const [
    'human resources',
    'personalwesen',
    'recruiting',
    'talent acquisition',
  ])) {
    result.add('hr');
  }
  return result;
}

List<Map<String, dynamic>> _analysisItems(Object? value) =>
    (value as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

Set<String> _tokens(String input) => normalizeText(input)
    .split(RegExp(r'[^a-z0-9+#]+'))
    .where((token) => token.length >= 3 && !_stopWords.contains(token))
    .map(_canonicalToken)
    .toSet();

String _canonicalToken(String token) => switch (token) {
  'informatiker' || 'informatikerin' || 'informatik' => 'informatik',
  'entwickler' ||
  'entwicklerin' ||
  'developer' ||
  'development' => 'entwicklung',
  'analyse' || 'analytics' || 'analyst' => 'analyse',
  'german' || 'allemand' || 'deutsch' => 'deutsch',
  'english' || 'anglais' || 'englisch' => 'englisch',
  _ => token,
};

String normalizeText(String input) => input
    .trim()
    .toLowerCase()
    .replaceAll('ä', 'a')
    .replaceAll('ö', 'o')
    .replaceAll('ü', 'u')
    .replaceAll('ß', 'ss')
    .replaceAll('é', 'e')
    .replaceAll('è', 'e')
    .replaceAll('ê', 'e')
    .replaceAll('à', 'a')
    .replaceAll('â', 'a')
    .replaceAll('ç', 'c')
    .replaceAll('ä', 'a')
    .replaceAll('ö', 'o')
    .replaceAll('ü', 'u')
    .replaceAll('ß', 'ss')
    .replaceAll('é', 'e')
    .replaceAll('è', 'e')
    .replaceAll('ê', 'e')
    .replaceAll('à', 'a')
    .replaceAll('â', 'a')
    .replaceAll('ç', 'c');

const _genericJobTags = <String>{
  'informatiker/in',
  'informatiker',
  'werkstudent',
  'working student',
  'student',
  'engineering',
  'it',
  'unknown',
  'operations',
  'software',
  'finance',
  'sales',
  'legal',
  'customer service',
  'sonstige/allgemeine stellen',
};

const _skillAliases = <String, List<String>>{
  'Flutter': ['flutter'],
  'Dart': ['dart'],
  'Python': ['python'],
  'Java': ['java'],
  'Kotlin': ['kotlin'],
  'Swift': ['swift'],
  'SQL': ['sql'],
  'JavaScript': ['javascript'],
  'TypeScript': ['typescript'],
  'React': ['react'],
  'Angular': ['angular'],
  'Vue': ['vue.js', 'vuejs'],
  'AWS': ['aws', 'amazon web services'],
  'Azure': ['azure'],
  'Google Cloud': ['gcp', 'google cloud'],
  'Git': ['git'],
  'Docker': ['docker'],
  'Kubernetes': ['kubernetes'],
  'Figma': ['figma'],
  'Excel': ['excel'],
  'SAP': ['sap'],
  'Power BI': ['power bi', 'powerbi'],
  'Tableau': ['tableau'],
  'REST API': ['rest api', 'restful'],
  'Machine Learning': ['machine learning', 'ml'],
  'Data Analysis': ['data analysis', 'datenanalyse', 'analytics'],
  'C++': ['c++'],
  'C#': ['c#'],
  'Linux': ['linux'],
  'HTML/CSS': ['html/css', 'html', 'css'],
  'Node.js': ['node.js', 'nodejs'],
  'MySQL': ['mysql'],
  'PostgreSQL': ['postgresql', 'postgres'],
  'Pandas': ['pandas'],
  'NumPy': ['numpy'],
  'Matplotlib': ['matplotlib'],
  'GitHub': ['github'],
  'GitLab': ['gitlab'],
  'Scrum': ['scrum'],
  'FPGA': ['fpga'],
  'Verilog': ['verilog'],
  'Vivado': ['vivado'],
  'Salesforce': ['salesforce'],
  'MATLAB': ['matlab'],
  'CAD': ['cad', 'autocad'],
};

const _stopWords = <String>{
  'and',
  'avec',
  'der',
  'des',
  'die',
  'eine',
  'einer',
  'for',
  'fur',
  'les',
  'mit',
  'oder',
  'pour',
  'the',
  'und',
  'von',
  'werkstudent',
  'working',
  'student',
};
