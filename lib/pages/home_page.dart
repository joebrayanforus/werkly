import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_page.dart';
import '../data/werkly_repository.dart';
import '../l10n/app_language.dart';
import 'privacy_page.dart';
import '../services/application_kit_service.dart';
import '../services/commute_service.dart';
import '../services/compatibility_service.dart';
import '../services/german_city_service.dart';
import '../services/interview_prep_service.dart';
import '../services/job_description_formatter.dart';
import '../services/notification_service.dart';
import '../services/saved_search_service.dart';

part 'home/navigation.dart';
part 'home/shared_widgets.dart';
part 'home/dashboard_view.dart';
part 'home/onboarding.dart';
part 'home/jobs_view.dart';
part 'home/application_prep_sheet.dart';
part 'home/map_view.dart';
part 'home/applications_view.dart';
part 'home/profile_view.dart';
part 'home/cv_analysis.dart';
part 'home/admin_moderation_sheet.dart';
part 'home/account_settings.dart';
part 'home/interview_prep_sheet.dart';
part 'home/assistant_sheet.dart';
part 'home/employer_job_form.dart';

const _ink = Color(0xFF17231F);
const _green = Color(0xFF2F6B55);
const _mint = Color(0xFFDDEDE4);
const _orange = Color(0xFFE9A95B);
const _line = Color(0xFFE7EAE4);
const _muted = Color(0xFF718079);
const _cream = Color(0xFFF7F7F2);

bool _isGuestProfileName(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.isEmpty ||
      const {
        'profil invité',
        'gastprofil',
        'guest profile',
      }.contains(normalized);
}

String _applicationLetter({
  required Job job,
  required UserProfileData profile,
  required AppLanguage language,
}) {
  final strings = AppStrings(language);
  final name = _isGuestProfileName(profile.fullName)
      ? strings.get('guestApplicantName')
      : profile.fullName.trim();
  final matchingSkills = job.tags
      .where(
        (tag) => profile.skills.any(
          (skill) =>
              skill.toLowerCase().contains(tag.toLowerCase()) ||
              tag.toLowerCase().contains(skill.toLowerCase()),
        ),
      )
      .toList();
  // Without a real match, fall back to the job's own tags -- but skip
  // boilerplate ones ("Werkstudent", "IT"...) so the letter never claims
  // a generic label as if it were an actual skill.
  final fallbackSkills = job.tags
      .where((tag) => !isGenericJobTag(tag))
      .toList();
  final skillValues = matchingSkills.isEmpty
      ? fallbackSkills.take(2).toList()
      : matchingSkills.take(3).toList();
  final skills = skillValues.isEmpty
      ? strings.get('interviewRoleSkillsFallback')
      : skillValues.join(', ');
  final degree = profile.degree.trim();
  final university = profile.university.trim();

  return switch (language) {
    AppLanguage.fr =>
      '''Madame, Monsieur,

C’est avec grand intérêt que je vous adresse ma candidature au poste de ${job.title} chez ${job.company}. ${degree.isEmpty && university.isEmpty ? 'Mon profil associe une forte capacité d’apprentissage à une expérience pratique en projet.' : 'Je poursuis actuellement ${degree.isEmpty ? 'mes études' : degree}${university.isEmpty ? '' : ' à $university'}.'}

Je souhaite mettre à profit mes compétences en $skills au sein de votre équipe tout en continuant à progresser. ${profile.professionalSummary.trim().isEmpty ? 'Je travaille de manière structurée, fiable et collaborative.' : profile.professionalSummary.trim()}

Je serais heureux de pouvoir vous présenter plus précisément ma motivation lors d’un entretien.

Cordialement,
$name''',
    AppLanguage.de =>
      '''Sehr geehrte Damen und Herren,

mit großem Interesse bewerbe ich mich als ${job.title} bei ${job.company}. ${degree.isEmpty && university.isEmpty ? 'Mein Profil verbindet Lernbereitschaft mit praktischer Projektarbeit.' : 'Aktuell studiere ich ${degree.isEmpty ? 'an einer Hochschule' : degree}${university.isEmpty ? '' : ' an der $university'}.'}

Meine Kenntnisse in $skills möchte ich in Ihrem Team gezielt einsetzen und weiterentwickeln. ${profile.professionalSummary.trim().isEmpty ? 'Ich arbeite strukturiert, zuverlässig und gerne im Team.' : profile.professionalSummary.trim()}

Gerne überzeuge ich Sie in einem persönlichen Gespräch von meiner Motivation.

Mit freundlichen Grüßen
$name''',
    AppLanguage.en =>
      '''Dear Hiring Team,

I am pleased to apply for the ${job.title} position at ${job.company}. ${degree.isEmpty && university.isEmpty ? 'My profile combines a strong willingness to learn with practical project experience.' : 'I am currently studying ${degree.isEmpty ? 'at university' : degree}${university.isEmpty ? '' : ' at $university'}.'}

I would welcome the opportunity to contribute my skills in $skills while continuing to learn from your team. ${profile.professionalSummary.trim().isEmpty ? 'I work in a structured, reliable and collaborative way.' : profile.professionalSummary.trim()}

I would be happy to discuss my motivation and experience in an interview.

Kind regards,
$name''',
  };
}

/// The job context sent to the AI assistant for a selected job -- shared so
/// every caller (the assistant chat, the dedicated AI letter button) sends
/// the exact same shape.
Map<String, dynamic> jobAiContext(Job job) => {
  'title': job.title,
  'company': job.company,
  'location': job.location,
  'tags': job.tags,
  'description': job.description,
};

Future<bool?> askAiConsent(BuildContext context) => showDialog<bool>(
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

double _distanceBetweenKm(
  double latitudeA,
  double longitudeA,
  double latitudeB,
  double longitudeB,
) {
  const earthRadiusKm = 6371.0;
  double radians(double value) => value * math.pi / 180;
  final latitudeDelta = radians(latitudeB - latitudeA);
  final longitudeDelta = radians(longitudeB - longitudeA);
  final a =
      math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
      math.cos(radians(latitudeA)) *
          math.cos(radians(latitudeB)) *
          math.sin(longitudeDelta / 2) *
          math.sin(longitudeDelta / 2);
  return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

enum _OnboardingAction { preferences, cv, explore }

class _OnboardingPreferences {
  const _OnboardingPreferences({
    required this.city,
    required this.fields,
    required this.workMode,
    required this.weeklyHours,
    required this.germanLevel,
    required this.searchRadius,
    this.cityLatitude,
    this.cityLongitude,
    this.locationSource = 'manual',
  });

  final String city;
  final List<String> fields;
  final String workMode;
  final String weeklyHours;
  final String germanLevel;
  final int searchRadius;
  final double? cityLatitude;
  final double? cityLongitude;
  final String locationSource;
}

class Job {
  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.match,
    required this.commute,
    required this.salary,
    required this.source,
    required this.sourceUrl,
    required this.latitude,
    required this.longitude,
    required this.color,
    required this.tags,
    required this.description,
    required this.posted,
    this.postedAt,
    this.hourlyMin,
    this.remote = false,
    this.remoteType = 'onsite',
    this.routeUrl,
    this.compatibility = const CompatibilityBreakdown.unscored(),
  });

  final int id;
  final String title;
  final String company;
  final String location;
  final int match;
  final String commute;
  final String salary;
  final String source;
  final String sourceUrl;
  final double latitude;
  final double longitude;
  final Color color;
  final List<String> tags;
  final String description;
  final String posted;
  final DateTime? postedAt;
  final double? hourlyMin;
  final bool remote;
  final String remoteType;
  final Uri? routeUrl;
  final CompatibilityBreakdown compatibility;
}

enum JobSortOption { match, newest, salary }

String jobSortLabel(JobSortOption option) => switch (option) {
  JobSortOption.match => 'Meilleure compatibilité',
  JobSortOption.newest => 'Plus récentes',
  JobSortOption.salary => 'Salaire le plus élevé',
};

String _localizedJobSortLabel(BuildContext context, JobSortOption option) =>
    context.tr(switch (option) {
      JobSortOption.match => 'sortMatch',
      JobSortOption.newest => 'sortNewest',
      JobSortOption.salary => 'sortSalary',
    });

String _localizedFilterLabel(BuildContext context, String value) =>
    context.tr(switch (value) {
      'Nouvelles' => 'newFilter',
      'Remote' => 'remoteFilter',
      'Sauvegardées' => 'savedFilter',
      _ => 'forYou',
    });

String _localizedPreferenceValue(BuildContext context, String value) {
  final language = AppLanguageController.language.value;
  if (language == AppLanguage.fr) return value;
  const german = <String, String>{
    'Tous domaines': 'Alle Bereiche',
    'Informatique': 'Informatik',
    'Ingénierie': 'Ingenieurwesen',
    'Business & Finance': 'Wirtschaft & Finanzen',
    'Marketing & Design': 'Marketing & Design',
    'Hybride': 'Hybrid',
    'Télétravail': 'Remote',
    'Sur site': 'Vor Ort',
    'Plus de 20 h': 'Mehr als 20 Std.',
    'Non précisé': 'Nicht angegeben',
  };
  const english = <String, String>{
    'Tous domaines': 'All fields',
    'Informatique': 'Computer science',
    'Ingénierie': 'Engineering',
    'Business & Finance': 'Business & Finance',
    'Marketing & Design': 'Marketing & Design',
    'Hybride': 'Hybrid',
    'Télétravail': 'Remote',
    'Sur site': 'On site',
    'Plus de 20 h': 'More than 20 h',
    'Non précisé': 'Not specified',
  };
  return (language == AppLanguage.de ? german : english)[value] ?? value;
}

String _localizedPosted(BuildContext context, Job job) {
  final postedAt = job.postedAt;
  if (postedAt == null) return job.posted;
  final difference = DateTime.now().toUtc().difference(postedAt.toUtc());
  if (difference.inHours < 1) return context.tr('postedToday');
  if (difference.inHours < 24) {
    return context.trFormat('postedHours', {'count': difference.inHours});
  }
  if (difference.inDays == 1) return context.tr('postedYesterday');
  return context.trFormat('postedDays', {'count': difference.inDays});
}

List<Job> sortJobsForDisplay(Iterable<Job> jobs, JobSortOption option) {
  final result = jobs.toList();
  int comparePostedAt(Job a, Job b) {
    final aValue = a.postedAt?.millisecondsSinceEpoch ?? -1;
    final bValue = b.postedAt?.millisecondsSinceEpoch ?? -1;
    return bValue.compareTo(aValue);
  }

  result.sort(switch (option) {
    JobSortOption.match => (a, b) {
      final byMatch = b.match.compareTo(a.match);
      return byMatch != 0 ? byMatch : comparePostedAt(a, b);
    },
    JobSortOption.newest => comparePostedAt,
    JobSortOption.salary => (a, b) {
      final bySalary = (b.hourlyMin ?? -1).compareTo(a.hourlyMin ?? -1);
      return bySalary != 0 ? bySalary : b.match.compareTo(a.match);
    },
  });
  return result;
}

/// The job details are embedded only in the wide, two-column Jobs view.
///
/// Other pages do not render that panel, so their job cards open the details
/// in a sheet to make every click immediately visible.
///
/// This is the single source of truth for that breakpoint: both the Jobs
/// view (deciding whether to render the embedded panel) and the tap handler
/// (deciding whether to open the sheet) call [usesEmbeddedJobDetails] so a
/// selected card always opens something visible.
const jobsEmbeddedDetailMinimumViewportWidth = 1360.0;

bool usesEmbeddedJobDetails({
  required int pageIndex,
  required double viewportWidth,
}) =>
    pageIndex == 1 &&
    viewportWidth >= jobsEmbeddedDetailMinimumViewportWidth;

int _storedSearchRadius(UserProfileData profile) {
  final value = (profile.preferences['search_radius'] as num?)?.round() ?? 25;
  return value.clamp(5, 100);
}

bool _skillMatches(String profileSkill, String jobSkill) {
  final profileValue = profileSkill.trim().toLowerCase();
  final jobValue = jobSkill.trim().toLowerCase();
  if (profileValue.isEmpty || jobValue.isEmpty) return false;
  return profileValue.contains(jobValue) || jobValue.contains(profileValue);
}

List<String> matchedJobSkills(Job job, Iterable<String> profileSkills) => job
    .tags
    .where((tag) => profileSkills.any((skill) => _skillMatches(skill, tag)))
    .toSet()
    .toList();

List<String> missingJobSkills(Job job, Iterable<String> profileSkills) => job
    .tags
    .where((tag) => !profileSkills.any((skill) => _skillMatches(skill, tag)))
    .toSet()
    .toList();

/// How trustworthy a job listing's source is, mirroring the priority order
/// `sync-free-jobs` already uses internally (direct employer feeds > the
/// federal job board > aggregators) plus Werkly's own admin-verified
/// employer submissions.
enum SourceTrust { officialEmployer, officialBoard, verifiedSubmission, aggregator }

SourceTrust jobSourceTrust(String source) {
  if (source == 'Entreprise vérifiée') return SourceTrust.verifiedSubmission;
  if (source == 'Bundesagentur für Arbeit') return SourceTrust.officialBoard;
  if (source.startsWith('Greenhouse · ') ||
      source.startsWith('Lever · ') ||
      source == 'SmartRecruiters') {
    return SourceTrust.officialEmployer;
  }
  return SourceTrust.aggregator;
}

String _localizedSourceTrust(BuildContext context, SourceTrust trust) =>
    context.tr(switch (trust) {
      SourceTrust.officialEmployer => 'sourceOfficialEmployer',
      SourceTrust.officialBoard => 'sourceOfficialBoard',
      SourceTrust.verifiedSubmission => 'sourceVerifiedSubmission',
      SourceTrust.aggregator => 'sourceAggregator',
    });

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repository = WerklyRepository();
  final _commuteService = CommuteService();
  final _savedSearchService = const SavedSearchService();
  final Map<int, CommuteEstimate> _commuteEstimates = {};
  List<Map<String, dynamic>> _jobRows = <Map<String, dynamic>>[];
  List<Job> _jobCatalog = <Job>[];
  int _pageIndex = 0;
  int _selectedJobId = 1;
  int _distance = 15;
  String _query = '';
  String _filter = 'Pour toi';
  final Set<int> _savedJobs = <int>{};
  final Set<int> _appliedJobs = <int>{};
  final Map<int, String> _applicationStatuses = <int, String>{};
  UserProfileData _profile = UserProfileData.guest();
  double _minimumSalary = 0;
  bool _flexibleOnly = false;
  Set<String> _selectedSources = <String>{};
  JobSortOption _jobSort = JobSortOption.match;
  bool _isLoadingWorkspace = true;
  bool _isRefreshingJobs = false;
  bool _isAnalyzingCv = false;
  String? _workspaceError;
  DateTime? _jobsUpdatedAt;
  bool _syncNoticeShown = false;
  bool _onboardingChecked = false;
  List<WerklyNotification> _notifications = const [];
  List<SavedJobSearch> _savedSearches = const [];
  bool _systemNotificationsEnabled = false;

  int get _unreadNotificationCount =>
      _notifications.where((item) => item.unread && item.isDue()).length;

  @override
  void initState() {
    super.initState();
    AppLanguageController.language.addListener(_handleLanguageChanged);
    NotificationService.instance.openedJobId.addListener(
      _handleOpenedNotification,
    );
    _loadWorkspace();
  }

  @override
  void dispose() {
    AppLanguageController.language.removeListener(_handleLanguageChanged);
    NotificationService.instance.openedJobId.removeListener(
      _handleOpenedNotification,
    );
    _commuteService.close();
    super.dispose();
  }

  void _handleLanguageChanged() {
    if (mounted) {
      setState(() => _jobCatalog = _jobRows.map(_jobFromRow).toList());
    }
  }

  void _handleOpenedNotification() {
    final jobId = NotificationService.instance.openedJobId.value;
    if (jobId == null || !mounted) return;
    NotificationService.instance.openedJobId.value = null;
    final job = _jobById(jobId);
    if (job == null) return;
    _selectPage(1);
    final selected = job;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showJob(selected);
    });
  }

  Job? _jobById(int? id) {
    if (id == null) return null;
    for (final job in _jobCatalog) {
      if (job.id == id) return job;
    }
    return null;
  }

  Future<void> _loadWorkspace({
    bool forceSync = false,
    bool announce = false,
  }) async {
    if (_isRefreshingJobs) return;
    setState(() {
      _isLoadingWorkspace = _jobCatalog.isEmpty;
      _isRefreshingJobs = forceSync;
      _workspaceError = null;
    });
    try {
      final state = await _repository.loadWorkspace(forceSync: forceSync);
      final savedSearches = await _savedSearchService.loadAll();
      if (!mounted) return;
      setState(() {
        _profile = state.profile;
        _distance = _storedSearchRadius(state.profile);
        _jobRows = state.jobs;
        _jobCatalog = _jobRows.map(_jobFromRow).toList();
        _savedSearches = savedSearches;
        if (_jobCatalog.isNotEmpty) {
          if (!_jobCatalog.any((job) => job.id == _selectedJobId)) {
            _selectedJobId = _jobCatalog.first.id;
          }
        }
        _savedJobs
          ..clear()
          ..addAll(state.favoriteJobIds);
        _appliedJobs
          ..clear()
          ..addAll(state.applications.keys);
        _applicationStatuses
          ..clear()
          ..addAll(state.applications);
        _jobsUpdatedAt = DateTime.now();
        _isLoadingWorkspace = false;
        _isRefreshingJobs = false;
      });
      if (announce && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.trFormat('jobsUpdatedToast', {
                'count': _jobCatalog.length,
              }),
            ),
          ),
        );
      }
      await _refreshNotifications(scanJobs: true);
      _refreshCommutes();
      if (!_onboardingChecked) {
        _onboardingChecked = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _maybeShowOnboarding();
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingWorkspace = false;
        _isRefreshingJobs = false;
        _workspaceError = context.tr('jobsLoadFailed');
      });
      if (announce) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('jobsUpdateFailed'))));
      }
    }
  }

  Future<void> _refreshNotifications({bool scanJobs = false}) async {
    final service = NotificationService.instance;
    final alertJobs = _savedSearches.isEmpty
        ? _jobCatalog
        : _jobCatalog
              .where(
                (job) => _savedSearches.any(
                  (search) => _jobMatchesSavedSearch(job, search),
                ),
              )
              .toList();
    final items = scanJobs
        ? await service.syncNewJobAlerts(
            alertJobs
                .map(
                  (job) => JobAlertCandidate(
                    id: job.id,
                    title: job.title,
                    company: job.company,
                    match: job.match,
                    postedAt: job.postedAt,
                  ),
                )
                .toList(),
          )
        : await service.load();
    final enabled = await service.systemNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _notifications = items;
      _systemNotificationsEnabled = enabled;
    });
  }

  bool _jobMatchesSavedSearch(Job job, SavedJobSearch search) {
    final query = search.query.trim().toLowerCase();
    final queryMatches =
        query.isEmpty ||
        job.title.toLowerCase().contains(query) ||
        job.company.toLowerCase().contains(query) ||
        job.tags.any((tag) => tag.toLowerCase().contains(query));
    final filterMatches = switch (search.filter) {
      'Remote' => job.remoteType == 'remote' || job.remoteType == 'hybrid',
      'Nouvelles' =>
        job.postedAt != null &&
            DateTime.now().toUtc().difference(job.postedAt!.toUtc()).inDays <=
                7,
      'Sauvegardées' => _savedJobs.contains(job.id),
      _ => true,
    };
    final salaryMatches =
        search.minimumSalary <= 0 ||
        (job.hourlyMin != null && job.hourlyMin! >= search.minimumSalary);
    final flexibleMatches = !search.flexibleOnly || job.remote;
    final sourceMatches =
        search.sources.isEmpty || search.sources.contains(job.source);
    final city = GermanCityService.exact(search.city);
    final distanceMatches =
        city == null ||
        job.remoteType == 'remote' ||
        _distanceBetweenKm(
              city.latitude,
              city.longitude,
              job.latitude,
              job.longitude,
            ) <=
            search.radiusKm;
    return queryMatches &&
        filterMatches &&
        salaryMatches &&
        flexibleMatches &&
        sourceMatches &&
        distanceMatches;
  }

  Future<void> _refreshCommutes() async {
    if (_jobRows.isEmpty) return;
    final center = _searchCenter;
    final candidates = _jobRows
        .where((row) {
          final latitude = (row['latitude'] as num?)?.toDouble();
          final longitude = (row['longitude'] as num?)?.toDouble();
          final remoteType = row['remote_type'] as String? ?? 'onsite';
          return latitude != null &&
              longitude != null &&
              remoteType != 'remote' &&
              !_commuteEstimates.containsKey((row['id'] as num).toInt());
        })
        .take(12)
        .toList();
    for (var offset = 0; offset < candidates.length; offset += 3) {
      final chunk = candidates.skip(offset).take(3);
      final results = await Future.wait(
        chunk.map((row) async {
          final id = (row['id'] as num).toInt();
          final estimate = await _commuteService.estimate(
            fromLatitude: center.latitude,
            fromLongitude: center.longitude,
            toLatitude: (row['latitude'] as num).toDouble(),
            toLongitude: (row['longitude'] as num).toDouble(),
          );
          return (id, estimate);
        }),
      );
      if (!mounted) return;
      var changed = false;
      for (final result in results) {
        if (result.$2 != null) {
          _commuteEstimates[result.$1] = result.$2!;
          changed = true;
        }
      }
      if (changed) {
        setState(() => _jobCatalog = _jobRows.map(_jobFromRow).toList());
      }
    }
  }

  Future<void> _maybeShowOnboarding() async {
    final tutorialComplete = await _repository.isTutorialComplete();
    if (!tutorialComplete && mounted) {
      final completed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => const _FirstRunTutorialSheet(),
      );
      if (completed == true) {
        await _repository.setTutorialComplete(true);
      } else {
        return;
      }
    }
    final localComplete = await _repository.isOnboardingComplete();
    final profileComplete =
        _profile.preferences['onboarding_completed'] == true;
    if (localComplete || profileComplete || !mounted) return;
    final action = await showModalBottomSheet<_OnboardingAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _OnboardingWelcomeSheet(),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _OnboardingAction.preferences:
        final preferences = await showModalBottomSheet<_OnboardingPreferences>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _QuickPreferencesSheet(profile: _profile),
        );
        if (preferences != null) {
          await _saveOnboardingPreferences(preferences);
        }
        break;
      case _OnboardingAction.cv:
        await _uploadCv();
        if (_profile.cvPath != null) await _completeOnboarding();
        break;
      case _OnboardingAction.explore:
        await _completeOnboarding();
        break;
    }
  }

  Future<void> _saveOnboardingPreferences(
    _OnboardingPreferences selection,
  ) async {
    final skills = [..._profile.skills];
    if (selection.germanLevel != 'Non précisé') {
      skills.removeWhere((skill) => skill.toLowerCase().startsWith('deutsch'));
      skills.add('Deutsch ${selection.germanLevel}');
    }
    final updated = _profile.copyWith(
      city: selection.city,
      skills: skills.toSet().toList(),
      preferences: {
        ..._profile.preferences,
        'fields': selection.fields,
        'work_mode': selection.workMode,
        'remote': selection.workMode != 'Sur site',
        'weekly_hours': selection.weeklyHours,
        'german_level': selection.germanLevel,
        'search_radius': selection.searchRadius,
        'city_latitude': selection.cityLatitude,
        'city_longitude': selection.cityLongitude,
        'location_source': selection.locationSource,
        'onboarding_completed': true,
      },
      profileCompletion: math.max(_profile.profileCompletion, 45),
    );
    try {
      final saved = await _repository.saveProfile(updated);
      await _repository.setOnboardingComplete(true);
      if (!mounted) return;
      setState(() {
        _profile = saved;
        _distance = selection.searchRadius;
      });
      await _loadWorkspace();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('preferencesSaved'))));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.trFormat('preferencesSaveFailed', {'error': error}),
            ),
          ),
        );
      }
    }
  }

  Future<void> _editPreferences() async {
    final preferences = await showModalBottomSheet<_OnboardingPreferences>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickPreferencesSheet(profile: _profile),
    );
    if (preferences != null) {
      await _saveOnboardingPreferences(preferences);
    }
  }

  Future<void> _completeOnboarding() async {
    final updated = _profile.copyWith(
      preferences: {..._profile.preferences, 'onboarding_completed': true},
    );
    try {
      final saved = await _repository.saveProfile(updated);
      await _repository.setOnboardingComplete(true);
      if (mounted) setState(() => _profile = saved);
    } catch (_) {
      await _repository.setOnboardingComplete(true);
    }
  }

  Future<void> _replayTutorial() async {
    await _repository.setTutorialComplete(false);
    if (mounted) await _maybeShowOnboarding();
  }

  List<Job> get _visibleJobs {
    final normalized = _query.trim().toLowerCase();
    final filtered = _jobCatalog.where((job) {
      final searchMatch =
          normalized.isEmpty ||
          job.title.toLowerCase().contains(normalized) ||
          job.company.toLowerCase().contains(normalized) ||
          job.location.toLowerCase().contains(normalized) ||
          job.tags.any((tag) => tag.toLowerCase().contains(normalized));
      final filterMatch = switch (_filter) {
        'Remote' => job.remote,
        'Nouvelles' =>
          job.postedAt != null &&
              DateTime.now().toUtc().difference(job.postedAt!.toUtc()).inDays <=
                  7,
        'Sauvegardées' => _savedJobs.contains(job.id),
        _ => true,
      };
      final salaryMatch = (job.hourlyMin ?? 0) >= _minimumSalary;
      final flexibleMatch = !_flexibleOnly || job.remote;
      final sourceMatch =
          _selectedSources.isEmpty || _selectedSources.contains(job.source);
      return searchMatch &&
          filterMatch &&
          salaryMatch &&
          flexibleMatch &&
          sourceMatch;
    });
    return sortJobsForDisplay(filtered, _jobSort);
  }

  Job get _selectedJob => _jobCatalog.firstWhere(
    (job) => job.id == _selectedJobId,
    orElse: () => _jobCatalog.first,
  );

  Job _jobFromRow(Map<String, dynamic> row) {
    const colors = [
      Color(0xFF6E5BA7),
      Color(0xFFE16C46),
      Color(0xFF009999),
      Color(0xFF195B9B),
      Color(0xFF72A62E),
    ];
    final id = (row['id'] as num).toInt();
    final minimum = row['salary_min'] as num?;
    final maximum = row['salary_max'] as num?;
    final postedAt = DateTime.tryParse(row['posted_at'] as String? ?? '');
    final tags = List<String>.from(
      row['tags'] as List? ?? const [],
    ).map(formatExternalText).where((tag) => tag.isNotEmpty).toSet().toList();
    final remoteType = row['remote_type'] as String? ?? 'onsite';
    final remote = remoteType != 'onsite';
    final title = formatExternalText(row['title']?.toString() ?? 'Werkstudent');
    final description = formatJobDescription(
      row['description']?.toString() ?? '',
    );
    final location = formatExternalText(
      row['location']?.toString() ?? 'Allemagne',
    );
    final latitude = (row['latitude'] as num?)?.toDouble();
    final longitude = (row['longitude'] as num?)?.toDouble();
    final center = _searchCenter;
    final distanceKm = latitude == null || longitude == null
        ? null
        : _distanceBetweenKm(
            center.latitude,
            center.longitude,
            latitude,
            longitude,
          );
    final commute = _commuteEstimates[id];
    final compatibility = calculateJobCompatibility(
      profile: _profile,
      jobTags: tags,
      jobTitle: title,
      jobDescription: description,
      jobLocation: location,
      remote: remote,
      remoteType: remoteType,
      hourlyMin: minimum?.toDouble(),
      minimumDesiredSalary: _minimumSalary,
      distanceKm: distanceKm,
      searchRadiusKm: _distance,
      postedAt: postedAt,
      language: AppLanguageController.language.value,
    );
    return Job(
      id: id,
      title: title,
      company: formatExternalText(row['company']?.toString() ?? ''),
      location: location,
      match: compatibility.overall,
      commute: commute?.label ?? _estimatedCommute(latitude, longitude, remote),
      salary: minimum == null
          ? context.tr('salaryUnknown')
          : '${minimum.toStringAsFixed(0)}–${(maximum ?? minimum).toStringAsFixed(0)} €/h',
      source: formatExternalText(row['source']?.toString() ?? 'Partenaire'),
      sourceUrl: row['source_url'] as String? ?? '',
      latitude: latitude ?? 48.1374,
      longitude: longitude ?? 11.5755,
      color: colors[(id - 1).abs() % colors.length],
      tags: tags,
      description: description,
      posted: _relativePostedAt(postedAt),
      postedAt: postedAt,
      hourlyMin: minimum?.toDouble(),
      remote: remote,
      remoteType: remoteType,
      routeUrl: commute?.routeUrl,
      compatibility: compatibility,
    );
  }

  String _estimatedCommute(double? latitude, double? longitude, bool remote) {
    if (latitude == null || longitude == null) {
      return context.tr('unknownDistance');
    }
    final center = _searchCenter;
    final km = _distanceBetweenKm(
      center.latitude,
      center.longitude,
      latitude,
      longitude,
    );
    final minutes = math.max(8, (km * 2.7 + 8).round());
    return remote && minutes > 35
        ? context.tr('hybrid')
        : context.trFormat('estimatedMinutes', {'minutes': minutes});
  }

  LatLng get _searchCenter {
    final latitude = (_profile.preferences['city_latitude'] as num?)
        ?.toDouble();
    final longitude = (_profile.preferences['city_longitude'] as num?)
        ?.toDouble();
    if (latitude != null && longitude != null) {
      return LatLng(latitude, longitude);
    }
    final city = GermanCityService.exact(_profile.city);
    if (city != null) return LatLng(city.latitude, city.longitude);
    return const LatLng(48.1374, 11.5755);
  }

  String _relativePostedAt(DateTime? value) {
    if (value == null) return context.tr('recently');
    final difference = DateTime.now().toUtc().difference(value.toUtc());
    if (difference.inHours < 1) return context.tr('justNow');
    if (difference.inHours < 24) {
      return context.trFormat('postedHours', {'count': difference.inHours});
    }
    if (difference.inDays == 1) return context.tr('postedYesterday');
    return context.trFormat('postedDays', {'count': difference.inDays});
  }

  String get _firstName {
    final user = Supabase.instance.client.auth.currentUser;
    final fullName = (user?.userMetadata?['full_name'] as String?)?.trim();
    if (fullName == null || fullName.isEmpty) return 'toi';
    return fullName.split(' ').first;
  }

  void _selectPage(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_pageIndex == index) return;
    setState(() => _pageIndex = index);
  }

  void _showAssistant([String? initialPrompt]) {
    if (_jobCatalog.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('loadJobsFirst'))));
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssistantSheet(
        jobs: _jobCatalog,
        profile: _profile,
        selectedJob: _selectedJob,
        initialPrompt: initialPrompt,
      ),
    );
  }

  Future<void> _showInterviewPrep(Job job) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _InterviewPrepSheet(job: job, profile: _profile),
  );

  Future<void> _showAdminModeration() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdminModerationSheet(repository: _repository),
    );
    if (mounted) await _loadWorkspace();
  }

  Future<void> _showNotifications() async {
    await _refreshNotifications();
    if (!mounted) return;
    var sheetItems = List<WerklyNotification>.of(_notifications);
    var systemEnabled = _systemNotificationsEnabled;
    String scheduleLabel(WerklyNotification item) {
      final dueAt = item.dueAt;
      if (dueAt == null) return context.tr('newJob');
      final local = dueAt.toLocal();
      final localizations = MaterialLocalizations.of(context);
      final date =
          '${localizations.formatShortDate(local)} · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
      return item.isDue()
          ? context.trFormat('reminderDue', {'date': date})
          : context.trFormat('scheduledFor', {'date': date});
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: SizedBox(
            height: math.min(MediaQuery.sizeOf(context).height * .78, 680),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('alertsReminders'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (sheetItems.any((item) => item.unread))
                        TextButton(
                          onPressed: () async {
                            final updated = await NotificationService.instance
                                .markAllRead();
                            if (!mounted || !sheetContext.mounted) return;
                            setState(() => _notifications = updated);
                            setSheetState(() => sheetItems = updated);
                          },
                          child: Text(context.tr('markAllRead')),
                        ),
                    ],
                  ),
                  Text(
                    context.tr('alertsSubtitle'),
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  if (!systemEnabled)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: _mint,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('receiveDeviceReminders'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.tr('permissionOptional'),
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            onPressed: () async {
                              final granted = await NotificationService.instance
                                  .requestSystemPermission();
                              if (!mounted || !sheetContext.mounted) return;
                              setState(
                                () => _systemNotificationsEnabled = granted,
                              );
                              setSheetState(() => systemEnabled = granted);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    granted
                                        ? context.tr('notificationsEnabled')
                                        : context.tr('notificationsDenied'),
                                  ),
                                ),
                              );
                            },
                            child: Text(context.tr('enable')),
                          ),
                        ],
                      ),
                    ),
                  if (!systemEnabled) const SizedBox(height: 12),
                  Expanded(
                    child: sheetItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.notifications_none_rounded,
                                  color: _muted,
                                  size: 36,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  context.tr('noAlerts'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.tr('alertsEmptyBody'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: sheetItems.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = sheetItems[index];
                              final reminder = item.kind == 'reminder';
                              return Dismissible(
                                key: ValueKey(item.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 18),
                                  color: const Color(0xFFFFE4E0),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                  ),
                                ),
                                onDismissed: (_) async {
                                  final updated = await NotificationService
                                      .instance
                                      .delete(item.id);
                                  if (!mounted || !sheetContext.mounted) return;
                                  setState(() => _notifications = updated);
                                  setSheetState(() => sheetItems = updated);
                                },
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: reminder
                                        ? const Color(0xFFFFF0DC)
                                        : _mint,
                                    foregroundColor: reminder
                                        ? const Color(0xFFA86416)
                                        : _green,
                                    child: Icon(
                                      reminder
                                          ? Icons.alarm_rounded
                                          : Icons.work_outline_rounded,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.localizedTitle(
                                            AppLanguageController
                                                .language
                                                .value,
                                          ),
                                          style: TextStyle(
                                            fontWeight: item.unread
                                                ? FontWeight.w900
                                                : FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (item.unread && item.isDue())
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 3),
                                      Text(
                                        item.localizedMessage(
                                          AppLanguageController.language.value,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        scheduleLabel(item),
                                        style: const TextStyle(
                                          color: _green,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    final updated = await NotificationService
                                        .instance
                                        .markRead(item.id);
                                    if (!mounted || !sheetContext.mounted) {
                                      return;
                                    }
                                    setState(() => _notifications = updated);
                                    final job = _jobById(item.jobId);
                                    if (job == null) {
                                      setSheetState(() => sheetItems = updated);
                                      return;
                                    }
                                    Navigator.pop(sheetContext);
                                    _selectPage(1);
                                    _showJob(job);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showFilters() async {
    var minimumSalary = _minimumSalary;
    var flexibleOnly = _flexibleOnly;
    var selectedSources = Set<String>.of(_selectedSources);
    final sources = _jobCatalog.map((job) => job.source).toSet().toList()
      ..sort();
    final result = await showDialog<(double, bool, Set<String>)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.tr('advancedFilters')),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    minimumSalary == 0
                        ? context.tr('allSalaries')
                        : context.trFormat('salaryFrom', {
                            'salary': minimumSalary.round(),
                          }),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Slider(
                    value: minimumSalary,
                    min: 0,
                    max: 25,
                    divisions: 5,
                    label: minimumSalary == 0
                        ? context.tr('all')
                        : '${minimumSalary.round()} €/h',
                    onChanged: (value) =>
                        setDialogState(() => minimumSalary = value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.tr('flexibleOnly')),
                    value: flexibleOnly,
                    onChanged: (value) =>
                        setDialogState(() => flexibleOnly = value),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('sources'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final source in sources)
                        FilterChip(
                          label: Text(source),
                          selected: selectedSources.contains(source),
                          onSelected: (selected) => setDialogState(() {
                            selected
                                ? selectedSources.add(source)
                                : selectedSources.remove(source);
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, (0, false, <String>{})),
              child: Text(context.tr('reset')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, (
                minimumSalary,
                flexibleOnly,
                selectedSources,
              )),
              child: Text(context.tr('apply')),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _minimumSalary = result.$1;
      _flexibleOnly = result.$2;
      _selectedSources = result.$3;
      _jobCatalog = _jobRows.map(_jobFromRow).toList();
    });
  }

  Future<void> _saveCurrentSearch() async {
    final defaultName = _query.trim().isNotEmpty
        ? '${_query.trim()} · ${_profile.city}'
        : 'Werkstudent · ${_profile.city}';
    final controller = TextEditingController(text: defaultName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('saveThisSearch')),
        content: TextField(
          controller: controller,
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
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    final search = SavedJobSearch(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      query: _query,
      filter: _filter,
      sort: _jobSort.name,
      minimumSalary: _minimumSalary,
      flexibleOnly: _flexibleOnly,
      sources: Set<String>.of(_selectedSources),
      city: _profile.city,
      radiusKm: _distance,
      createdAt: DateTime.now().toUtc(),
    );
    final items = await _savedSearchService.save(search);
    if (!mounted) return;
    setState(() => _savedSearches = items);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr('searchSavedToast'))));
  }

  Future<void> _applySavedSearch(SavedJobSearch search) async {
    final city = GermanCityService.exact(search.city);
    final updatedProfile = _profile.copyWith(
      city: search.city.isEmpty ? _profile.city : search.city,
      preferences: {
        ..._profile.preferences,
        'search_radius': search.radiusKm,
        if (city != null) 'city_latitude': city.latitude,
        if (city != null) 'city_longitude': city.longitude,
      },
    );
    try {
      final savedProfile = await _repository.saveProfile(updatedProfile);
      if (!mounted) return;
      setState(() {
        _profile = savedProfile;
        _query = search.query;
        _filter = search.filter;
        _jobSort = JobSortOption.values.firstWhere(
          (value) => value.name == search.sort,
          orElse: () => JobSortOption.match,
        );
        _minimumSalary = search.minimumSalary;
        _flexibleOnly = search.flexibleOnly;
        _selectedSources = Set<String>.of(search.sources);
        _distance = search.radiusKm;
        _commuteEstimates.clear();
        _jobCatalog = _jobRows.map(_jobFromRow).toList();
      });
      _refreshCommutes();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('searchApplyFailed'))),
        );
      }
    }
  }

  void _changeMapDistance(double value) {
    final radius = value.round().clamp(5, 100);
    if (radius == _distance) return;
    setState(() {
      _distance = radius;
      _jobCatalog = _jobRows.map(_jobFromRow).toList();
    });
  }

  Future<void> _persistMapDistance(double value) async {
    final radius = value.round().clamp(5, 100);
    final updated = _profile.copyWith(
      preferences: {..._profile.preferences, 'search_radius': radius},
    );
    setState(() {
      _distance = radius;
      _profile = updated;
      _jobCatalog = _jobRows.map(_jobFromRow).toList();
    });
    try {
      final saved = await _repository.saveProfile(updated);
      if (!mounted) return;
      setState(() {
        _profile = saved;
        _jobCatalog = _jobRows.map(_jobFromRow).toList();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.trFormat('preferencesSaveFailed', {'error': error}),
          ),
        ),
      );
    }
  }

  Future<void> _showSavedSearches() async {
    if (_savedSearches.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('noSavedSearches'))));
      return;
    }
    var items = List<SavedJobSearch>.of(_savedSearches);
    final selected = await showModalBottomSheet<SavedJobSearch>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .78,
          ),
          decoration: const BoxDecoration(
            color: _cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.tr('mySavedSearches'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(14),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final details = [
                      if (item.query.isNotEmpty) '“${item.query}”',
                      if (item.city.isNotEmpty) item.city,
                      '${item.radiusKm} km',
                      if (item.minimumSalary > 0)
                        context.trFormat('salaryStarting', {
                          'salary': item.minimumSalary.round(),
                        }),
                    ].join(' · ');
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(
                          Icons.saved_search_rounded,
                          color: _green,
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(details),
                        onTap: () => Navigator.pop(sheetContext, item),
                        trailing: IconButton(
                          tooltip: context.tr('delete'),
                          onPressed: () async {
                            final updated = await _savedSearchService.delete(
                              item.id,
                            );
                            if (!mounted || !sheetContext.mounted) return;
                            setState(() => _savedSearches = updated);
                            setSheetState(() => items = updated);
                            if (updated.isEmpty) Navigator.pop(sheetContext);
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) await _applySavedSearch(selected);
  }

  String _coverLetter(Job job) => _applicationLetter(
    job: job,
    profile: _profile,
    language: AppLanguageController.language.value,
  );

  Future<void> _showLetter(Job job) async {
    var useAi = false;
    if (_repository.currentUser != null) {
      var privacyChoice = await _repository.getAiPrivacyChoice();
      if (privacyChoice == null && mounted) {
        privacyChoice = await askAiConsent(context);
        if (privacyChoice != null) {
          await _repository.setAiPrivacyChoice(privacyChoice);
        }
      }
      useAi = privacyChoice == true;
    }

    var letter = _coverLetter(job);
    var byAi = false;
    String? fallbackNote;

    if (useAi) {
      if (mounted) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(context.tr('letterGenerating'))),
              ],
            ),
          ),
        );
      }
      if (mounted) {
        try {
          final (reply, _) = await _repository.askAi(
            message: context.tr('assistantLetterPrompt'),
            profile: _profile,
            selectedJob: jobAiContext(job),
            bestMatches: const [],
          );
          letter = reply;
          byAi = true;
        } on AiQuotaExceededException catch (error) {
          fallbackNote = error.message;
        } catch (_) {
          fallbackNote = mounted ? context.tr('letterAiUnavailable') : null;
        }
      }
      if (mounted) Navigator.pop(context);
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.trFormat('coverLetterFor', {'company': job.company}),
        ),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  byAi
                      ? context.tr('letterByNia')
                      : fallbackNote ?? context.tr('letterQuickTemplate'),
                  style: TextStyle(
                    color: byAi ? _green : _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                SelectableText(letter),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('close')),
          ),
          OutlinedButton.icon(
            onPressed: () => _downloadLetter(job, letter),
            icon: const Icon(Icons.download_rounded),
            label: Text(context.tr('downloadLetter')),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: letter));
              if (context.mounted) Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text(this.context.tr('letterCopied'))),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: Text(context.tr('copy')),
          ),
        ],
      ),
    );
  }

  ApplicationKitData _applicationKitData(
    Job job, {
    String? coverLetterOverride,
  }) => ApplicationKitData(
    applicantName: _isGuestProfileName(_profile.fullName)
        ? context.tr('guestApplicantName')
        : _profile.fullName.trim(),
    email: Supabase.instance.client.auth.currentUser?.email ?? '',
    degree: _profile.degree,
    university: _profile.university,
    city: _profile.city,
    summary: _profile.professionalSummary,
    profileSkills: _profile.skills,
    jobTitle: job.title,
    company: job.company,
    jobLocation: job.location,
    jobTags: job.tags,
    sourceUrl: job.sourceUrl,
    coverLetter: coverLetterOverride ?? _coverLetter(job),
    generatedAt: DateTime.now(),
    language: AppLanguageController.language.value,
  );

  String _safeFileToken(String value) => value
      .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  Future<bool> _confirmPlaceholderNameDownload() async {
    if (!_isGuestProfileName(_profile.fullName)) return true;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('letterNeedsNameTitle')),
        content: Text(context.tr('letterNeedsNameBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('letterDownloadAnyway')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('signIn')),
          ),
        ],
      ),
    );
    if (proceed != true && mounted) {
      await _openAuth();
    }
    return proceed == true;
  }

  Future<void> _downloadLetter(Job job, String letter) async {
    if (!await _confirmPlaceholderNameDownload() || !mounted) return;
    final data = _applicationKitData(job, coverLetterOverride: letter);
    final pdf = ApplicationKitService.buildLetterPdf(data);
    final safeCompany = _safeFileToken(job.company);
    final filename =
        '${context.tr('applicationFilePrefix')}_${context.tr('pdfCoverLetter').toLowerCase()}_${safeCompany.isEmpty ? 'werkstudent' : safeCompany}.pdf';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 760,
          height: math.min(MediaQuery.sizeOf(context).height * .92, 820),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, color: _green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.trFormat('coverLetterFor', {
                          'company': job.company,
                        }),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr('close'),
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: PdfPreview(
                  build: (_) => pdf,
                  pdfFileName: filename,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  allowPrinting: true,
                  allowSharing: true,
                  loadingWidget: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showApplicationKit(Job job) async {
    final data = _applicationKitData(job);
    final pdf = ApplicationKitService.buildPdf(data);
    final safeCompany = _safeFileToken(job.company);
    final filename =
        '${context.tr('applicationFilePrefix')}_${safeCompany.isEmpty ? 'werkstudent' : safeCompany}.pdf';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 960,
          height: math.min(MediaQuery.sizeOf(context).height * .92, 820),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
                child: Row(
                  children: [
                    const Icon(Icons.folder_copy_outlined, color: _green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.trFormat('applicationFolder', {
                          'company': job.company,
                        }),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr('close'),
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: PdfPreview(
                  build: (_) => pdf,
                  pdfFileName: filename,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  allowPrinting: true,
                  allowSharing: true,
                  loadingWidget: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editProfile() async {
    final name = TextEditingController(text: _profile.fullName);
    final university = TextEditingController(text: _profile.university);
    final degree = TextEditingController(text: _profile.degree);
    final city = TextEditingController(text: _profile.city);
    final summary = TextEditingController(text: _profile.professionalSummary);
    final skills = TextEditingController(text: _profile.skills.join(', '));
    var prefersRemote = _profile.preferences['remote'] == true;
    final result = await showDialog<UserProfileData>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.tr('editProfile')),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: InputDecoration(
                      labelText: context.tr('fullName'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: university,
                    decoration: InputDecoration(
                      labelText: context.tr('university'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: degree,
                    decoration: InputDecoration(
                      labelText: context.tr('education'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: city,
                    decoration: InputDecoration(labelText: context.tr('city')),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: skills,
                    decoration: InputDecoration(
                      labelText: context.tr('commaSkills'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: summary,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: context.tr('professionalSummary'),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.tr('preferFlexibleJobs')),
                    value: prefersRemote,
                    onChanged: (value) =>
                        setDialogState(() => prefersRemote = value),
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
            FilledButton(
              onPressed: () {
                final parsedSkills = skills.text
                    .split(',')
                    .map((value) => value.trim())
                    .where((value) => value.isNotEmpty)
                    .toSet()
                    .toList();
                var completion = 20;
                if (name.text.trim().isNotEmpty) completion += 10;
                if (university.text.trim().isNotEmpty) completion += 10;
                if (degree.text.trim().isNotEmpty) completion += 10;
                if (city.text.trim().isNotEmpty) completion += 5;
                if (summary.text.trim().isNotEmpty) completion += 20;
                if (parsedSkills.isNotEmpty) completion += 15;
                if (_profile.cvPath != null) completion += 10;
                Navigator.pop(
                  context,
                  _profile.copyWith(
                    fullName: name.text,
                    university: university.text,
                    degree: degree.text,
                    city: city.text,
                    professionalSummary: summary.text,
                    skills: parsedSkills,
                    preferences: {
                      ..._profile.preferences,
                      'remote': prefersRemote,
                    },
                    profileCompletion: completion.clamp(0, 100),
                  ),
                );
              },
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    university.dispose();
    degree.dispose();
    city.dispose();
    summary.dispose();
    skills.dispose();
    if (result == null) return;
    try {
      final saved = await _repository.saveProfile(result);
      if (!mounted) return;
      setState(() => _profile = saved);
      await _loadWorkspace();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('profileSaved'))));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.trFormat('profileSaveFailed', {'error': error}),
            ),
          ),
        );
      }
    }
  }

  Future<void> _setApplicationStatus(int id, String? status) async {
    setState(() {
      if (status == null) {
        _applicationStatuses.remove(id);
        _appliedJobs.remove(id);
      } else {
        _applicationStatuses[id] = status;
        _appliedJobs.add(id);
      }
    });
    try {
      if (status == null) {
        await _repository.removeApplication(id);
      } else {
        await _repository.setApplicationStatus(id, status);
      }
      final job = _jobById(id);
      if (job != null) {
        final notifications = status == null
            ? await NotificationService.instance.removeJobReminders(id)
            : await NotificationService.instance.addStatusReminder(
                jobId: id,
                jobTitle: job.title,
                company: job.company,
                status: status,
              );
        if (mounted) setState(() => _notifications = notifications);
      }
    } catch (_) {
      _showSyncNotice();
    }
  }

  Future<void> _openExternalSearch(String provider) async {
    final keywords = _query.trim().isEmpty
        ? 'Werkstudent'
        : 'Werkstudent ${_query.trim()}';
    final location = _profile.city.trim().isEmpty
        ? 'Deutschland'
        : _profile.city.trim();
    final query = Uri.encodeQueryComponent(keywords);
    final place = Uri.encodeQueryComponent(location);
    final uri = switch (provider) {
      'LinkedIn' => Uri.parse(
        'https://www.linkedin.com/jobs/search/?keywords=$query&location=$place',
      ),
      'Indeed' => Uri.parse('https://de.indeed.com/jobs?q=$query&l=$place'),
      _ => Uri.parse('https://www.stepstone.de/jobs/werkstudent?q=$query'),
    };
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.trFormat('externalOpenFailed', {'provider': provider}),
          ),
        ),
      );
    }
  }

  Future<void> _showEmployerSubmission() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      await _openAuth();
      if (Supabase.instance.client.auth.currentUser == null || !mounted) return;
    }
    final user = Supabase.instance.client.auth.currentUser!;
    final draft = await showDialog<_EmployerJobDraft>(
      context: context,
      builder: (_) => _EmployerJobForm(initialEmail: user.email ?? ''),
    );
    if (draft == null) return;
    try {
      await _repository.submitEmployerJob(
        companyName: draft.companyName,
        contactName: draft.contactName,
        contactEmail: draft.contactEmail,
        title: draft.title,
        location: draft.location,
        remoteType: draft.remoteType,
        salaryMin: draft.salaryMin,
        salaryMax: draft.salaryMax,
        sourceUrl: draft.sourceUrl,
        tags: draft.tags,
        description: draft.description,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('employerJobSubmitted'))),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.trFormat('employerJobSubmitFailed', {'error': error}),
            ),
          ),
        );
      }
    }
  }

  Future<void> _openAuth() async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const AuthPage()));
    if (mounted && Supabase.instance.client.auth.currentUser != null) {
      await _loadWorkspace();
    }
  }

  void _showJob(Job job) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final embeddedDetails = usesEmbeddedJobDetails(
      pageIndex: _pageIndex,
      viewportWidth: viewportWidth,
    );
    setState(() {
      _selectedJobId = job.id;
    });
    // The wide Jobs page already has an embedded detail panel. Everywhere
    // else, open the offer immediately so a click always has a visible result.
    if (!embeddedDetails) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => _JobDetailSheet(
          job: job,
          profileSkills: _profile.skills,
          applied: _appliedJobs.contains(job.id),
          onApply: () {
            Navigator.pop(sheetContext);
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _prepareApplication(job),
            );
          },
          onLetter: () => _showLetter(job),
          onInterview: () => _showInterviewPrep(job),
        ),
      );
    }
  }

  Future<void> _prepareApplication(Job job) async {
    final initialStatus = _applicationStatuses[job.id] ?? 'preparing';
    if (!_applicationStatuses.containsKey(job.id)) {
      await _setApplicationStatus(job.id, initialStatus);
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApplicationPrepSheet(
        job: job,
        profile: _profile,
        initialStatus: initialStatus,
        onGenerateLetter: () => _showLetter(job),
        onExportKit: () => _showApplicationKit(job),
        onSetReminder: () => _setApplicationReminder(job),
        onOpenOriginal: () => _openOriginalJob(job),
        onEditProfile: _editProfile,
        onStatusChanged: (status) => _setApplicationStatus(job.id, status),
      ),
    );
  }

  Future<bool> _setApplicationReminder(Job job) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: context.tr('reminderDate'),
      cancelText: context.tr('cancel'),
      confirmText: context.tr('continue'),
    );
    if (date == null || !mounted) return false;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: context.tr('reminderTime'),
      cancelText: context.tr('cancel'),
      confirmText: context.tr('save'),
    );
    if (time == null || !mounted) return false;
    final dueAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!dueAt.isAfter(now)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('futureDateRequired'))));
      return false;
    }
    final items = await NotificationService.instance.scheduleReminder(
      jobId: job.id,
      jobTitle: job.title,
      company: job.company,
      dueAt: dueAt,
    );
    if (!mounted) return false;
    setState(() => _notifications = items);
    final materialLocalizations = MaterialLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.trFormat('reminderScheduled', {
            'date': materialLocalizations.formatShortDate(dueAt),
            'time': materialLocalizations.formatTimeOfDay(
              TimeOfDay.fromDateTime(dueAt),
            ),
          }),
        ),
      ),
    );
    return true;
  }

  Future<void> _openOriginalJob(Job job) async {
    final uri = Uri.tryParse(job.sourceUrl);
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('originalLinkUnavailable'))),
        );
      }
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('jobOpenFailed'))));
    }
  }

  Future<void> _toggleSaved(int id) async {
    final saved = !_savedJobs.contains(id);
    setState(() => saved ? _savedJobs.add(id) : _savedJobs.remove(id));
    try {
      await _repository.setFavorite(id, favorite: saved);
    } catch (_) {
      _showSyncNotice();
    }
  }

  void _showSyncNotice() {
    if (!mounted || _syncNoticeShown) return;
    _syncNoticeShown = true;
    final guest = Supabase.instance.client.auth.currentUser == null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          guest ? context.tr('savedOnDevice') : context.tr('syncUnavailable'),
        ),
        action: guest
            ? SnackBarAction(label: context.tr('signIn'), onPressed: _openAuth)
            : null,
      ),
    );
  }

  Future<void> _uploadCv() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      await _openAuth();
      if (Supabase.instance.client.auth.currentUser == null) return;
    }
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (selection == null || selection.files.single.bytes == null) return;
    final file = selection.files.single;
    try {
      await _repository.uploadCv(
        bytes: file.bytes!,
        extension: file.extension ?? 'pdf',
      );
      await _loadWorkspace();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.trFormat('cvAddedToast', {'file': file.name}),
            ),
          ),
        );
      }
      await _analyzeCv();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.trFormat('cvAddFailed', {'error': error})),
          ),
        );
      }
    }
  }

  Future<bool> _requestCvAnalysisConsent({bool forcePrompt = false}) async {
    final savedChoice = await _repository.getCvAnalysisPrivacyChoice();
    if (savedChoice == true) {
      await _repository.setCvAnalysisPrivacyChoice(true);
      return true;
    }
    if (savedChoice == false && !forcePrompt) return false;
    if (!mounted) return false;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('analyzeCvConsentTitle')),
        content: Text(context.tr('analyzeCvConsentBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('keepWithoutAnalysis')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(context.tr('analyze')),
          ),
        ],
      ),
    );
    if (accepted != null) {
      await _repository.setCvAnalysisPrivacyChoice(accepted);
    }
    return accepted == true;
  }

  Future<void> _analyzeCv({bool forceConsentPrompt = false}) async {
    if (_isAnalyzingCv || _profile.cvPath == null) return;
    final accepted = await _requestCvAnalysisConsent(
      forcePrompt: forceConsentPrompt,
    );
    if (!accepted) {
      if (mounted && !forceConsentPrompt) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('cvKeptPrivate'))));
      }
      return;
    }
    setState(() => _isAnalyzingCv = true);
    try {
      await _repository.analyzeCv();
      await _loadWorkspace();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.trFormat('cvSkillsDetected', {
                'count': _profile.skills.length,
              }),
            ),
          ),
        );
      }
    } catch (_) {
      await _loadWorkspace();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('cvAnalysisFailed'))));
      }
    } finally {
      if (mounted) setState(() => _isAnalyzingCv = false);
    }
  }

  Future<void> _viewCv() async {
    final path = _profile.cvPath;
    if (path == null || path.trim().isEmpty) return;
    try {
      final uri = await _repository.createCvViewUrl(path);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw Exception('URL non prise en charge');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.trFormat('viewCvFailed', {'error': error.toString()}),
          ),
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('deleteAccountTitle')),
        content: Text(context.tr('deleteAccountBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.deleteAccount();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('deleteAccountUnavailable'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 760;
    final showWorkspaceStatus = _jobCatalog.isEmpty && _pageIndex <= 2;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (desktop)
              _SideNavigation(
                selected: _pageIndex,
                profileCompletion: _profile.profileCompletion,
                onSelected: _selectPage,
              ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    desktop: desktop,
                    pageIndex: _pageIndex,
                    onSearch: (value) => setState(() => _query = value),
                    onAssistant: _showAssistant,
                    onNotifications: _showNotifications,
                    unreadNotifications: _unreadNotificationCount,
                  ),
                  Expanded(
                    child: showWorkspaceStatus
                        ? _WorkspaceStatusView(
                            key: ValueKey('workspace-status-$_pageIndex'),
                            title: switch (_pageIndex) {
                              1 => context.tr('jobs'),
                              2 => context.tr('map'),
                              _ => context.tr('dashboard'),
                            },
                            icon: switch (_pageIndex) {
                              1 => Icons.work_outline_rounded,
                              2 => Icons.map_outlined,
                              _ => Icons.grid_view_rounded,
                            },
                            loading: _isLoadingWorkspace,
                            message: _workspaceError,
                            onRetry: () =>
                                _loadWorkspace(forceSync: true, announce: true),
                          )
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: KeyedSubtree(
                              key: ValueKey(_pageIndex),
                              child: switch (_pageIndex) {
                                0 => _DashboardView(
                                  jobs: sortJobsForDisplay(
                                    _jobCatalog,
                                    JobSortOption.match,
                                  ).take(3).toList(),
                                  allJobs: _jobCatalog,
                                  profile: _profile,
                                  firstName: _firstName,
                                  savedJobs: _savedJobs,
                                  onOpenJobs: () => _selectPage(1),
                                  onOpenMap: () => _selectPage(2),
                                  onOpenJob: _showJob,
                                  onToggleSaved: _toggleSaved,
                                ),
                                1 => _JobsView(
                                  jobs: _visibleJobs,
                                  selectedJob: _selectedJob,
                                  profile: _profile,
                                  query: _query,
                                  filter: _filter,
                                  sort: _jobSort,
                                  isRefreshing: _isRefreshingJobs,
                                  lastUpdated: _jobsUpdatedAt,
                                  savedJobs: _savedJobs,
                                  appliedJobs: _appliedJobs,
                                  onSearch: (value) =>
                                      setState(() => _query = value),
                                  onFilter: (value) =>
                                      setState(() => _filter = value),
                                  onSort: (value) =>
                                      setState(() => _jobSort = value),
                                  onRefresh: () => _loadWorkspace(
                                    forceSync: true,
                                    announce: true,
                                  ),
                                  onMoreFilters: _showFilters,
                                  onSaveSearch: _saveCurrentSearch,
                                  onManageSearches: _showSavedSearches,
                                  savedSearchCount: _savedSearches.length,
                                  onOpenJob: _showJob,
                                  onApply: _prepareApplication,
                                  onToggleSaved: _toggleSaved,
                                  onLetter: _showLetter,
                                  onInterview: _showInterviewPrep,
                                  onExternalSearch: _openExternalSearch,
                                  onSubmitJob: _showEmployerSubmission,
                                ),
                                2 => _MapView(
                                  jobs: _visibleJobs,
                                  distance: _distance,
                                  center: _searchCenter,
                                  savedJobs: _savedJobs,
                                  onDistanceChanged: _changeMapDistance,
                                  onDistanceChangeEnd: _persistMapDistance,
                                  onOpenJob: _showJob,
                                  onToggleSaved: _toggleSaved,
                                ),
                                3 => _ApplicationsView(
                                  jobs: _jobCatalog,
                                  savedJobs: _savedJobs,
                                  applicationStatuses: _applicationStatuses,
                                  onOpenJob: _showJob,
                                  onStatusChanged: _setApplicationStatus,
                                ),
                                _ => _ProfileView(
                                  profile: _profile,
                                  jobs: _jobCatalog,
                                  onUploadCv: _uploadCv,
                                  onAnalyzeCv: () =>
                                      _analyzeCv(forceConsentPrompt: true),
                                  onViewCv: _viewCv,
                                  isAnalyzingCv: _isAnalyzingCv,
                                  onEditProfile: _editProfile,
                                  onEditPreferences: _editPreferences,
                                  onOptimizeCv: () => _showAssistant(
                                    context.tr('assistantCvPrompt'),
                                  ),
                                  onSignIn: _openAuth,
                                  onSignOut: _repository.signOut,
                                  onDeleteAccount: _deleteAccount,
                                  onReplayTutorial: _replayTutorial,
                                  onOpenPrivacy: () =>
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => const PrivacyPage(),
                                        ),
                                      ),
                                  isAdmin: _repository.isAdmin,
                                  onOpenAdmin: _showAdminModeration,
                                ),
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: desktop
          ? null
          : _MobileNavigation(selected: _pageIndex, onSelected: _selectPage),
      floatingActionButton: desktop
          ? FloatingActionButton.extended(
              onPressed: _showAssistant,
              backgroundColor: _ink,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.auto_awesome_rounded, size: 19),
              label: Text(context.tr('assistant')),
            )
          : FloatingActionButton(
              onPressed: _showAssistant,
              backgroundColor: _ink,
              foregroundColor: Colors.white,
              child: const Icon(Icons.auto_awesome_rounded),
            ),
    );
  }
}

