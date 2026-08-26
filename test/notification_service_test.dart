import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:werkstudent_ai/l10n/app_language.dart';
import 'package:werkstudent_ai/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLanguageController.language.value = AppLanguage.en;
  });

  test('stores, reads and removes an application reminder', () async {
    final service = NotificationService.instance;
    final dueAt = DateTime.now().add(const Duration(days: 2));

    final scheduled = await service.scheduleReminder(
      jobId: 42,
      jobTitle: 'Werkstudent Flutter',
      company: 'Werkly Labs',
      dueAt: dueAt,
    );

    expect(scheduled, hasLength(1));
    expect(scheduled.single.jobId, 42);
    expect(scheduled.single.kind, 'reminder');
    expect(scheduled.single.unread, isTrue);

    final read = await service.markRead(scheduled.single.id);
    expect(read.single.unread, isFalse);

    final removed = await service.delete(scheduled.single.id);
    expect(removed, isEmpty);
  });

  test('creates deduplicated alerts for newly published jobs', () async {
    final service = NotificationService.instance;
    final candidate = JobAlertCandidate(
      id: 7,
      title: 'Werkstudent Data',
      company: 'Example AG',
      match: 88,
      postedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    final first = await service.syncNewJobAlerts([candidate]);
    final second = await service.syncNewJobAlerts([candidate]);

    expect(first.where((item) => item.id == 'job-7'), hasLength(1));
    expect(second.where((item) => item.id == 'job-7'), hasLength(1));
    final alert = second.singleWhere((item) => item.id == 'job-7');
    expect(alert.localizedTitle(AppLanguage.en), 'New job at 88%');
    expect(alert.localizedTitle(AppLanguage.de), 'Neuer Job mit 88 %');
    expect(
      alert.localizedMessage(AppLanguage.fr),
      'Werkstudent Data chez Example AG',
    );
  });

  test('localizes notifications saved by an older app version', () {
    final legacy = WerklyNotification.fromJson({
      'id': 'job-9',
      'kind': 'job',
      'title': 'Nouvelle offre à 74 %',
      'message': 'Werkstudent QA chez Example GmbH',
      'job_id': 9,
      'created_at': DateTime.utc(2026, 8, 15).toIso8601String(),
    });

    expect(legacy.localizedTitle(AppLanguage.en), 'New job at 74%');
    expect(
      legacy.localizedMessage(AppLanguage.de),
      'Werkstudent QA bei Example GmbH',
    );
  });
}
