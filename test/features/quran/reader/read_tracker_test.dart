import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/features/quran/reader/read_tracker.dart';

/// Dwell logika citatela (docs/02 A5.2): 2,5 s, len v popredi, raz.
/// `testWidgets` kvoli falosnym casovacom (`tester.pump`).
void main() {
  group('ReadTracker', () {
    testWidgets('reports a verse after the dwell, once', (tester) async {
      final read = <int>[];
      final t = ReadTracker(onRead: read.add)..update({2, 1});
      await tester.pump(const Duration(milliseconds: 2499));
      expect(read, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(read, [1, 2]);
      t.update({1, 2, 3});
      await tester.pump(const Duration(seconds: 3));
      expect(read, [1, 2, 3]);
      expect(t.reported, {1, 2, 3});
      t.dispose();
    });

    testWidgets('verse leaving the screen restarts its dwell', (tester) async {
      final read = <int>[];
      final t = ReadTracker(onRead: read.add)..update({5});
      await tester.pump(const Duration(seconds: 2));
      t.update(const {});
      expect(t.pending, isEmpty);
      t.update({5});
      await tester.pump(const Duration(seconds: 2));
      expect(read, isEmpty);
      await tester.pump(const Duration(seconds: 1));
      expect(read, [5]);
      t.dispose();
    });

    testWidgets('pause cancels, resume starts visible verses from zero', (
      tester,
    ) async {
      final read = <int>[];
      final t = ReadTracker(onRead: read.add)..update({7});
      await tester.pump(const Duration(seconds: 2));
      t
        ..pause()
        ..update({7, 8});
      await tester.pump(const Duration(seconds: 5));
      expect(read, isEmpty);
      t
        ..resume()
        ..resume();
      await tester.pump(const Duration(seconds: 3));
      expect(read, [7, 8]);
      t.dispose();
    });

    testWidgets('dispose stops everything', (tester) async {
      final read = <int>[];
      ReadTracker(onRead: read.add)
        ..update({1})
        ..dispose()
        ..update({2});
      await tester.pump(const Duration(seconds: 5));
      expect(read, isEmpty);
    });
  });

  group('visibleFractionOf', () {
    double f(double top, double bottom) => visibleFractionOf(
      top: top,
      bottom: bottom,
      viewTop: 0,
      viewBottom: 100,
    );

    test('fully, partly and not visible rows', () {
      expect(f(10, 50), 1);
      expect(f(-20, 20), 0.5);
      expect(f(80, 120), 0.5);
      expect(f(100, 140), 0);
      expect(f(-50, -10), 0);
      expect(f(10, 10), 0);
    });

    test('row taller than the viewport counts against the viewport', () {
      expect(f(-100, 300), 1);
      expect(f(40, 400), closeTo(0.6, 1e-9));
      expect(
        visibleFractionOf(top: 0, bottom: 10, viewTop: 0, viewBottom: 0),
        0,
      );
    });
  });
}
