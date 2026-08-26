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
  final skillValues = matchingSkills.isEmpty
      ? job.tags.take(2).toList()
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
    final letter = _coverLetter(job);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.trFormat('coverLetterFor', {'company': job.company}),
        ),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(child: SelectableText(letter)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('close')),
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

  ApplicationKitData _applicationKitData(Job job) => ApplicationKitData(
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
    coverLetter: _coverLetter(job),
    generatedAt: DateTime.now(),
    language: AppLanguageController.language.value,
  );

  Future<void> _showApplicationKit(Job job) async {
    final data = _applicationKitData(job);
    final pdf = ApplicationKitService.buildPdf(data);
    final safeCompany = job.company
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
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

class _WorkspaceStatusView extends StatelessWidget {
  const _WorkspaceStatusView({
    super.key,
    required this.title,
    required this.icon,
    required this.loading,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final IconData icon;
  final bool loading;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const CircularProgressIndicator(color: _green)
              else
                Icon(icon, size: 48, color: _muted),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                loading
                    ? context.tr('loadingRealJobs')
                    : message ?? context.tr('noJobsAvailable'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (!loading) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.tr('retry')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNavigation extends StatelessWidget {
  const _SideNavigation({
    required this.selected,
    required this.profileCompletion,
    required this.onSelected,
  });

  final int selected;
  final int profileCompletion;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.grid_view_rounded, context.tr('home')),
      (Icons.work_outline_rounded, context.tr('jobs')),
      (Icons.map_outlined, context.tr('map')),
      (Icons.view_kanban_outlined, context.tr('tracking')),
      (Icons.person_outline_rounded, context.tr('profile')),
    ];

    return Container(
      width: 218,
      decoration: const BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 720;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: _Brand(light: true),
                    ),
                    SizedBox(height: compact ? 24 : 42),
                    for (var i = 0; i < items.length; i++) ...[
                      _SideNavItem(
                        icon: items[i].$1,
                        label: items[i].$2,
                        selected: selected == i,
                        onTap: () => onSelected(i),
                      ),
                      SizedBox(height: compact ? 3 : 7),
                    ],
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.all(compact ? 11 : 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                color: _orange,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  context.trFormat('profileCompletion', {
                                    'score': profileCompletion,
                                  }),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          LinearProgressIndicator(
                            value: profileCompletion.clamp(0, 100) / 100,
                            minHeight: 5,
                            color: _orange,
                            backgroundColor: Color(0xFF43504C),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            context.tr('profileTip'),
                            maxLines: compact ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFB8C2BE),
                              fontSize: 11,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? 9 : 18),
                    _UserRow(light: true),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? _ink : const Color(0xFF9FABE4),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? _ink : const Color(0xFFD2D8D5),
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavigation extends StatelessWidget {
  const _MobileNavigation({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: onSelected,
      height: 68,
      backgroundColor: Colors.white,
      indicatorColor: _mint,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.grid_view_rounded),
          label: context.tr('home'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.work_outline_rounded),
          label: context.tr('jobs'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.map_outlined),
          label: context.tr('map'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.view_kanban_outlined),
          label: context.tr('tracking'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline_rounded),
          label: context.tr('profile'),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.desktop,
    required this.pageIndex,
    required this.onSearch,
    required this.onAssistant,
    required this.onNotifications,
    required this.unreadNotifications,
  });

  final bool desktop;
  final int pageIndex;
  final ValueChanged<String> onSearch;
  final VoidCallback onAssistant;
  final VoidCallback onNotifications;
  final int unreadNotifications;

  @override
  Widget build(BuildContext context) {
    final titles = [
      context.tr('dashboard'),
      context.tr('jobs'),
      context.tr('map'),
      context.tr('applications'),
      context.tr('myProfile'),
    ];
    return Container(
      height: desktop ? 86 : 72,
      padding: EdgeInsets.symmetric(horizontal: desktop ? 28 : 16),
      decoration: const BoxDecoration(
        color: _cream,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          if (!desktop) ...[
            const _Brand(light: false),
            const Spacer(),
          ] else ...[
            Text(
              titles[pageIndex],
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(width: 28),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: TextField(
                  onChanged: onSearch,
                  decoration: InputDecoration(
                    hintText: context.tr('searchHint'),
                    prefixIcon: const Icon(Icons.search_rounded, size: 21),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: context.tr('notifications'),
              onPressed: onNotifications,
              icon: Badge(
                isLabelVisible: unreadNotifications > 0,
                label: Text(
                  unreadNotifications > 9 ? '9+' : '$unreadNotifications',
                ),
                child: const Icon(Icons.notifications_none_rounded),
              ),
            ),
            const SizedBox(width: 10),
            _UserRow(light: false),
          ],
          if (!desktop) ...[
            IconButton(
              tooltip: context.tr('notifications'),
              onPressed: onNotifications,
              icon: Badge(
                isLabelVisible: unreadNotifications > 0,
                label: Text(
                  unreadNotifications > 9 ? '9+' : '$unreadNotifications',
                ),
                child: const Icon(Icons.notifications_none_rounded),
              ),
            ),
            IconButton(
              tooltip: context.tr('assistant'),
              onPressed: onAssistant,
              icon: const Icon(Icons.auto_awesome_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.light});
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 33,
          height: 33,
          decoration: BoxDecoration(
            color: _orange,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: const Text(
            'W',
            style: TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          'werkly',
          style: TextStyle(
            color: light ? Colors.white : _ink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.light});
  final bool light;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadataName = (user?.userMetadata?['full_name'] as String?)?.trim();
    final name = metadataName == null || metadataName.isEmpty
        ? (user?.email?.split('@').first ?? context.tr('guestMode'))
        : metadataName;
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFB9D7CC),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials.isEmpty ? 'W' : initials,
            style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          name,
          style: TextStyle(
            color: light ? Colors.white : _ink,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    required this.jobs,
    required this.allJobs,
    required this.profile,
    required this.firstName,
    required this.savedJobs,
    required this.onOpenJobs,
    required this.onOpenMap,
    required this.onOpenJob,
    required this.onToggleSaved,
  });

  final List<Job> jobs;
  final List<Job> allJobs;
  final UserProfileData profile;
  final String firstName;
  final Set<int> savedJobs;
  final VoidCallback onOpenJobs;
  final VoidCallback onOpenMap;
  final ValueChanged<Job> onOpenJob;
  final ValueChanged<int> onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1040;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 30 : 18, 26, wide ? 30 : 18, 110),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WelcomeBanner(
                    firstName: firstName,
                    newJobs: allJobs.where((job) {
                      final postedAt = job.postedAt;
                      return postedAt != null &&
                          DateTime.now().difference(postedAt).inHours <= 24;
                    }).length,
                    onOpenJobs: onOpenJobs,
                  ),
                  const SizedBox(height: 22),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: _OpportunityMap(
                            jobs: allJobs,
                            city: profile.city,
                            radiusKm:
                                (profile.preferences['search_radius'] as num?)
                                    ?.round() ??
                                25,
                            onOpenMap: onOpenMap,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 4,
                          child: _ProfileInsightCard(
                            profile: profile,
                            jobs: allJobs,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _OpportunityMap(
                      jobs: allJobs,
                      city: profile.city,
                      radiusKm:
                          (profile.preferences['search_radius'] as num?)
                              ?.round() ??
                          25,
                      onOpenMap: onOpenMap,
                    ),
                    const SizedBox(height: 18),
                    _ProfileInsightCard(profile: profile, jobs: allJobs),
                  ],
                  const SizedBox(height: 26),
                  _SectionTitle(
                    title: context.tr('bestMatches'),
                    subtitle: context.tr('matchesSubtitle'),
                    action: context.trFormat('seeJobs', {
                      'count': allJobs.length,
                    }),
                    onTap: onOpenJobs,
                  ),
                  const SizedBox(height: 14),
                  if (constraints.maxWidth >= 920)
                    SizedBox(
                      height: 275,
                      child: Row(
                        children: [
                          for (var i = 0; i < jobs.length; i++) ...[
                            Expanded(
                              child: _JobCard(
                                job: jobs[i],
                                saved: savedJobs.contains(jobs[i].id),
                                onTap: () => onOpenJob(jobs[i]),
                                onSave: () => onToggleSaved(jobs[i].id),
                              ),
                            ),
                            if (i != jobs.length - 1) const SizedBox(width: 14),
                          ],
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 275,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: jobs.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) => SizedBox(
                          width: math.min(330, constraints.maxWidth * .82),
                          child: _JobCard(
                            job: jobs[index],
                            saved: savedJobs.contains(jobs[index].id),
                            onTap: () => onOpenJob(jobs[index]),
                            onSave: () => onToggleSaved(jobs[index].id),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({
    required this.firstName,
    required this.newJobs,
    required this.onOpenJobs,
  });
  final String firstName;
  final int newJobs;
  final VoidCallback onOpenJobs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _mint,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8DED2)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          return Flex(
            direction: compact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: compact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: compact ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        newJobs == 0
                            ? '✦  ${context.tr('jobsUpdated')}'
                            : '✦  ${context.trFormat('newJobsToday', {'count': newJobs})}',
                        style: const TextStyle(
                          color: _green,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      context.trFormat('welcome', {'name': firstName}),
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('welcomeSubtitle'),
                      style: const TextStyle(
                        color: Color(0xFF50665C),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (compact)
                const SizedBox(height: 20)
              else
                const SizedBox(width: 24),
              FilledButton.icon(
                onPressed: onOpenJobs,
                style: FilledButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                icon: const Icon(Icons.arrow_outward_rounded, size: 18),
                label: Text(context.tr('exploreMatches')),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OpportunityMap extends StatelessWidget {
  const _OpportunityMap({
    required this.jobs,
    required this.city,
    required this.radiusKm,
    required this.onOpenMap,
  });
  final List<Job> jobs;
  final String city;
  final int radiusKm;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 330,
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _MapPainter())),
            Positioned(
              left: 20,
              top: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 16),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: _green,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${city.trim().isEmpty ? context.tr('countryGermany') : city} · ${context.tr('radius')} $radiusKm km',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            if (jobs.isNotEmpty)
              Positioned(
                left: 25,
                bottom: 25,
                child: _MapPin(label: '${jobs[0].match}', hot: true),
              ),
            if (jobs.length > 1)
              Positioned(
                left: 190,
                top: 105,
                child: _MapPin(label: '${jobs[1].match}'),
              ),
            if (jobs.length > 2)
              Positioned(
                right: 70,
                top: 92,
                child: _MapPin(label: '${jobs[2].match}'),
              ),
            if (jobs.length > 3)
              Positioned(
                right: 140,
                bottom: 62,
                child: _MapPin(label: '${jobs[3].match}', hot: true),
              ),
            Positioned(
              right: 18,
              bottom: 18,
              child: FilledButton.tonalIcon(
                onPressed: onOpenMap,
                icon: const Icon(Icons.fullscreen_rounded, size: 18),
                label: Text(context.tr('openMap')),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.label, this.hot = false});
  final String label;
  final bool hot;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: hot ? 46 : 40,
      height: hot ? 46 : 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hot ? _orange : _green,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: hot ? _ink : Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFFE9EEE8), BlendMode.srcOver);
    final district = Paint()..color = const Color(0xFFDCE6DC);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .06,
          size.height * .12,
          size.width * .30,
          size.height * .45,
        ),
        const Radius.circular(28),
      ),
      district,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .59,
          size.height * .42,
          size.width * .34,
          size.height * .42,
        ),
        const Radius.circular(34),
      ),
      district,
    );

    final river = Paint()
      ..color = const Color(0xFFB7D6DF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
    final riverPath = Path()
      ..moveTo(size.width * .62, -10)
      ..cubicTo(
        size.width * .75,
        size.height * .28,
        size.width * .43,
        size.height * .55,
        size.width * .54,
        size.height + 10,
      );
    canvas.drawPath(riverPath, river);

    final road = Paint()
      ..color = Colors.white.withValues(alpha: .9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final thinRoad = Paint()
      ..color = Colors.white.withValues(alpha: .7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawLine(
      Offset(-10, size.height * .76),
      Offset(size.width + 10, size.height * .16),
      road,
    );
    canvas.drawLine(
      Offset(size.width * .20, -10),
      Offset(size.width * .72, size.height + 10),
      road,
    );
    canvas.drawLine(
      Offset(-10, size.height * .34),
      Offset(size.width + 10, size.height * .54),
      thinRoad,
    );
    canvas.drawLine(
      Offset(size.width * .36, -10),
      Offset(size.width * .18, size.height + 10),
      thinRoad,
    );
    canvas.drawLine(
      Offset(size.width * .82, -10),
      Offset(size.width * .89, size.height + 10),
      thinRoad,
    );

    final center = Offset(size.width * .46, size.height * .44);
    final heatPaint = Paint()
      ..shader = RadialGradient(
        colors: [_orange.withValues(alpha: .25), _orange.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: 85));
    canvas.drawCircle(center, 85, heatPaint);

    final labelStyle = TextStyle(
      color: _muted.withValues(alpha: .75),
      fontSize: 10,
      fontWeight: FontWeight.w700,
    );
    for (final item in <(String, Offset)>[
      ('MAXVORSTADT', Offset(size.width * .24, size.height * .36)),
      ('ALTSTADT', Offset(size.width * .49, size.height * .66)),
      ('BOGENHAUSEN', Offset(size.width * .74, size.height * .32)),
      ('SENDLING', Offset(size.width * .25, size.height * .87)),
    ]) {
      final painter = TextPainter(
        text: TextSpan(text: item.$1, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, item.$2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProfileInsightCard extends StatelessWidget {
  const _ProfileInsightCard({required this.profile, required this.jobs});

  final UserProfileData profile;
  final List<Job> jobs;

  @override
  Widget build(BuildContext context) {
    final demand = <String, int>{};
    for (final job in jobs) {
      for (final tag in job.tags) {
        demand[tag] = (demand[tag] ?? 0) + 1;
      }
    }
    final rankedDemand = demand.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final profileSkills = profile.skills.take(4).toList();
    final displayed = profileSkills.isNotEmpty
        ? profileSkills
              .map((skill) => MapEntry(skill, demand[skill] ?? 0))
              .toList()
        : rankedDemand.take(4).toList();
    final maxDemand = math.max(
      1,
      displayed.fold<int>(0, (value, item) => math.max(value, item.value)),
    );
    final education = [
      profile.degree,
      profile.university,
    ].where((value) => value.trim().isNotEmpty).join(' · ');
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('profileCardTitle'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _ScoreBubble(score: profile.profileCompletion),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              education.isEmpty ? context.tr('profileIncomplete') : education,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 22),
            Text(
              profileSkills.isEmpty
                  ? context.tr('skillsSought')
                  : context.tr('skillsPresence'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (displayed.isEmpty)
              Text(
                context.tr('noData'),
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            for (final skill in displayed) ...[
              Row(
                children: [
                  SizedBox(
                    width: 66,
                    child: Text(
                      skill.key,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: skill.value / maxDemand,
                      color: skill.value == 0 ? _orange : _green,
                      backgroundColor: const Color(0xFFEEF0EB),
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    context.trFormat('jobCount', {'count': skill.value}),
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 13),
            ],
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFFAA681B),
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      profileSkills.isEmpty
                          ? context.tr('addSkillsForScores')
                          : context.tr('scoreUsesProfile'),
                      style: const TextStyle(
                        color: Color(0xFF765127),
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
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

class _FirstRunTutorialSheet extends StatefulWidget {
  const _FirstRunTutorialSheet();

  @override
  State<_FirstRunTutorialSheet> createState() => _FirstRunTutorialSheetState();
}

class _FirstRunTutorialSheetState extends State<_FirstRunTutorialSheet> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page == 3) {
      Navigator.pop(context, true);
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLanguageController.language,
      builder: (context, _, _) {
        final pages = <({IconData icon, String title, String body})>[
          (
            icon: Icons.translate_rounded,
            title: context.tr('tutorialLanguageTitle'),
            body: context.tr('tutorialLanguageBody'),
          ),
          (
            icon: Icons.auto_awesome_rounded,
            title: context.tr('tutorialMatchesTitle'),
            body: context.tr('tutorialMatchesBody'),
          ),
          (
            icon: Icons.route_rounded,
            title: context.tr('tutorialMapTitle'),
            body: context.tr('tutorialMapBody'),
          ),
          (
            icon: Icons.task_alt_rounded,
            title: context.tr('tutorialKitTitle'),
            body: context.tr('tutorialKitBody'),
          ),
        ];
        return SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Container(
                height: math.min(650, MediaQuery.sizeOf(context).height * .9),
                decoration: const BoxDecoration(
                  color: _cream,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 14, 14, 4),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'W',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'werkly',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(context.tr('skip')),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: pages.length,
                        onPageChanged: (value) => setState(() => _page = value),
                        itemBuilder: (context, index) {
                          final item = pages[index];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(28, 18, 28, 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 112,
                                  height: 112,
                                  decoration: BoxDecoration(
                                    color: index.isEven
                                        ? _mint
                                        : const Color(0xFFFFEBD2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 48,
                                    color: index.isEven
                                        ? _green
                                        : const Color(0xFFAA681B),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  item.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 27,
                                    height: 1.1,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 13),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 500,
                                  ),
                                  child: Text(
                                    item.body,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                if (index == 0) ...[
                                  const SizedBox(height: 26),
                                  SegmentedButton<AppLanguage>(
                                    showSelectedIcon: true,
                                    segments: [
                                      for (final language in AppLanguage.values)
                                        ButtonSegment(
                                          value: language,
                                          label: Text(language.shortLabel),
                                        ),
                                    ],
                                    selected: {
                                      AppLanguageController.language.value,
                                    },
                                    onSelectionChanged: (selection) =>
                                        AppLanguageController.setLanguage(
                                          selection.first,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var index = 0; index < pages.length; index++)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: index == _page ? 24 : 7,
                                  height: 7,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: index == _page
                                        ? _green
                                        : const Color(0xFFD2D9D5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.trFormat('tutorialProgress', {
                              'current': _page + 1,
                              'total': pages.length,
                            }),
                            style: const TextStyle(color: _muted, fontSize: 10),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _next,
                              style: FilledButton.styleFrom(
                                backgroundColor: _ink,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              icon: Icon(
                                _page == pages.length - 1
                                    ? Icons.rocket_launch_rounded
                                    : Icons.arrow_forward_rounded,
                              ),
                              label: Text(
                                _page == pages.length - 1
                                    ? context.tr('start')
                                    : context.tr('next'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingWelcomeSheet extends StatelessWidget {
  const _OnboardingWelcomeSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Container(
            decoration: const BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCAD2CE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _orange,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'W',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('welcomeWerkly'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              context.tr('chooseHowToPersonalize'),
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                                height: 1.4,
                              ),
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
                  _OnboardingChoice(
                    icon: Icons.tune_rounded,
                    title: context.tr('choosePreferences'),
                    subtitle: context.tr('choosePreferencesBody'),
                    badge: context.tr('twoMinutes'),
                    primary: true,
                    onTap: () =>
                        Navigator.pop(context, _OnboardingAction.preferences),
                  ),
                  const SizedBox(height: 10),
                  _OnboardingChoice(
                    icon: Icons.document_scanner_rounded,
                    title: context.tr('importAnalyzeCv'),
                    subtitle: context.tr('importAnalyzeCvBody'),
                    badge: context.tr('secureAccountRequired'),
                    onTap: () => Navigator.pop(context, _OnboardingAction.cv),
                  ),
                  const SizedBox(height: 10),
                  _OnboardingChoice(
                    icon: Icons.explore_outlined,
                    title: context.tr('exploreFirst'),
                    subtitle: context.tr('exploreFirstBody'),
                    badge: context.tr('guestBadge'),
                    onTap: () =>
                        Navigator.pop(context, _OnboardingAction.explore),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 15,
                        color: _muted,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          context.tr('noAutomaticApplication'),
                          style: const TextStyle(color: _muted, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingChoice extends StatelessWidget {
  const _OnboardingChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? _ink : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primary ? _ink : _line),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primary
                      ? const Color(0xFF304039)
                      : const Color(0xFFF0F5F2),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: primary ? _orange : _green, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: primary ? Colors.white : _ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: primary ? const Color(0xFFC9D1CE) : _muted,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      badge,
                      style: TextStyle(
                        color: primary ? _orange : _green,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: primary ? Colors.white : _green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickPreferencesSheet extends StatefulWidget {
  const _QuickPreferencesSheet({required this.profile});

  final UserProfileData profile;

  @override
  State<_QuickPreferencesSheet> createState() => _QuickPreferencesSheetState();
}

class _QuickPreferencesSheetState extends State<_QuickPreferencesSheet> {
  static const _availableFields = [
    'Tous domaines',
    'Informatique',
    'Data & IA',
    'Ingénierie',
    'Business & Finance',
    'Marketing & Design',
  ];
  static const _workModes = ['Hybride', 'Télétravail', 'Sur site'];
  static const _weeklyHours = ['10–15 h', '16–20 h', 'Plus de 20 h'];
  static const _germanLevels = [
    'Non précisé',
    'A1',
    'A2',
    'B1',
    'B2',
    'C1',
    'C2',
  ];
  static const _radii = [10, 25, 50, 100];

  late final TextEditingController _city;
  late final FocusNode _cityFocus;
  late final Set<String> _fields;
  late String _workMode;
  late String _hours;
  late String _german;
  late int _radius;
  GermanCity? _selectedCity;
  bool _isLocating = false;
  bool _showDomainError = false;
  String? _locationError;
  String _locationSource = 'manual';

  @override
  void initState() {
    super.initState();
    final preferences = widget.profile.preferences;
    _city = TextEditingController(text: widget.profile.city);
    _cityFocus = FocusNode();
    _selectedCity = GermanCityService.exact(widget.profile.city);
    _locationSource = preferences['location_source'] as String? ?? 'manual';
    _fields = List<String>.from(
      preferences['fields'] as List? ?? const [],
    ).toSet();
    if (_fields.isEmpty) _fields.add('Tous domaines');
    _workMode = preferences['work_mode'] as String? ?? 'Hybride';
    _hours = preferences['weekly_hours'] as String? ?? '16–20 h';
    _german = preferences['german_level'] as String? ?? 'Non précisé';
    _radius = (preferences['search_radius'] as num?)?.toInt() ?? 25;
  }

  @override
  void dispose() {
    _city.dispose();
    _cityFocus.dispose();
    super.dispose();
  }

  void _selectCity(GermanCity city, {bool fromCurrentPosition = false}) {
    setState(() {
      _selectedCity = city;
      _city.text = city.name;
      _city.selection = TextSelection.collapsed(offset: city.name.length);
      _locationError = null;
      _locationSource = fromCurrentPosition
          ? 'current_position_city'
          : 'city_suggestion';
    });
    _cityFocus.unfocus();
  }

  Future<void> _useCurrentLocation() async {
    final serviceOffMessage = context.tr('locationServiceOff');
    final deniedMessage = context.tr('locationDenied');
    final blockedMessage = context.tr('locationBlocked');
    final outsideGermanyMessage = context.tr('outsideGermany');
    final unavailableMessage = context.tr('locationUnavailable');
    setState(() {
      _isLocating = true;
      _locationError = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw _LocationSelectionException(serviceOffMessage);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw _LocationSelectionException(deniedMessage);
      }
      if (permission == LocationPermission.deniedForever) {
        throw _LocationSelectionException(blockedMessage);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final nearest = GermanCityService.nearest(
        position.latitude,
        position.longitude,
      );
      if (nearest.distanceKm > 180) {
        throw _LocationSelectionException(outsideGermanyMessage);
      }
      if (!mounted) return;
      _selectCity(nearest.city, fromCurrentPosition: true);
    } on _LocationSelectionException catch (error) {
      if (mounted) setState(() => _locationError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _locationError = unavailableMessage);
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _toggleField(String field, bool selected) {
    setState(() {
      _showDomainError = false;
      if (field == 'Tous domaines') {
        _fields.clear();
        if (selected) _fields.add(field);
        return;
      }
      _fields.remove('Tous domaines');
      selected ? _fields.add(field) : _fields.remove(field);
    });
  }

  void _submit() {
    final cityName = _city.text.trim();
    if (cityName.isEmpty || _fields.isEmpty) {
      setState(() {
        _showDomainError = _fields.isEmpty;
        if (cityName.isEmpty) {
          _locationError = context.tr('chooseCityRequired');
        }
      });
      return;
    }
    final city = _selectedCity ?? GermanCityService.exact(cityName);
    Navigator.pop(
      context,
      _OnboardingPreferences(
        city: city?.name ?? cityName,
        fields: _fields.toList(),
        workMode: _workMode,
        weeklyHours: _hours,
        germanLevel: _german,
        searchRadius: _radius,
        cityLatitude: city?.latitude,
        cityLongitude: city?.longitude,
        locationSource: city == null ? 'manual' : _locationSource,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 760,
            maxHeight: MediaQuery.sizeOf(context).height * .92,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 14, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('preferencesTitle'),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              context.tr('preferencesPurpose'),
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 10,
                              ),
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
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _city,
                          focusNode: _cityFocus,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.addressCity],
                          onTap: () => setState(() {}),
                          onChanged: (value) => setState(() {
                            _selectedCity = GermanCityService.exact(value);
                            _locationError = null;
                            _locationSource = 'manual';
                          }),
                          decoration: InputDecoration(
                            labelText: context.tr('searchCity'),
                            hintText: context.tr('cityHint'),
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            suffixIcon: _city.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: context.tr('clearCity'),
                                    onPressed: () => setState(() {
                                      _city.clear();
                                      _selectedCity = null;
                                      _locationError = null;
                                      _locationSource = 'manual';
                                      _cityFocus.requestFocus();
                                    }),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                        _CitySuggestions(
                          query: _city.text,
                          visible: _cityFocus.hasFocus,
                          onSelected: _selectCity,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _isLocating ? null : _useCurrentLocation,
                            icon: _isLocating
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.my_location_rounded),
                            label: Text(
                              _isLocating
                                  ? context.tr('locatingCity')
                                  : context.tr('useCurrentLocation'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('approximateCityOnly'),
                          style: const TextStyle(color: _muted, fontSize: 10),
                        ),
                        if (_locationError != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            _locationError!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _PreferenceLabel(
                          title: context.tr('domainsQuestion'),
                          subtitle: context.tr('chooseAtLeastOne'),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableFields
                              .map(
                                (field) => FilterChip(
                                  selected: _fields.contains(field),
                                  label: Text(
                                    _localizedPreferenceValue(context, field),
                                  ),
                                  onSelected: (selected) =>
                                      _toggleField(field, selected),
                                ),
                              )
                              .toList(),
                        ),
                        if (_showDomainError) ...[
                          const SizedBox(height: 7),
                          Text(
                            context.tr('domainRequired'),
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _PreferenceLabel(
                          title: context.tr('preferredWorkMode'),
                        ),
                        const SizedBox(height: 10),
                        _ChoiceRow(
                          values: _workModes,
                          selected: _workMode,
                          onSelected: (value) =>
                              setState(() => _workMode = value),
                        ),
                        const SizedBox(height: 20),
                        _PreferenceLabel(
                          title: context.tr('weeklyAvailability'),
                        ),
                        const SizedBox(height: 10),
                        _ChoiceRow(
                          values: _weeklyHours,
                          selected: _hours,
                          onSelected: (value) => setState(() => _hours = value),
                        ),
                        const SizedBox(height: 20),
                        _PreferenceLabel(
                          title: context.tr('germanLevelChoice'),
                          subtitle: context.tr('germanLevelHelp'),
                        ),
                        const SizedBox(height: 10),
                        _ChoiceRow(
                          values: _germanLevels,
                          selected: _german,
                          onSelected: (value) =>
                              setState(() => _german = value),
                        ),
                        const SizedBox(height: 20),
                        _PreferenceLabel(
                          title: context.trFormat('searchRadius', {
                            'radius': _radius,
                          }),
                          subtitle: context.tr('distantJobsVisible'),
                        ),
                        const SizedBox(height: 10),
                        _ChoiceRow(
                          values: _radii.map((value) => '$value km').toList(),
                          selected: '$_radius km',
                          onSelected: (value) => setState(
                            () => _radius = int.parse(value.split(' ').first),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(context.tr('personalizeJobs')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationSelectionException implements Exception {
  const _LocationSelectionException(this.message);

  final String message;
}

class _CitySuggestions extends StatelessWidget {
  const _CitySuggestions({
    required this.query,
    required this.visible,
    required this.onSelected,
  });

  final String query;
  final bool visible;
  final ValueChanged<GermanCity> onSelected;

  @override
  Widget build(BuildContext context) {
    if (!visible || query.trim().isEmpty) return const SizedBox.shrink();
    final suggestions = GermanCityService.search(query);
    if (suggestions.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(12, 7, 12, 0),
        child: Text(
          context.tr('noCitySuggestion'),
          style: const TextStyle(color: _muted, fontSize: 10),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < suggestions.length; index++) ...[
              if (index > 0) const Divider(height: 1, indent: 46),
              ListTile(
                dense: true,
                visualDensity: const VisualDensity(vertical: -3),
                leading: const Icon(
                  Icons.location_city_rounded,
                  color: _green,
                  size: 19,
                ),
                title: Text(
                  suggestions[index].name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  suggestions[index].state,
                  style: const TextStyle(fontSize: 10),
                ),
                onTap: () => onSelected(suggestions[index]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreferenceLabel extends StatelessWidget {
  const _PreferenceLabel({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(subtitle!, style: const TextStyle(color: _muted, fontSize: 10)),
        ],
      ],
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (value) => ChoiceChip(
              selected: value == selected,
              label: Text(_localizedPreferenceValue(context, value)),
              onSelected: (_) => onSelected(value),
            ),
          )
          .toList(),
    );
  }
}

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
                    Text(job.commute, style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.payments_outlined,
                      size: 15,
                      color: _muted,
                    ),
                    const SizedBox(width: 5),
                    Text(job.salary, style: const TextStyle(fontSize: 11)),
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
        company.substring(0, 1),
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

class _MapView extends StatelessWidget {
  const _MapView({
    required this.jobs,
    required this.distance,
    required this.center,
    required this.savedJobs,
    required this.onDistanceChanged,
    required this.onDistanceChangeEnd,
    required this.onOpenJob,
    required this.onToggleSaved,
  });

  final List<Job> jobs;
  final int distance;
  final LatLng center;
  final Set<int> savedJobs;
  final ValueChanged<double> onDistanceChanged;
  final ValueChanged<double> onDistanceChangeEnd;
  final ValueChanged<Job> onOpenJob;
  final ValueChanged<int> onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final nearbyJobs = jobs
        .where(
          (job) =>
              _distanceBetweenKm(
                center.latitude,
                center.longitude,
                job.latitude,
                job.longitude,
              ) <=
              distance,
        )
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Padding(
          padding: EdgeInsets.all(wide ? 24 : 14),
          child: wide
              ? Row(
                  children: [
                    Expanded(
                      flex: 8,
                      child: _BigMap(
                        jobs: nearbyJobs,
                        distance: distance,
                        center: center,
                        onDistanceChanged: onDistanceChanged,
                        onDistanceChangeEnd: onDistanceChangeEnd,
                        onOpenJob: onOpenJob,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 4,
                      child: _MapJobList(
                        jobs: nearbyJobs,
                        savedJobs: savedJobs,
                        onOpenJob: onOpenJob,
                        onToggleSaved: onToggleSaved,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _BigMap(
                        jobs: nearbyJobs,
                        distance: distance,
                        center: center,
                        onDistanceChanged: onDistanceChanged,
                        onDistanceChangeEnd: onDistanceChangeEnd,
                        onOpenJob: onOpenJob,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      flex: 4,
                      child: _MapJobList(
                        jobs: nearbyJobs,
                        savedJobs: savedJobs,
                        onOpenJob: onOpenJob,
                        onToggleSaved: onToggleSaved,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _BigMap extends StatelessWidget {
  const _BigMap({
    required this.jobs,
    required this.distance,
    required this.center,
    required this.onDistanceChanged,
    required this.onDistanceChangeEnd,
    required this.onOpenJob,
  });
  final List<Job> jobs;
  final int distance;
  final LatLng center;
  final ValueChanged<double> onDistanceChanged;
  final ValueChanged<double> onDistanceChangeEnd;
  final ValueChanged<Job> onOpenJob;

  @override
  Widget build(BuildContext context) {
    final markers = jobs
        .map(
          (job) => Marker(
            key: ValueKey('job-${job.id}'),
            point: LatLng(job.latitude, job.longitude),
            width: 52,
            height: 52,
            child: Tooltip(
              message:
                  '${job.title}\n${job.company} · ${job.compatibility.scored ? '${job.match}% ${context.tr('compatibility')}' : context.tr('profileNeedsCompletion')}',
              child: Semantics(
                button: true,
                label: context.trFormat('openJobAt', {
                  'job': job.title,
                  'company': job.company,
                }),
                child: InkWell(
                  onTap: () => onOpenJob(job),
                  customBorder: const CircleBorder(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Color(0x33000000), blurRadius: 8),
                      ],
                    ),
                    child: const Icon(
                      Icons.work_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
        .toList();
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 11.3,
                minZoom: 4,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'de.werkly.app',
                  maxZoom: 19,
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: center,
                      radius: distance * 1000,
                      useRadiusInMeter: true,
                      color: _green.withValues(alpha: .08),
                      borderColor: _green.withValues(alpha: .55),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                MarkerLayer(markers: markers),
                RichAttributionWidget(
                  showFlutterMapAttribution: false,
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: Container(
              width: 245,
              padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x18000000), blurRadius: 15),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_bike_rounded,
                        color: _green,
                        size: 18,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        context.tr('maximumDistance'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$distance km',
                        style: const TextStyle(
                          color: _green,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: distance.clamp(5, 100).toDouble(),
                    min: 5,
                    max: 100,
                    divisions: 19,
                    onChanged: onDistanceChanged,
                    onChangeEnd: onDistanceChangeEnd,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapJobList extends StatelessWidget {
  const _MapJobList({
    required this.jobs,
    required this.savedJobs,
    required this.onOpenJob,
    required this.onToggleSaved,
  });
  final List<Job> jobs;
  final Set<int> savedJobs;
  final ValueChanged<Job> onOpenJob;
  final ValueChanged<int> onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.trFormat('nearbyJobs', {'count': jobs.length}),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            const Icon(Icons.sort_rounded, color: _muted),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: jobs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => SizedBox(
              height: 230,
              child: _JobCard(
                job: jobs[index],
                compact: true,
                saved: savedJobs.contains(jobs[index].id),
                onTap: () => onOpenJob(jobs[index]),
                onSave: () => onToggleSaved(jobs[index].id),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.profile,
    required this.jobs,
    required this.onUploadCv,
    required this.onAnalyzeCv,
    required this.onViewCv,
    required this.isAnalyzingCv,
    required this.onEditProfile,
    required this.onEditPreferences,
    required this.onOptimizeCv,
    required this.onSignIn,
    required this.onSignOut,
    required this.onDeleteAccount,
    required this.onReplayTutorial,
    required this.onOpenPrivacy,
    required this.isAdmin,
    required this.onOpenAdmin,
  });

  final UserProfileData profile;
  final List<Job> jobs;
  final VoidCallback onUploadCv;
  final VoidCallback onAnalyzeCv;
  final VoidCallback onViewCv;
  final bool isAnalyzingCv;
  final VoidCallback onEditProfile;
  final VoidCallback onEditPreferences;
  final VoidCallback onOptimizeCv;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;
  final VoidCallback onReplayTutorial;
  final VoidCallback onOpenPrivacy;
  final bool isAdmin;
  final VoidCallback onOpenAdmin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 960;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 24, wide ? 28 : 16, 100),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    title: context.tr('professionalProfile'),
                    subtitle: context.tr('professionalProfileSubtitle'),
                  ),
                  const SizedBox(height: 18),
                  if (wide) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: _ProfileSummary(
                            profile: profile,
                            jobs: jobs,
                            onUploadCv: onUploadCv,
                            onEditProfile: onEditProfile,
                            onEditPreferences: onEditPreferences,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              _CvChecklist(
                                profile: profile,
                                onOptimize: onOptimizeCv,
                              ),
                              const SizedBox(height: 14),
                              _LanguageSelectorCard(),
                              const SizedBox(height: 14),
                              _AccountActions(
                                onSignIn: onSignIn,
                                onSignOut: onSignOut,
                                onDeleteAccount: onDeleteAccount,
                                onReplayTutorial: onReplayTutorial,
                                onOpenPrivacy: onOpenPrivacy,
                                isAdmin: isAdmin,
                                onOpenAdmin: onOpenAdmin,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _CvAnalysisCard(
                      profile: profile,
                      isAnalyzing: isAnalyzingCv,
                      onAnalyze: onAnalyzeCv,
                      onView: onViewCv,
                      onUpload: onUploadCv,
                    ),
                  ] else ...[
                    _ProfileSummary(
                      profile: profile,
                      jobs: jobs,
                      onUploadCv: onUploadCv,
                      onEditProfile: onEditProfile,
                      onEditPreferences: onEditPreferences,
                    ),
                    const SizedBox(height: 16),
                    _CvAnalysisCard(
                      profile: profile,
                      isAnalyzing: isAnalyzingCv,
                      onAnalyze: onAnalyzeCv,
                      onView: onViewCv,
                      onUpload: onUploadCv,
                    ),
                    const SizedBox(height: 16),
                    _CvChecklist(profile: profile, onOptimize: onOptimizeCv),
                    const SizedBox(height: 14),
                    _LanguageSelectorCard(),
                    const SizedBox(height: 14),
                    _AccountActions(
                      onSignIn: onSignIn,
                      onSignOut: onSignOut,
                      onDeleteAccount: onDeleteAccount,
                      onReplayTutorial: onReplayTutorial,
                      onOpenPrivacy: onOpenPrivacy,
                      isAdmin: isAdmin,
                      onOpenAdmin: onOpenAdmin,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.profile,
    required this.jobs,
    required this.onUploadCv,
    required this.onEditProfile,
    required this.onEditPreferences,
  });
  final UserProfileData profile;
  final List<Job> jobs;
  final VoidCallback onUploadCv;
  final VoidCallback onEditProfile;
  final VoidCallback onEditPreferences;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadataName = (user?.userMetadata?['full_name'] as String?)?.trim();
    final name = !_isGuestProfileName(profile.fullName)
        ? profile.fullName.trim()
        : metadataName == null || metadataName.isEmpty
        ? (user?.email?.split('@').first ?? context.tr('guestProfileName'))
        : metadataName;
    final subtitle = [
      profile.degree,
      profile.university,
      profile.city,
    ].where((value) => value.trim().isNotEmpty).join(' · ');
    final demand = <String, int>{};
    for (final job in jobs) {
      for (final tag in job.tags) {
        demand[tag] = (demand[tag] ?? 0) + 1;
      }
    }
    final topDemand = demand.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB9D7CC),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials.isEmpty ? 'W' : initials,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle.isEmpty
                            ? context.tr('addEducationCity')
                            : subtitle,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: context.tr('editProfile'),
                  onSelected: (action) => switch (action) {
                    'profile' => onEditProfile(),
                    'preferences' => onEditPreferences(),
                    _ => onUploadCv(),
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: Text(context.tr('editProfile')),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'cv',
                      child: ListTile(
                        leading: const Icon(Icons.upload_file_rounded),
                        title: Text(context.tr('addCv')),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'preferences',
                      child: ListTile(
                        leading: const Icon(Icons.tune_rounded),
                        title: Text(context.tr('editPreferences')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('aiSummary'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              profile.professionalSummary.trim().isEmpty
                  ? context.tr('addSummary')
                  : profile.professionalSummary,
            ),
            const SizedBox(height: 22),
            Text(
              context.tr('detectedSkills'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (profile.skills.isEmpty)
              Text(
                context.tr('noSkillsProvided'),
                style: const TextStyle(color: _muted),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.skills
                    .map(
                      (skill) => _SkillPill(
                        label: skill,
                        level: context.tr('declared'),
                        strong: jobs.any(
                          (job) => job.tags.any(
                            (tag) => tag.toLowerCase() == skill.toLowerCase(),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 24),
            Text(
              context.tr('marketDemand'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            if (topDemand.isEmpty)
              Text(context.tr('marketTrendsEmpty'))
            else
              for (final entry in topDemand.take(3)) ...[
                _DemandBar(
                  label: entry.key,
                  value: entry.value / math.max(1, jobs.length),
                  opportunities: context.trFormat('jobCount', {
                    'count': entry.value,
                  }),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _SkillPill extends StatelessWidget {
  const _SkillPill({
    required this.label,
    required this.level,
    this.strong = false,
  });
  final String label;
  final String level;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: strong ? _mint : const Color(0xFFF1F2EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: _ink,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
          children: [
            TextSpan(text: '$label  '),
            TextSpan(
              text: level,
              style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w500,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemandBar extends StatelessWidget {
  const _DemandBar({
    required this.label,
    required this.value,
    required this.opportunities,
  });
  final String label;
  final double value;
  final String opportunities;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value,
            minHeight: 9,
            color: _orange,
            backgroundColor: const Color(0xFFF0EEE8),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 52,
          child: Text(
            opportunities,
            style: const TextStyle(color: _muted, fontSize: 9),
          ),
        ),
      ],
    );
  }
}

class _CvAnalysisCard extends StatelessWidget {
  const _CvAnalysisCard({
    required this.profile,
    required this.isAnalyzing,
    required this.onAnalyze,
    required this.onView,
    required this.onUpload,
  });

  final UserProfileData profile;
  final bool isAnalyzing;
  final VoidCallback onAnalyze;
  final VoidCallback onView;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final analysis = profile.cvAnalysis;
    final skills = _analysisItems(analysis['skills']);
    final languages = _analysisItems(analysis['languages']);
    final experiences = _analysisItems(analysis['experiences']);
    final warnings = (analysis['warnings'] as List? ?? const [])
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .toList();
    final complete = profile.cvAnalysisStatus == 'complete';
    final failed = profile.cvAnalysisStatus == 'failed';
    final analyzedAt = profile.cvAnalyzedAt;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: complete ? _mint : const Color(0xFFFFF1DD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    complete
                        ? Icons.document_scanner_rounded
                        : Icons.auto_awesome_rounded,
                    color: complete ? _green : const Color(0xFF9C5E19),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('cvAnalysis'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAnalyzing
                            ? context.tr('extractingCv')
                            : complete
                            ? context.tr('cvResultsVerify')
                            : failed
                            ? context.tr('cvLastFailed')
                            : profile.cvPath == null
                            ? context.tr('cvAddPdf')
                            : context.tr('cvStored'),
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: isAnalyzing
                      ? const SizedBox(
                          key: ValueKey('cv-analyzing'),
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : FilledButton.icon(
                          key: const ValueKey('cv-action'),
                          onPressed: profile.cvPath == null
                              ? onUpload
                              : onAnalyze,
                          icon: Icon(
                            profile.cvPath == null
                                ? Icons.upload_file_rounded
                                : Icons.refresh_rounded,
                            size: 17,
                          ),
                          label: Text(
                            profile.cvPath == null
                                ? context.tr('addMyCv')
                                : complete
                                ? context.tr('reanalyze')
                                : context.tr('analyze'),
                          ),
                        ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              child: isAnalyzing
                  ? const Padding(
                      padding: EdgeInsets.only(top: 18),
                      child: _CvAnalysisProgress(),
                    )
                  : const SizedBox.shrink(),
            ),
            if (!isAnalyzing && profile.cvPath != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                  label: Text(context.tr('viewMyCv')),
                ),
              ),
            ],
            if (!isAnalyzing &&
                failed &&
                profile.cvAnalysisError.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                profile.cvAnalysisError,
                style: TextStyle(color: Colors.red.shade700, fontSize: 11),
              ),
            ],
            if (!isAnalyzing && complete) ...[
              const SizedBox(height: 20),
              Wrap(
                spacing: 24,
                runSpacing: 18,
                children: [
                  _AnalysisGroup(
                    title: '${context.tr('skills')} (${skills.length})',
                    items: skills
                        .take(8)
                        .map((item) => item['name']?.toString() ?? '')
                        .where((value) => value.isNotEmpty)
                        .toList(),
                  ),
                  _AnalysisGroup(
                    title: '${context.tr('languages')} (${languages.length})',
                    items: languages
                        .map(
                          (item) => [item['language'], item['level']]
                              .whereType<String>()
                              .where((v) => v.isNotEmpty)
                              .join(' '),
                        )
                        .where((value) => value.isNotEmpty)
                        .toList(),
                  ),
                  _AnalysisGroup(
                    title:
                        '${context.tr('experiences')} (${experiences.length})',
                    items: experiences
                        .take(4)
                        .map((item) => item['title']?.toString() ?? '')
                        .where((value) => value.isNotEmpty)
                        .toList(),
                  ),
                ],
              ),
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  context.trFormat('cvWarnings', {
                    'items': warnings.take(3).join(' · '),
                  }),
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
              if (analyzedAt != null) ...[
                const SizedBox(height: 10),
                Text(
                  context.trFormat('cvLastAnalysis', {
                    'date': MaterialLocalizations.of(
                      context,
                    ).formatShortDate(analyzedAt.toLocal()),
                  }),
                  style: const TextStyle(color: _muted, fontSize: 9),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  static List<Map<String, dynamic>> _analysisItems(Object? value) =>
      (value as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
}

class _CvAnalysisProgress extends StatefulWidget {
  const _CvAnalysisProgress();

  @override
  State<_CvAnalysisProgress> createState() => _CvAnalysisProgressState();
}

class _CvAnalysisProgressState extends State<_CvAnalysisProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = <String>[
      context.tr('cvScanPreparing'),
      context.tr('cvScanReading'),
      context.tr('cvScanSkills'),
      context.tr('cvScanProfile'),
    ];
    return Semantics(
      liveRegion: true,
      label: context.tr('extractingCv'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _green.withValues(alpha: .055),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _green.withValues(alpha: .14)),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final current = (_controller.value * steps.length)
                .floor()
                .clamp(0, steps.length - 1)
                .toInt();
            final pulse = 1 + math.sin(_controller.value * math.pi * 8) * .06;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Transform.scale(
                      scale: pulse,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: _mint,
                          shape: BoxShape.circle,
                        ),
                        child: Transform.rotate(
                          angle: _controller.value * math.pi * 2,
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: _green,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 380),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, .25),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Text(
                          steps[current],
                          key: ValueKey(current),
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const LinearProgressIndicator(
                  minHeight: 6,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  color: _green,
                  backgroundColor: Color(0xFFDDE6E0),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(
                    steps.length,
                    (index) => Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        margin: EdgeInsets.only(
                          right: index == steps.length - 1 ? 0 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: index <= current
                              ? _green
                              : _green.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  context.tr('cvScanWait'),
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AnalysisGroup extends StatelessWidget {
  const _AnalysisGroup({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 275,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              context.tr('nothingFound'),
              style: const TextStyle(color: _muted, fontSize: 10),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: items
                  .map(
                    (item) => Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(item, style: const TextStyle(fontSize: 10)),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _CvChecklist extends StatelessWidget {
  const _CvChecklist({required this.profile, required this.onOptimize});
  final UserProfileData profile;
  final VoidCallback onOptimize;

  @override
  Widget build(BuildContext context) {
    final score = profile.profileCompletion.clamp(0, 100);
    final hasSummary = profile.professionalSummary.trim().isNotEmpty;
    final hasSkills = profile.skills.isNotEmpty;
    final hasStudy =
        profile.degree.trim().isNotEmpty ||
        profile.university.trim().isNotEmpty;
    return Column(
      children: [
        Card(
          margin: EdgeInsets.zero,
          color: _ink,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: _orange,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('cvScore'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$score/100',
                      style: const TextStyle(
                        color: _orange,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 8,
                  color: _orange,
                  backgroundColor: Color(0xFF3D4844),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                const SizedBox(height: 14),
                Text(
                  score >= 80
                      ? context.tr('profileSolid')
                      : context.tr('completeProfile'),
                  style: const TextStyle(
                    color: Color(0xFFC9D1CE),
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onOptimize,
                  style: FilledButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: _ink,
                  ),
                  child: Text(context.tr('optimizeAi')),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('nextImprovements'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                _ChecklistItem(
                  done: hasSummary,
                  title: context.tr('clearProfile'),
                  detail: hasSummary
                      ? context.tr('summaryProvided')
                      : context.trFormat('potentialPoints', {'count': 20}),
                ),
                _ChecklistItem(
                  done: hasSkills,
                  title: context.tr('skillsProvided'),
                  detail: hasSkills
                      ? context.trFormat('skillCount', {
                          'count': profile.skills.length,
                        })
                      : context.trFormat('potentialPoints', {'count': 15}),
                ),
                _ChecklistItem(
                  done: hasStudy,
                  title: context.tr('educationUniversity'),
                  detail: hasStudy
                      ? context.tr('informationPresent')
                      : context.trFormat('potentialPoints', {'count': 20}),
                ),
                _ChecklistItem(
                  done: profile.skills.any(
                    (skill) => skill.toLowerCase().contains('deutsch'),
                  ),
                  title: context.tr('germanLevel'),
                  detail: context.trFormat('potentialPoints', {'count': 5}),
                ),
                _ChecklistItem(
                  done: profile.cvPath != null,
                  title: context.tr('cvAdded'),
                  detail: profile.cvPath == null
                      ? context.trFormat('potentialPoints', {'count': 10})
                      : context.tr('secureSupabaseDocument'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.done,
    required this.title,
    required this.detail,
  });
  final bool done;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: done ? _green : _orange,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(color: _muted, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminModerationSheet extends StatefulWidget {
  const _AdminModerationSheet({required this.repository});

  final WerklyRepository repository;

  @override
  State<_AdminModerationSheet> createState() => _AdminModerationSheetState();
}

class _AdminModerationSheetState extends State<_AdminModerationSheet> {
  late Future<List<EmployerSubmissionData>> _future = _load();
  var _pendingOnly = true;
  final Set<String> _reviewing = {};

  Future<List<EmployerSubmissionData>> _load() =>
      widget.repository.loadEmployerSubmissions();

  Future<void> _review(EmployerSubmissionData item, bool approved) async {
    final controller = TextEditingController(
      text: approved ? context.tr('adminApprovedDefaultNote') : '',
    );
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          approved
              ? context.tr('approveJobTitle')
              : context.tr('rejectJobTitle'),
        ),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          autofocus: !approved,
          decoration: InputDecoration(
            labelText: approved
                ? context.tr('internalNote')
                : context.tr('rejectionReason'),
            hintText: approved
                ? context.tr('checksCompleted')
                : context.tr('correctionNeeded'),
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (!approved && value.isEmpty) return;
              Navigator.pop(context, value);
            },
            style: approved
                ? null
                : FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: Text(
              approved ? context.tr('approve') : context.tr('reject'),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    if (notes == null || !mounted) return;
    setState(() => _reviewing.add(item.id));
    try {
      await widget.repository.reviewEmployerSubmission(
        id: item.id,
        approved: approved,
        notes: notes,
      );
      if (!mounted) return;
      setState(() => _future = _load());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved
                ? context.tr('jobApprovedPublished')
                : context.tr('jobRejectedHistory'),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.trFormat('adminDecisionFailed', {'error': error}),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _reviewing.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * .92,
      decoration: const BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const _SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 14),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings_outlined, color: _green),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('moderationTitle'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        context.tr('moderationSubtitle'),
                        style: const TextStyle(color: _muted, fontSize: 10),
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
          const Divider(height: 1),
          SwitchListTile.adaptive(
            title: Text(context.tr('pendingOnly')),
            value: _pendingOnly,
            onChanged: (value) => setState(() => _pendingOnly = value),
          ),
          Expanded(
            child: FutureBuilder<List<EmployerSubmissionData>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        context.trFormat('moderationLoadFailed', {
                          'error': snapshot.error ?? '',
                        }),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final items = (snapshot.data ?? const [])
                    .where((item) => !_pendingOnly || item.status == 'pending')
                    .toList();
                if (items.isEmpty) {
                  return Center(child: Text(context.tr('noJobsToModerate')));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final busy = _reviewing.contains(item.id);
                    final statusColor = switch (item.status) {
                      'approved' => _green,
                      'rejected' => Colors.red.shade700,
                      _ => const Color(0xFF9C5E19),
                    };
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: .12),
                          foregroundColor: statusColor,
                          child: Text(
                            item.companyName.isEmpty
                                ? '?'
                                : item.companyName[0],
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${item.companyName} · ${item.location} · ${context.tr(switch (item.status) {
                            'approved' => 'moderationApproved',
                            'rejected' => 'moderationRejected',
                            _ => 'moderationPending',
                          })}',
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          18,
                          0,
                          18,
                          18,
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(item.description),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              context.trFormat('contactLabel', {
                                'value':
                                    '${item.contactName} · ${item.contactEmail}',
                              }),
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => launchUrl(
                                Uri.parse(item.sourceUrl),
                                mode: LaunchMode.externalApplication,
                              ),
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                size: 16,
                              ),
                              label: Text(context.tr('verifyJobPage')),
                            ),
                          ),
                          if (item.reviewNotes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                context.trFormat('lastNote', {
                                  'note': item.reviewNotes,
                                }),
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: busy
                                      ? null
                                      : () => _review(item, false),
                                  icon: const Icon(Icons.close_rounded),
                                  label: Text(context.tr('reject')),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: busy
                                      ? null
                                      : () => _review(item, true),
                                  icon: busy
                                      ? const SizedBox.square(
                                          dimension: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.check_rounded),
                                  label: Text(context.tr('approve')),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSelectorCard extends StatelessWidget {
  const _LanguageSelectorCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.translate_rounded, color: _green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('language'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              context.tr('languageHelp'),
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            ValueListenableBuilder<AppLanguage>(
              valueListenable: AppLanguageController.language,
              builder: (context, language, _) => SizedBox(
                width: double.infinity,
                child: SegmentedButton<AppLanguage>(
                  showSelectedIcon: false,
                  segments: AppLanguage.values
                      .map(
                        (item) => ButtonSegment<AppLanguage>(
                          value: item,
                          label: Text(item.shortLabel),
                          tooltip: item.label,
                        ),
                      )
                      .toList(),
                  selected: {language},
                  onSelectionChanged: (selection) async {
                    await AppLanguageController.setLanguage(selection.single);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountActions extends StatelessWidget {
  const _AccountActions({
    required this.onSignIn,
    required this.onSignOut,
    required this.onDeleteAccount,
    required this.onReplayTutorial,
    required this.onOpenPrivacy,
    required this.isAdmin,
    required this.onOpenAdmin,
  });

  final VoidCallback onSignIn;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;
  final VoidCallback onReplayTutorial;
  final VoidCallback onOpenPrivacy;
  final bool isAdmin;
  final VoidCallback onOpenAdmin;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('accountPrivacy'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              user?.email ?? context.tr('guestNavigation'),
              style: const TextStyle(color: _muted, fontSize: 10),
            ),
            const SizedBox(height: 14),
            if (isAdmin) ...[
              FilledButton.tonalIcon(
                onPressed: onOpenAdmin,
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                label: Text(context.tr('moderateJobs')),
              ),
              const SizedBox(height: 8),
            ],
            if (user == null)
              FilledButton.icon(
                onPressed: onSignIn,
                icon: const Icon(Icons.login_rounded, size: 17),
                label: Text(context.tr('signInSync')),
              )
            else
              OutlinedButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded, size: 17),
                label: Text(context.tr('signOut')),
              ),
            TextButton.icon(
              onPressed: onOpenPrivacy,
              icon: const Icon(Icons.privacy_tip_outlined, size: 17),
              label: Text(context.tr('privacyPolicy')),
            ),
            TextButton.icon(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'Werkly',
                applicationVersion: '1.0.0',
                applicationLegalese: context.tr('legalAttribution'),
              ),
              icon: const Icon(Icons.description_outlined, size: 17),
              label: Text(context.tr('legal')),
            ),
            TextButton.icon(
              onPressed: onReplayTutorial,
              icon: const Icon(Icons.school_outlined, size: 17),
              label: Text(context.tr('replayTutorial')),
            ),
            if (user != null)
              TextButton.icon(
                onPressed: onDeleteAccount,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 17),
                label: Text(context.tr('deleteAccount')),
              ),
          ],
        ),
      ),
    );
  }
}

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
      final reply = await _repository.askAi(
        message: message,
        profile: widget.profile,
        selectedJob: _jobContext(widget.selectedJob),
        bestMatches: ranked.take(5).map(_matchContext).toList(),
      );
      if (mounted) setState(() => _messages.add((false, reply)));
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
                              : context.tr('assistantGeminiMode'),
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

class _EmployerJobDraft {
  const _EmployerJobDraft({
    required this.companyName,
    required this.contactName,
    required this.contactEmail,
    required this.title,
    required this.location,
    required this.remoteType,
    required this.sourceUrl,
    required this.tags,
    required this.description,
    this.salaryMin,
    this.salaryMax,
  });

  final String companyName;
  final String contactName;
  final String contactEmail;
  final String title;
  final String location;
  final String remoteType;
  final double? salaryMin;
  final double? salaryMax;
  final String sourceUrl;
  final List<String> tags;
  final String description;
}

class _EmployerJobForm extends StatefulWidget {
  const _EmployerJobForm({required this.initialEmail});

  final String initialEmail;

  @override
  State<_EmployerJobForm> createState() => _EmployerJobFormState();
}

class _EmployerJobFormState extends State<_EmployerJobForm> {
  final _formKey = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _contact = TextEditingController();
  late final TextEditingController _email;
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _salaryMin = TextEditingController();
  final _salaryMax = TextEditingController();
  final _url = TextEditingController();
  final _tags = TextEditingController();
  final _description = TextEditingController();
  String _remoteType = 'onsite';

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _company.dispose();
    _contact.dispose();
    _email.dispose();
    _title.dispose();
    _location.dispose();
    _salaryMin.dispose();
    _salaryMax.dispose();
    _url.dispose();
    _tags.dispose();
    _description.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? context.tr('requiredField')
        : null;
  }

  double? _number(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _EmployerJobDraft(
        companyName: _company.text.trim(),
        contactName: _contact.text.trim(),
        contactEmail: _email.text.trim(),
        title: _title.text.trim(),
        location: _location.text.trim(),
        remoteType: _remoteType,
        salaryMin: _number(_salaryMin.text),
        salaryMax: _number(_salaryMax.text),
        sourceUrl: _url.text.trim(),
        tags: _tags.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
        description: _description.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('publishWerkstudentJob')),
      content: SizedBox(
        width: 590,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .68,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('employerSubmissionNotice'),
                    style: const TextStyle(color: _muted, height: 1.35),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _company,
                    validator: _required,
                    decoration: InputDecoration(
                      labelText: '${context.tr('company')} *',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _contact,
                    validator: _required,
                    decoration: InputDecoration(
                      labelText: '${context.tr('contactPerson')} *',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final required = _required(value);
                      if (required != null) return required;
                      return value!.contains('@')
                          ? null
                          : context.tr('invalidEmail');
                    },
                    decoration: InputDecoration(
                      labelText: '${context.tr('professionalEmail')} *',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _title,
                    validator: _required,
                    decoration: InputDecoration(
                      labelText: '${context.tr('jobTitle')} *',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _location,
                    validator: _required,
                    decoration: InputDecoration(
                      labelText: '${context.tr('germanCity')} *',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _remoteType,
                    decoration: InputDecoration(
                      labelText: context.tr('workMode'),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'onsite',
                        child: Text(context.tr('onSite')),
                      ),
                      DropdownMenuItem(
                        value: 'hybrid',
                        child: Text(context.tr('hybrid')),
                      ),
                      DropdownMenuItem(
                        value: 'remote',
                        child: Text(context.tr('remote')),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _remoteType = value ?? _remoteType),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _salaryMin,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) =>
                              value!.trim().isEmpty || _number(value) != null
                              ? null
                              : context.tr('invalidNumber'),
                          decoration: InputDecoration(
                            labelText: context.tr('minimumSalary'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _salaryMax,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value!.trim().isEmpty) return null;
                            final maximum = _number(value);
                            if (maximum == null) {
                              return context.tr('invalidNumber');
                            }
                            final minimum = _number(_salaryMin.text);
                            return minimum != null && maximum < minimum
                                ? context.tr('belowMinimum')
                                : null;
                          },
                          decoration: InputDecoration(
                            labelText: context.tr('maximumSalary'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _url,
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      final required = _required(value);
                      if (required != null) return required;
                      final uri = Uri.tryParse(value!.trim());
                      return uri != null && uri.scheme == 'https'
                          ? null
                          : context.tr('httpsRequired');
                    },
                    decoration: InputDecoration(
                      labelText: '${context.tr('officialApplicationLink')} *',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _tags,
                    decoration: InputDecoration(
                      labelText: context.tr('jobSkills'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _description,
                    minLines: 4,
                    maxLines: 7,
                    validator: (value) => (value?.trim().length ?? 0) < 40
                        ? context.tr('minimumDescription')
                        : null,
                    decoration: InputDecoration(
                      labelText: '${context.tr('jobDescription')} *',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.send_rounded, size: 18),
          label: Text(context.tr('submitForReview')),
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
