import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('free job sync uses public sources and safe snapshots', () {
    final source = File(
      'supabase/functions/sync-free-jobs/index.ts',
    ).readAsStringSync();

    expect(source, contains('https://www.arbeitnow.com/api/job-board-api'));
    expect(source, contains('https://api.smartrecruiters.com/v1/companies/'));
    expect(source, contains("source: 'Arbeitnow'"));
    expect(source, contains("source: 'SmartRecruiters'"));
    expect(source, contains('last_seen_at: runStarted'));
    expect(source, contains(".lt('last_seen_at', runStarted)"));
    expect(source, contains('jobFingerprint(row)'));
    expect(source, contains('sourcePriority(left.source)'));
    expect(source, isNot(contains('linkedin.com/jobs')));
    expect(source, isNot(contains('indeed.com/jobs')));
    expect(source, isNot(contains('stepstone.de/jobs')));
  });

  test('job snapshot migration is reproducible and scheduled twice daily', () {
    final migration = File(
      'supabase/migrations/'
      '20260815180000_add_job_last_seen_and_reschedule_sync.sql',
    ).readAsStringSync();
    final config = File('supabase/config.toml').readAsStringSync();

    expect(migration, contains('add column if not exists last_seen_at'));
    expect(migration, contains('alter column last_seen_at set not null'));
    expect(migration, contains('jobs_source_last_seen_at_idx'));
    expect(migration, contains('claim_free_job_sync'));
    expect(migration, contains("interval '10 minutes'"));
    expect(migration, contains("'17 3,15 * * *'"));
    expect(migration, contains('timeout_milliseconds := 60000'));
    expect(config, contains('[functions.sync-free-jobs]'));
    expect(config, contains('verify_jwt = false'));
  });
}
