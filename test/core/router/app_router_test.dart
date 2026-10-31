import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/feed/feed_screen.dart';
import 'package:sakina/features/gate/gate_screen.dart';
import 'package:sakina/features/journey/journey_screen.dart';
import 'package:sakina/features/prayer/prayer_screen.dart';
import 'package:sakina/features/quran/quran_screen.dart';
import 'package:sakina/features/today/today_screen.dart';
import 'package:sakina/ui/gallery/sk_gallery_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('starts on Today with 4 tab bottom navigation', (tester) async {
    await tester.pumpSakina();
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(navBar, findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
  });

  testWidgets('switches tabs', (tester) async {
    await tester.pumpSakina();
    for (final (label, screen) in [
      ('Quran', QuranScreen),
      ('Prayer', PrayerScreen),
      ('Journey', JourneyScreen),
      ('Today', TodayScreen),
    ]) {
      await tester.tap(find.descendant(of: navBar, matching: find.text(label)));
      await tester.pumpAndSettle();
      expect(find.byType(screen), findsOneWidget);
    }
  });

  testWidgets('feed is fullscreen and back returns to Today', (tester) async {
    await tester.pumpSakina();
    // D-05: vyssia hlavicka Dnes, CTA moze byt v testovacom okne pod nav.
    await tester.ensureVisible(find.text("Begin today's cards"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Begin today's cards"));
    await tester.pumpAndSettle();
    expect(find.byType(FeedScreen), findsOneWidget);
    expect(navBar, findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('feed opened by deep link goes to Today on back', (tester) async {
    await tester.pumpSakina(location: 'mursa://feed');
    expect(find.byType(FeedScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('gate deep link opens fullscreen gate with app param', (
    tester,
  ) async {
    final router = await tester.pumpSakina(
      location: 'mursa://gate?app=com.instagram.android',
    );
    final gate = tester.widget<GateScreen>(find.byType(GateScreen));
    expect(gate.app, 'com.instagram.android');
    expect(gate.source, 'monitor');
    expect(navBar, findsNothing);
    expect(router.state.uri.path, '/gate');
    final popScope = tester.widget<PopScope<dynamic>>(
      find.descendant(
        of: find.byType(GateScreen),
        matching: find.byWidgetPredicate((w) => w is PopScope),
      ),
    );
    expect(popScope.canPop, isFalse);
  });

  testWidgets('gate without valid app redirects to Today', (tester) async {
    await tester.pumpSakina(location: '/gate?app=../x');
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('root path redirects to Today', (tester) async {
    await tester.pumpSakina(location: '/');
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('dev gallery is available only with devTools', (tester) async {
    await tester.pumpSakina(location: '/dev/gallery', devTools: true);
    expect(find.byType(SkGalleryScreen), findsOneWidget);
    expect(navBar, findsNothing);

    await tester.pumpSakina(location: 'mursa://dev/gallery', devTools: true);
    expect(find.byType(SkGalleryScreen), findsOneWidget);
  });

  testWidgets('dev gallery redirects to Today in prod', (tester) async {
    await tester.pumpSakina(location: '/dev/gallery');
    expect(find.byType(SkGalleryScreen), findsNothing);
    expect(find.byType(TodayScreen), findsOneWidget);
  });
}
