@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/features/feed/feed_screen.dart';
import 'package:prosoche/features/today/today_screen.dart';
import 'package:prosoche/ui/theme/prosoche_theme.dart';

import '../../fakes/fake_repositories.dart';
import '../../helpers/golden/golden.dart';
import 'f02_harness.dart';

/// Goldeny obrazoviek Dnes a Feed (EN, AR, UR, BN x tema x 1.0/2.0; ID
/// a TR smoke) s fake repozitarmi.
///
///   flutter test --update-goldens test/features/today/today_golden_test.dart
void main() {
  ThemeData theme(Brightness b) =>
      b == Brightness.dark ? ProsocheTheme.dark() : ProsocheTheme.light();

  Widget screen(BuildContext context, FakeRepositories repos, Widget child) =>
      ProviderScope(
        retry: (_, _) => null,
        overrides: repos.overrides(
          now: f02Now,
          deviceLanguage: Localizations.localeOf(context).languageCode,
        ),
        child: SizedBox(width: 360, height: 640, child: child),
      );

  goldenAllLocales(
    'TodayScreen',
    fileName: 'today_screen',
    theme: theme,
    builder: (context) =>
        screen(context, FakeRepositories(), const TodayScreen()),
  );

  goldenAllLocales(
    'TodayScreen in progress',
    fileName: 'today_screen_in_progress',
    theme: theme,
    brightness: const [Brightness.light],
    builder: (context) {
      final repos = FakeRepositories();
      repos.dailySets.put(
        DailySetState(
          set: fakeDailySet(f02Today),
          cursor: 4,
          startedAt: DateTime(2026, 10, 29, 8),
        ),
      );
      return screen(context, repos, const TodayScreen());
    },
  );

  goldenAllLocales(
    'FeedScreen',
    fileName: 'feed_screen',
    theme: theme,
    builder: (context) {
      final repos = FakeRepositories();
      repos.dailySets.put(
        DailySetState(set: fakeDailySet(f02Today), cursor: 1),
      );
      return screen(context, repos, const FeedScreen());
    },
  );
}
