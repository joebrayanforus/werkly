import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_language.dart';

class JobAlertCandidate {
  const JobAlertCandidate({
    required this.id,
    required this.title,
    required this.company,
    required this.match,
    required this.postedAt,
  });

  final int id;
  final String title;
  final String company;
  final int match;
  final DateTime? postedAt;
}

class WerklyNotification {
  const WerklyNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.createdAt,
    this.jobId,
    this.dueAt,
    this.readAt,
    this.jobTitle,
    this.company,
    this.match,
  });

  factory WerklyNotification.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] as String? ?? 'info';
    final title = json['title'] as String? ?? 'Werkly';
    final message = json['message'] as String? ?? '';
    var jobTitle = json['job_title'] as String?;
    var company = json['company'] as String?;
    var match = (json['match'] as num?)?.toInt();

    // Upgrade notifications created by older app versions so they also follow
    // the currently selected language.
    if ((jobTitle == null || company == null) &&
        (kind == 'job' || kind == 'reminder')) {
      for (final separator in const [' chez ', ' bei ', ' at ']) {
        final separatorIndex = message.lastIndexOf(separator);
        if (separatorIndex > 0) {
          jobTitle ??= message.substring(0, separatorIndex).trim();
          company ??= message
              .substring(separatorIndex + separator.length)
              .trim();
          break;
        }
      }
    }
    match ??= int.tryParse(
      RegExp(r'(\d+)\s*%').firstMatch(title)?.group(1) ?? '',
    );

    return WerklyNotification(
      id: json['id'] as String? ?? '',
      kind: kind,
      title: title,
      message: message,
      jobId: (json['job_id'] as num?)?.toInt(),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      dueAt: DateTime.tryParse(json['due_at'] as String? ?? ''),
      readAt: DateTime.tryParse(json['read_at'] as String? ?? ''),
      jobTitle: jobTitle,
      company: company,
      match: match,
    );
  }

  final String id;
  final String kind;
  final String title;
  final String message;
  final int? jobId;
  final DateTime createdAt;
  final DateTime? dueAt;
  final DateTime? readAt;
  final String? jobTitle;
  final String? company;
  final int? match;

  bool get unread => readAt == null;
  bool isDue([DateTime? now]) =>
      dueAt == null || !dueAt!.isAfter(now ?? DateTime.now());

  WerklyNotification copyWith({DateTime? readAt}) => WerklyNotification(
    id: id,
    kind: kind,
    title: title,
    message: message,
    jobId: jobId,
    createdAt: createdAt,
    dueAt: dueAt,
    readAt: readAt ?? this.readAt,
    jobTitle: jobTitle,
    company: company,
    match: match,
  );

  String localizedTitle(AppLanguage language) {
    final strings = AppStrings(language);
    if (kind == 'job') {
      return (match ?? 0) > 0
          ? strings.format('notificationNewJobMatch', {'match': match!})
          : strings.get('newJob');
    }
    if (kind == 'reminder') return strings.get('applicationReminderTitle');
    return title;
  }

  String localizedMessage(AppLanguage language) {
    if ((jobTitle ?? '').isEmpty || (company ?? '').isEmpty) return message;
    return AppStrings(language).format('notificationJobAtCompany', {
      'job': jobTitle!,
      'company': company!,
    });
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'title': title,
    'message': message,
    'job_id': jobId,
    'created_at': createdAt.toUtc().toIso8601String(),
    'due_at': dueAt?.toUtc().toIso8601String(),
    'read_at': readAt?.toUtc().toIso8601String(),
    'job_title': jobTitle,
    'company': company,
    'match': match,
  };
}

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();
  static const _itemsKey = 'werkly_notifications_v1';
  static const _lastJobScanKey = 'werkly_last_job_alert_scan';
  static const _systemEnabledKey = 'werkly_system_notifications_enabled';
  static const _channelId = 'werkly_reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final ValueNotifier<int?> openedJobId = ValueNotifier<int?>(null);
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
    try {
      await _plugin.initialize(
        settings: InitializationSettings(
          android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: const DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          macOS: const DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          linux: LinuxInitializationSettings(
            defaultActionName: AppStrings(
              AppLanguageController.language.value,
            ).get('openWerkly'),
          ),
          windows: const WindowsInitializationSettings(
            appName: 'Werkly',
            appUserModelId: 'Werkly.StudentJobs.App',
            guid: '5f3e1050-c6e9-4ed0-a471-e3914cb16f63',
          ),
          web: const WebInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: _handleResponse,
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      _handleResponse(launch?.notificationResponse);
    } catch (_) {
      // Le centre de notifications interne continue de fonctionner même si
      // le système ne fournit pas de notifications natives.
    }
    _initialized = true;
  }

  void _handleResponse(NotificationResponse? response) {
    final value = int.tryParse(response?.payload ?? '');
    if (value != null) openedJobId.value = value;
  }

  Future<bool> requestSystemPermission() async {
    await initialize();
    bool granted = true;
    try {
      if (kIsWeb) {
        granted =
            await _plugin
                .resolvePlatformSpecificImplementation<
                  WebFlutterLocalNotificationsPlugin
                >()
                ?.requestNotificationsPermission() ??
            false;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        granted =
            await _plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.requestNotificationsPermission() ??
            true;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        granted =
            await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        granted =
            await _plugin
                .resolvePlatformSpecificImplementation<
                  MacOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      }
    } catch (_) {
      granted = false;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_systemEnabledKey, granted);
    return granted;
  }

  Future<bool> systemNotificationsEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_systemEnabledKey) ?? false;
  }

  Future<List<WerklyNotification>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_itemsKey);
    if (encoded == null || encoded.isEmpty) return <WerklyNotification>[];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return <WerklyNotification>[];
      final items =
          decoded
              .whereType<Map>()
              .map(
                (value) => WerklyNotification.fromJson(
                  Map<String, dynamic>.from(value),
                ),
              )
              .where((item) => item.id.isNotEmpty)
              .toList()
            ..sort(_compareNotifications);
      return items;
    } catch (_) {
      return <WerklyNotification>[];
    }
  }

  Future<List<WerklyNotification>> syncNewJobAlerts(
    List<JobAlertCandidate> candidates,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final storedScan = preferences.getString(_lastJobScanKey);
    final lastScan = DateTime.tryParse(storedScan ?? '');
    final now = DateTime.now();
    final cutoff = lastScan ?? now.subtract(const Duration(hours: 24));
    final items = await load();
    final knownIds = items.map((item) => item.id).toSet();
    final fresh =
        candidates
            .where(
              (candidate) =>
                  candidate.postedAt != null &&
                  candidate.postedAt!.isAfter(cutoff) &&
                  !knownIds.contains('job-${candidate.id}'),
            )
            .toList()
          ..sort((a, b) {
            final match = b.match.compareTo(a.match);
            if (match != 0) return match;
            return b.postedAt!.compareTo(a.postedAt!);
          });
    final created = <WerklyNotification>[];
    final strings = AppStrings(AppLanguageController.language.value);
    for (final candidate in fresh.take(5)) {
      final item = WerklyNotification(
        id: 'job-${candidate.id}',
        kind: 'job',
        title: candidate.match > 0
            ? strings.format('notificationNewJobMatch', {
                'match': candidate.match,
              })
            : strings.get('newJob'),
        message: strings.format('notificationJobAtCompany', {
          'job': candidate.title,
          'company': candidate.company,
        }),
        jobId: candidate.id,
        createdAt: now,
        jobTitle: candidate.title,
        company: candidate.company,
        match: candidate.match,
      );
      items.add(item);
      created.add(item);
    }
    await preferences.setString(_lastJobScanKey, now.toUtc().toIso8601String());
    if (created.isNotEmpty) await _save(items);
    if (await systemNotificationsEnabled()) {
      for (final item in created.take(2)) {
        await _showSystem(item);
      }
    }
    items.sort(_compareNotifications);
    return items;
  }

  Future<List<WerklyNotification>> scheduleReminder({
    required int jobId,
    required String jobTitle,
    required String company,
    required DateTime dueAt,
  }) async {
    final now = DateTime.now();
    final strings = AppStrings(AppLanguageController.language.value);
    final item = WerklyNotification(
      id: 'reminder-$jobId-${dueAt.millisecondsSinceEpoch}',
      kind: 'reminder',
      title: strings.get('applicationReminderTitle'),
      message: strings.format('notificationJobAtCompany', {
        'job': jobTitle,
        'company': company,
      }),
      jobId: jobId,
      createdAt: now,
      dueAt: dueAt,
      jobTitle: jobTitle,
      company: company,
    );
    final items = await load();
    items
      ..removeWhere(
        (existing) => existing.kind == 'reminder' && existing.jobId == jobId,
      )
      ..add(item);
    await _save(items);
    if (await systemNotificationsEnabled()) {
      await _scheduleSystem(item);
    }
    items.sort(_compareNotifications);
    return items;
  }

  Future<List<WerklyNotification>> addStatusReminder({
    required int jobId,
    required String jobTitle,
    required String company,
    required String status,
  }) async {
    if (status == 'rejected') return removeJobReminders(jobId);
    final now = DateTime.now();
    final dueAt = switch (status) {
      'applied' => now.add(const Duration(days: 7)),
      'interview' => now.add(const Duration(hours: 2)),
      'offer' => now.add(const Duration(days: 1)),
      _ => now.add(const Duration(days: 2)),
    };
    return scheduleReminder(
      jobId: jobId,
      jobTitle: jobTitle,
      company: company,
      dueAt: dueAt,
    );
  }

  Future<List<WerklyNotification>> removeJobReminders(int jobId) async {
    final items = await load();
    final removed = items
        .where((item) => item.kind == 'reminder' && item.jobId == jobId)
        .toList();
    items.removeWhere((item) => item.kind == 'reminder' && item.jobId == jobId);
    await _save(items);
    for (final item in removed) {
      try {
        await _plugin.cancel(id: _systemId(item.id));
      } catch (_) {}
    }
    return items;
  }

  Future<List<WerklyNotification>> markRead(String id) async {
    final now = DateTime.now();
    final items = (await load())
        .map((item) => item.id == id ? item.copyWith(readAt: now) : item)
        .toList();
    await _save(items);
    return items;
  }

  Future<List<WerklyNotification>> markAllRead() async {
    final now = DateTime.now();
    final items = (await load())
        .map((item) => item.unread ? item.copyWith(readAt: now) : item)
        .toList();
    await _save(items);
    return items;
  }

  Future<List<WerklyNotification>> delete(String id) async {
    final items = await load()
      ..removeWhere((item) => item.id == id);
    await _save(items);
    try {
      await _plugin.cancel(id: _systemId(id));
    } catch (_) {}
    return items;
  }

  Future<void> _save(List<WerklyNotification> items) async {
    items.sort(_compareNotifications);
    final limited = items.take(60).map((item) => item.toJson()).toList();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_itemsKey, jsonEncode(limited));
  }

  Future<void> _showSystem(WerklyNotification item) async {
    try {
      await _plugin.show(
        id: _systemId(item.id),
        title: item.localizedTitle(AppLanguageController.language.value),
        body: item.localizedMessage(AppLanguageController.language.value),
        payload: item.jobId?.toString(),
        notificationDetails: _details,
      );
    } catch (_) {}
  }

  Future<void> _scheduleSystem(WerklyNotification item) async {
    final dueAt = item.dueAt;
    if (dueAt == null) return;
    if (!dueAt.isAfter(DateTime.now())) {
      await _showSystem(item);
      return;
    }
    try {
      await _plugin.zonedSchedule(
        id: _systemId(item.id),
        title: item.localizedTitle(AppLanguageController.language.value),
        body: item.localizedMessage(AppLanguageController.language.value),
        payload: item.jobId?.toString(),
        scheduledDate: tz.TZDateTime.from(dueAt.toUtc(), tz.UTC),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Le rappel reste toujours visible dans le centre interne.
    }
  }

  NotificationDetails get _details {
    final strings = AppStrings(AppLanguageController.language.value);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        strings.get('notificationChannelName'),
        channelDescription: strings.get('notificationChannelDescription'),
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );
  }

  static int _systemId(String id) => id.hashCode & 0x7fffffff;

  static int _compareNotifications(WerklyNotification a, WerklyNotification b) {
    final aDate = a.dueAt ?? a.createdAt;
    final bDate = b.dueAt ?? b.createdAt;
    return bDate.compareTo(aDate);
  }
}
