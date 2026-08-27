import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_language.dart';
import '../services/job_description_formatter.dart';

/// Thrown when `ai-assistant` reports the free hourly quota is exhausted, so
/// callers can show that specific, recoverable state instead of treating it
/// like any other failure.
class AiQuotaExceededException implements Exception {
  const AiQuotaExceededException(this.message, {this.retryAfterSeconds});

  final String message;
  final int? retryAfterSeconds;
}

/// Parses the `ai-assistant` edge function's response. Pulled out of
/// [WerklyRepository.askAi] as a pure function (no [SupabaseClient] involved)
/// so it's directly unit-testable.
(String, int?) parseAskAiResponse(
  int status,
  Object? data, {
  required String unavailableMessage,
  required String noResponseMessage,
}) {
  if (status == 429 && data is Map) {
    final message = data['error'];
    throw AiQuotaExceededException(
      message is String ? message : unavailableMessage,
      retryAfterSeconds: (data['retryAfterSeconds'] as num?)?.toInt(),
    );
  }
  if (status < 200 || status >= 300 || data is! Map) {
    throw Exception(unavailableMessage);
  }
  final reply = data['reply'];
  if (reply is! String || reply.trim().isEmpty) {
    final error = data['error'];
    throw Exception(error is String ? error : noResponseMessage);
  }
  final remaining = (data['remainingHourlyRequests'] as num?)?.toInt();
  return (reply.trim(), remaining);
}

class UserProfileData {
  const UserProfileData({
    required this.fullName,
    required this.university,
    required this.degree,
    required this.city,
    required this.professionalSummary,
    required this.skills,
    required this.preferences,
    required this.profileCompletion,
    required this.cvAnalysis,
    required this.cvAnalysisStatus,
    required this.cvAnalysisError,
    this.cvPath,
    this.cvAnalyzedAt,
  });

  factory UserProfileData.guest() => const UserProfileData(
    fullName: '',
    university: '',
    degree: '',
    city: 'München',
    professionalSummary: '',
    skills: [],
    preferences: {},
    profileCompletion: 20,
    cvAnalysis: {},
    cvAnalysisStatus: 'not_started',
    cvAnalysisError: '',
  );

  factory UserProfileData.fromRow(Map<String, dynamic>? row) {
    if (row == null) return UserProfileData.guest();
    final rawSkills = row['skills'];
    return UserProfileData(
      fullName: (row['full_name'] as String? ?? '').trim(),
      university: (row['university'] as String? ?? '').trim(),
      degree: (row['degree'] as String? ?? '').trim(),
      city: (row['city'] as String? ?? 'München').trim(),
      professionalSummary: (row['professional_summary'] as String? ?? '')
          .trim(),
      skills: rawSkills is List
          ? rawSkills
                .map((value) => value is Map ? value['name'] : value)
                .whereType<String>()
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toList()
          : const [],
      preferences: row['preferences'] is Map
          ? Map<String, dynamic>.from(row['preferences'] as Map)
          : const {},
      cvPath: row['cv_path'] as String?,
      cvAnalysis: row['cv_analysis'] is Map
          ? Map<String, dynamic>.from(row['cv_analysis'] as Map)
          : const {},
      cvAnalysisStatus: (row['cv_analysis_status'] as String? ?? 'not_started')
          .trim(),
      cvAnalysisError: (row['cv_analysis_error'] as String? ?? '').trim(),
      cvAnalyzedAt: DateTime.tryParse(row['cv_analyzed_at'] as String? ?? ''),
      profileCompletion: (row['profile_completion'] as num?)?.toInt() ?? 20,
    );
  }

  final String fullName;
  final String university;
  final String degree;
  final String city;
  final String professionalSummary;
  final List<String> skills;
  final Map<String, dynamic> preferences;
  final String? cvPath;
  final Map<String, dynamic> cvAnalysis;
  final String cvAnalysisStatus;
  final String cvAnalysisError;
  final DateTime? cvAnalyzedAt;
  final int profileCompletion;

  UserProfileData copyWith({
    String? fullName,
    String? university,
    String? degree,
    String? city,
    String? professionalSummary,
    List<String>? skills,
    Map<String, dynamic>? preferences,
    String? cvPath,
    Map<String, dynamic>? cvAnalysis,
    String? cvAnalysisStatus,
    String? cvAnalysisError,
    DateTime? cvAnalyzedAt,
    int? profileCompletion,
  }) => UserProfileData(
    fullName: fullName ?? this.fullName,
    university: university ?? this.university,
    degree: degree ?? this.degree,
    city: city ?? this.city,
    professionalSummary: professionalSummary ?? this.professionalSummary,
    skills: skills ?? this.skills,
    preferences: preferences ?? this.preferences,
    cvPath: cvPath ?? this.cvPath,
    cvAnalysis: cvAnalysis ?? this.cvAnalysis,
    cvAnalysisStatus: cvAnalysisStatus ?? this.cvAnalysisStatus,
    cvAnalysisError: cvAnalysisError ?? this.cvAnalysisError,
    cvAnalyzedAt: cvAnalyzedAt ?? this.cvAnalyzedAt,
    profileCompletion: profileCompletion ?? this.profileCompletion,
  );

  Map<String, dynamic> toRow() => {
    'full_name': fullName.trim(),
    'university': university.trim(),
    'degree': degree.trim(),
    'city': city.trim(),
    'professional_summary': professionalSummary.trim(),
    'skills': skills
        .map((skill) => {'name': skill.trim(), 'level': 'declared'})
        .toList(),
    'preferences': preferences,
    'cv_analysis': cvAnalysis,
    'cv_analysis_status': cvAnalysisStatus,
    'cv_analysis_error': cvAnalysisError,
    'cv_analyzed_at': cvAnalyzedAt?.toUtc().toIso8601String(),
    'profile_completion': profileCompletion.clamp(0, 100),
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  };
}

class UserWorkspaceState {
  const UserWorkspaceState({
    required this.jobs,
    required this.favoriteJobIds,
    required this.applications,
    required this.profile,
  });

  final List<Map<String, dynamic>> jobs;
  final Set<int> favoriteJobIds;
  final Map<int, String> applications;
  final UserProfileData profile;
}

class EmployerSubmissionData {
  const EmployerSubmissionData({
    required this.id,
    required this.companyName,
    required this.contactName,
    required this.contactEmail,
    required this.title,
    required this.location,
    required this.remoteType,
    required this.sourceUrl,
    required this.tags,
    required this.description,
    required this.status,
    required this.reviewNotes,
    required this.createdAt,
    this.salaryMin,
    this.salaryMax,
    this.reviewedAt,
  });

  factory EmployerSubmissionData.fromRow(Map<String, dynamic> row) =>
      EmployerSubmissionData(
        id: row['id']?.toString() ?? '',
        companyName: formatExternalText(row['company_name']?.toString() ?? ''),
        contactName: formatExternalText(row['contact_name']?.toString() ?? ''),
        contactEmail: row['contact_email']?.toString() ?? '',
        title: formatExternalText(row['title']?.toString() ?? ''),
        location: formatExternalText(row['location']?.toString() ?? ''),
        remoteType: row['remote_type']?.toString() ?? 'onsite',
        salaryMin: (row['salary_min'] as num?)?.toDouble(),
        salaryMax: (row['salary_max'] as num?)?.toDouble(),
        sourceUrl: row['source_url']?.toString() ?? '',
        tags: List<String>.from(
          row['tags'] as List? ?? const [],
        ).map(formatExternalText).where((tag) => tag.isNotEmpty).toList(),
        description: formatJobDescription(row['description']?.toString() ?? ''),
        status: row['status']?.toString() ?? 'pending',
        reviewNotes: row['review_notes']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(row['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        reviewedAt: DateTime.tryParse(row['reviewed_at']?.toString() ?? ''),
      );

  final String id;
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
  final String status;
  final String reviewNotes;
  final DateTime createdAt;
  final DateTime? reviewedAt;
}

class WerklyRepository {
  WerklyRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  static const _guestFavoritesKey = 'werkly_guest_favorites';
  static const _guestApplicationsKey = 'werkly_guest_applications';
  static const _guestProfileKey = 'werkly_guest_profile';
  static const _lastFreeJobsSyncKey = 'werkly_last_free_jobs_sync';
  static const _onboardingCompleteKey = 'werkly_onboarding_complete';
  static const _tutorialCompleteKey = 'werkly_tutorial_v2_complete';

  final SupabaseClient _client;

  String _tr(String key, [Map<String, Object> values = const {}]) {
    final strings = AppStrings(AppLanguageController.language.value);
    return values.isEmpty ? strings.get(key) : strings.format(key, values);
  }

  User? get currentUser => _client.auth.currentUser;
  bool get isAdmin => currentUser?.appMetadata['role'] == 'admin';

  Future<bool> isOnboardingComplete() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_onboardingCompleteKey) ?? false;
  }

  Future<void> setOnboardingComplete(bool complete) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_onboardingCompleteKey, complete);
  }

  Future<bool> isTutorialComplete() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_tutorialCompleteKey) ?? false;
  }

  Future<void> setTutorialComplete(bool complete) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_tutorialCompleteKey, complete);
  }

  Future<UserWorkspaceState> loadWorkspace({bool forceSync = false}) async {
    await _syncFreeJobsIfDue(force: forceSync);
    final jobsResult = await _client
        .from('jobs')
        .select(
          'id,title,company,location,latitude,longitude,remote_type,salary_min,salary_max,source,source_url,tags,description,posted_at',
        )
        .eq('active', true)
        .order('posted_at', ascending: false);
    final jobs = (jobsResult as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    final user = currentUser;
    if (user == null) {
      final guest = await _loadGuestState();
      final guestProfile = await _loadGuestProfile();
      return UserWorkspaceState(
        jobs: jobs,
        favoriteJobIds: guest.$1,
        applications: guest.$2,
        profile: guestProfile,
      );
    }

    await _mergeGuestState(user.id);
    final results = await Future.wait<dynamic>([
      _client.from('favorites').select('job_id').eq('user_id', user.id),
      _client
          .from('applications')
          .select('job_id,status')
          .eq('user_id', user.id),
      _client.from('profiles').select().eq('id', user.id).maybeSingle(),
    ]);
    final favorites = (results[0] as List)
        .map((row) => (row as Map<String, dynamic>)['job_id'] as int)
        .toSet();
    final applications = <int, String>{};
    for (final item in results[1] as List) {
      final row = item as Map<String, dynamic>;
      applications[row['job_id'] as int] = row['status'] as String;
    }
    final profileRow = results[2] == null
        ? null
        : Map<String, dynamic>.from(results[2] as Map);
    return UserWorkspaceState(
      jobs: jobs,
      favoriteJobIds: favorites,
      applications: applications,
      profile: UserProfileData.fromRow(profileRow),
    );
  }

  Future<void> setFavorite(int jobId, {required bool favorite}) async {
    final user = currentUser;
    if (user == null) {
      final state = await _loadGuestState();
      favorite ? state.$1.add(jobId) : state.$1.remove(jobId);
      await _saveGuestState(state.$1, state.$2);
      return;
    }
    if (favorite) {
      await _client.from('favorites').upsert({
        'user_id': user.id,
        'job_id': jobId,
      });
    } else {
      await _client
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('job_id', jobId);
    }
  }

  Future<void> setApplication(int jobId, {required bool applied}) => applied
      ? setApplicationStatus(jobId, 'applied')
      : removeApplication(jobId);

  Future<void> setApplicationStatus(int jobId, String status) async {
    const allowed = {'preparing', 'applied', 'interview', 'offer', 'rejected'};
    if (!allowed.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Statut non pris en charge');
    }
    final user = currentUser;
    if (user == null) {
      final state = await _loadGuestState();
      state.$2[jobId] = status;
      await _saveGuestState(state.$1, state.$2);
      return;
    }
    await _client.from('applications').upsert({
      'user_id': user.id,
      'job_id': jobId,
      'status': status,
      'applied_at': status == 'applied'
          ? DateTime.now().toUtc().toIso8601String()
          : null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> removeApplication(int jobId) async {
    final user = currentUser;
    if (user == null) {
      final state = await _loadGuestState();
      state.$2.remove(jobId);
      await _saveGuestState(state.$1, state.$2);
      return;
    }
    await _client
        .from('applications')
        .delete()
        .eq('user_id', user.id)
        .eq('job_id', jobId);
  }

  Future<UserProfileData> saveProfile(UserProfileData profile) async {
    final user = currentUser;
    if (user == null) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _guestProfileKey,
        jsonEncode(profile.toRow()),
      );
      return profile;
    }
    final row = await _client
        .from('profiles')
        .update(profile.toRow())
        .eq('id', user.id)
        .select()
        .maybeSingle();
    if (row == null) {
      throw AuthException(_tr('errorProfileNotFound'));
    }
    return UserProfileData.fromRow(Map<String, dynamic>.from(row));
  }

  Future<String> uploadCv({
    required Uint8List bytes,
    required String extension,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw AuthException(_tr('errorSignInAddCv'));
    }
    final normalized = extension.toLowerCase().replaceAll('.', '');
    if (normalized != 'pdf') {
      throw FormatException(_tr('errorPdfRequired'));
    }
    final path = '${user.id}/cv.$normalized';
    await _client.storage
        .from('cvs')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    await _client
        .from('profiles')
        .update({
          'cv_path': path,
          'cv_analysis': <String, dynamic>{},
          'cv_analysis_status': 'not_started',
          'cv_analysis_error': '',
          'cv_analyzed_at': null,
          'profile_completion': 65,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id);
    return path;
  }

  Future<UserProfileData> analyzeCv() async {
    if (currentUser == null) {
      throw AuthException(_tr('errorSignInAnalyzeCv'));
    }
    final response = await _client.functions.invoke(
      'analyze-cv',
      body: <String, dynamic>{
        'language': AppLanguageController.language.value.code,
      },
    );
    final data = response.data;
    if (response.status < 200 || response.status >= 300 || data is! Map) {
      final message = data is Map ? data['error'] : null;
      throw Exception(
        message is String ? message : _tr('errorCvAnalysisFailed'),
      );
    }
    final profile = data['profile'];
    if (profile is! Map) {
      throw Exception(_tr('errorInvalidAnalyzedProfile'));
    }
    return UserProfileData.fromRow(Map<String, dynamic>.from(profile));
  }

  Future<Uri> createCvViewUrl(String path) async {
    final user = currentUser;
    if (user == null) {
      throw AuthException(_tr('errorSignInViewCv'));
    }
    final normalized = path.trim();
    if (normalized.isEmpty || !normalized.startsWith('${user.id}/')) {
      throw FormatException(_tr('errorInvalidCvPath'));
    }
    final signedUrl = await _client.storage
        .from('cvs')
        .createSignedUrl(normalized, 300);
    return Uri.parse(signedUrl);
  }

  Future<void> submitEmployerJob({
    required String companyName,
    required String contactName,
    required String contactEmail,
    required String title,
    required String location,
    required String remoteType,
    required String sourceUrl,
    required List<String> tags,
    required String description,
    double? salaryMin,
    double? salaryMax,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw AuthException(_tr('errorSignInPublishJob'));
    }
    await _client.from('employer_job_submissions').insert({
      'submitted_by': user.id,
      'company_name': companyName.trim(),
      'contact_name': contactName.trim(),
      'contact_email': contactEmail.trim(),
      'title': title.trim(),
      'location': location.trim(),
      'remote_type': remoteType,
      'salary_min': salaryMin,
      'salary_max': salaryMax,
      'source_url': sourceUrl.trim(),
      'tags': tags
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .take(10)
          .toList(),
      'description': description.trim(),
    });
  }

  Future<List<EmployerSubmissionData>> loadEmployerSubmissions() async {
    if (!isAdmin) {
      throw AuthException(_tr('errorAdminRequired'));
    }
    final rows = await _client
        .from('employer_job_submissions')
        .select(
          'id,company_name,contact_name,contact_email,title,location,remote_type,salary_min,salary_max,source_url,tags,description,status,review_notes,created_at,reviewed_at',
        )
        .order('created_at', ascending: false);
    return (rows as List)
        .map(
          (row) => EmployerSubmissionData.fromRow(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<void> reviewEmployerSubmission({
    required String id,
    required bool approved,
    required String notes,
  }) async {
    if (!isAdmin) {
      throw AuthException(_tr('errorAdminRequired'));
    }
    await _client
        .from('employer_job_submissions')
        .update({
          'status': approved ? 'approved' : 'rejected',
          'review_notes': notes.trim(),
        })
        .eq('id', id);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> deleteAccount() async {
    final response = await _client.functions.invoke('delete-account');
    if (response.status < 200 || response.status >= 300) {
      throw Exception(_tr('errorDeleteAccountFailed'));
    }
    await _client.auth.signOut();
  }

  Future<(String, int?)> askAi({
    required String message,
    required UserProfileData profile,
    required Map<String, dynamic> selectedJob,
    required List<Map<String, dynamic>> bestMatches,
  }) async {
    if (currentUser == null) {
      throw AuthException(_tr('errorSignInUseAi'));
    }
    final rawExperiences = profile.cvAnalysis['experiences'];
    final response = await _client.functions.invoke(
      'ai-assistant',
      body: {
        'language': AppLanguageController.language.value.code,
        'message': message,
        'profile': {
          'degree': profile.degree,
          'university': profile.university,
          'city': profile.city,
          'summary': profile.professionalSummary,
          'skills': profile.skills,
          'preferences': profile.preferences,
          // Real past roles from the CV scan (title/organization/period/
          // highlights), so a generated letter can reference actual work
          // history instead of writing generically.
          'experiences': rawExperiences is List
              ? rawExperiences.whereType<Map>().toList()
              : const [],
        },
        'job': selectedJob,
        'jobs': bestMatches,
      },
    );
    return parseAskAiResponse(
      response.status,
      response.data,
      unavailableMessage: _tr('errorAssistantUnavailable'),
      noResponseMessage: _tr('errorAiNoResponse'),
    );
  }

  Future<void> reportAiContent({
    required String content,
    required String reason,
    String details = '',
  }) async {
    final user = currentUser;
    if (user == null) {
      throw AuthException(_tr('errorSignInReportAi'));
    }
    final normalizedContent = content.trim();
    if (normalizedContent.isEmpty) {
      throw ArgumentError.value(content, 'content', 'Empty AI content');
    }
    const allowedReasons = {'inaccurate', 'offensive', 'unsafe', 'other'};
    if (!allowedReasons.contains(reason)) {
      throw ArgumentError.value(reason, 'reason', 'Unsupported reason');
    }
    final normalizedDetails = details.trim();
    await _client.from('ai_content_reports').insert({
      'user_id': user.id,
      'message_excerpt': normalizedContent.length > 4000
          ? normalizedContent.substring(0, 4000)
          : normalizedContent,
      'reason': reason,
      'details': normalizedDetails.isEmpty
          ? null
          : (normalizedDetails.length > 1000
                ? normalizedDetails.substring(0, 1000)
                : normalizedDetails),
    });
  }

  Future<bool?> getAiPrivacyChoice() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool('werkly_ai_privacy_accepted');
  }

  Future<void> setAiPrivacyChoice(bool accepted) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('werkly_ai_privacy_accepted', accepted);
  }

  Future<bool?> getCvAnalysisPrivacyChoice() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool('werkly_cv_analysis_privacy_accepted');
  }

  Future<void> setCvAnalysisPrivacyChoice(bool accepted) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('werkly_cv_analysis_privacy_accepted', accepted);
    final user = currentUser;
    if (user != null) {
      await _client
          .from('profiles')
          .update({
            'cv_ai_consent_at': accepted
                ? DateTime.now().toUtc().toIso8601String()
                : null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', user.id);
    }
  }

  Future<void> _syncFreeJobsIfDue({bool force = false}) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final lastValue = preferences.getString(_lastFreeJobsSyncKey);
      final last = lastValue == null ? null : DateTime.tryParse(lastValue);
      if (!force &&
          last != null &&
          DateTime.now().difference(last).inMinutes < 30) {
        return;
      }
      final response = await _client.functions
          .invoke('sync-free-jobs', body: const {})
          .timeout(const Duration(seconds: 60));
      if (response.status >= 200 && response.status < 300) {
        await preferences.setString(
          _lastFreeJobsSyncKey,
          DateTime.now().toUtc().toIso8601String(),
        );
      } else if (force) {
        throw StateError(
          _tr('errorRefreshRejected', {'status': response.status}),
        );
      }
    } catch (_) {
      if (force) rethrow;
      // L'application reste utilisable avec les offres déjà mises en cache.
    }
  }

  Future<(Set<int>, Map<int, String>)> _loadGuestState() async {
    final preferences = await SharedPreferences.getInstance();
    final favorites =
        (preferences.getStringList(_guestFavoritesKey) ?? const [])
            .map(int.tryParse)
            .whereType<int>()
            .toSet();
    final encodedApplications =
        preferences.getString(_guestApplicationsKey) ?? '{}';
    final decoded = jsonDecode(encodedApplications);
    final applications = <int, String>{};
    if (decoded is Map) {
      for (final entry in decoded.entries) {
        final id = int.tryParse(entry.key.toString());
        if (id != null && entry.value is String) {
          applications[id] = entry.value as String;
        }
      }
    }
    return (favorites, applications);
  }

  Future<UserProfileData> _loadGuestProfile() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_guestProfileKey);
    if (encoded == null || encoded.isEmpty) return UserProfileData.guest();
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is Map) {
        return UserProfileData.fromRow(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Un profil local invalide ne doit jamais bloquer l'application.
    }
    return UserProfileData.guest();
  }

  Future<void> _saveGuestState(
    Set<int> favorites,
    Map<int, String> applications,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _guestFavoritesKey,
      favorites.map((id) => id.toString()).toList()..sort(),
    );
    await preferences.setString(
      _guestApplicationsKey,
      jsonEncode(applications.map((key, value) => MapEntry('$key', value))),
    );
  }

  Future<void> _mergeGuestState(String userId) async {
    final state = await _loadGuestState();
    final guestProfile = await _loadGuestProfile();
    if (state.$1.isNotEmpty) {
      await _client
          .from('favorites')
          .upsert(
            state.$1
                .map((jobId) => {'user_id': userId, 'job_id': jobId})
                .toList(),
          );
    }
    if (state.$2.isNotEmpty) {
      await _client
          .from('applications')
          .upsert(
            state.$2.entries
                .map(
                  (entry) => {
                    'user_id': userId,
                    'job_id': entry.key,
                    'status': entry.value,
                    'updated_at': DateTime.now().toUtc().toIso8601String(),
                  },
                )
                .toList(),
          );
    }
    if (guestProfile.profileCompletion > 20) {
      final cloudProfile = await _client
          .from('profiles')
          .select('profile_completion')
          .eq('id', userId)
          .maybeSingle();
      final cloudCompletion =
          (cloudProfile?['profile_completion'] as num?)?.toInt() ?? 0;
      if (cloudCompletion <= 20) {
        await _client
            .from('profiles')
            .update(guestProfile.toRow())
            .eq('id', userId);
      }
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_guestProfileKey);
    }
    if (state.$1.isNotEmpty || state.$2.isNotEmpty) {
      await _saveGuestState(<int>{}, <int, String>{});
    }
  }
}
