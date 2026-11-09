import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/features/library/reader_screen.dart';
import 'package:prosoche/features/today/today_screen.dart';

import '../../helpers/pump_app.dart';

/// W-01: tuk na widget otvori citacku na sekcii citatu (deep link
/// `prosoche://reader/...`); back vedie na Dnes.
void main() {
  testWidgets('widget deep link opens the reader with the quote highlighted', (
    tester,
  ) async {
    await tester.pumpProsoche(
      location:
          'prosoche://reader/work-books?section=work-books.1.1&hl=Be%20here.',
    );
    final reader = tester.widget<ReaderScreen>(find.byType(ReaderScreen));
    expect(reader.workId, 'work-books');
    expect(reader.sectionKey, 'work-books.1.1');
    expect(reader.highlight, 'Be here.');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('invalid widget link falls back to Library', (tester) async {
    await tester.pumpProsoche(location: 'prosoche://reader/..');
    expect(find.byType(ReaderScreen), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
