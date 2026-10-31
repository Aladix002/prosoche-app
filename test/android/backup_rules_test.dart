import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/db/journal_db.dart';
import 'package:prosoche/data/repositories/infra/databases.dart';

/// Android zaloha (C-02): user.db sa zalohuje, dennik (journal.db) nikdy,
/// ani do Google zalohy, ani pri prenose do noveho telefonu. Rovnaku
/// kontrolu robi `tool/check_manifest.sh --rules`.
void main() {
  const res = 'android/app/src/main/res';
  final extraction = File('$res/xml/data_extraction_rules.xml');
  final legacy = [
    File('$res/xml/backup_rules_legacy.xml'),
    File('$res/xml-v28/backup_rules_legacy.xml'),
  ];
  final includes = RegExp('<include[^>]*path="([^"]*)"');

  test('manifest points to both backup rule files', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
    expect(
      manifest,
      contains('android:fullBackupContent="@xml/backup_rules_legacy"'),
    );
  });

  test('journal.db is never included, user.db is', () {
    expect(journalDbFileName, isNot(userDbFileName));
    for (final f in [extraction, ...legacy]) {
      expect(f.existsSync(), isTrue, reason: f.path);
      final paths = [
        for (final m in includes.allMatches(f.readAsStringSync())) m[1]!,
      ];
      for (final path in paths) {
        expect(path, isNot(contains('journal')), reason: f.path);
        expect(path, isNot(anyOf('', '.', './', '/')), reason: f.path);
      }
    }
    final rules = extraction.readAsStringSync();
    expect(rules, contains('<cloud-backup'));
    expect(rules, contains('<device-transfer'));
    for (final section in ['cloud-backup', 'device-transfer']) {
      final body = RegExp(
        '<$section[^>]*>(.*?)</$section>',
        dotAll: true,
      ).firstMatch(rules)![1]!;
      expect(body, contains('path="$userDbFileName"'), reason: section);
      expect(body, isNot(contains(journalDbFileName)), reason: section);
    }
  });
}
