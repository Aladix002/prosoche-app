import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/router/deep_link.dart';

void main() {
  String? map(String s) => mapDeepLink(Uri.parse(s));

  test('ignores non-mursa URIs', () {
    expect(map('/today'), isNull);
    expect(map('https://example.com/gate'), isNull);
  });

  test('maps tabs and feed', () {
    expect(map('mursa://today'), '/today');
    expect(map('mursa://feed'), '/feed');
    expect(map('mursa://prayer?p=asr'), '/prayer');
    expect(map('mursa://quran'), '/quran');
    expect(map('mursa://journey'), '/journey');
    expect(map('mursa://unknown'), '/today');
    expect(map('mursa:'), '/today');
  });

  test('maps nested targets from docs/02 C4', () {
    expect(map('mursa://quran/2/255'), '/quran/read/2?ayah=2255&mode=browse');
    expect(map('mursa://quran/18'), '/quran/read/18?mode=browse');
    expect(map('mursa://quran/115/1'), '/quran');
    expect(map('mursa://quran/x'), '/quran');
    expect(map('mursa://prayer/qibla'), '/prayer/qibla');
    expect(map('mursa://words'), '/words');
    expect(map('mursa://words/quiz'), '/words/quiz');
    expect(map('mursa://calendar'), '/calendar');
    expect(map('mursa://settings/blocking'), '/settings/blocking');
    expect(map('mursa://settings/notifications'), '/settings/notifications');
    expect(map('mursa://settings/evil'), '/settings');
  });

  test('maps gate with validated app and default src', () {
    expect(
      map('mursa://gate?app=com.instagram.android'),
      '/gate?app=com.instagram.android&src=monitor',
    );
    expect(
      map('mursa://gate?app=com.example.app&src=notif'),
      '/gate?app=com.example.app&src=notif',
    );
    expect(
      map('mursa://gate?app=com.example.app&src=evil'),
      '/gate?app=com.example.app&src=monitor',
    );
  });

  test('gate with invalid app falls back to today', () {
    expect(map('mursa://gate'), '/today');
    expect(map('mursa://gate?app=not-a-package'), '/today');
    expect(map('mursa://gate?app=..%2F..'), '/today');
  });

  test('maps dev gallery, unknown dev targets fall back to today', () {
    expect(map('mursa://dev/gallery'), '/dev/gallery');
    expect(map('mursa://dev'), '/today');
    expect(map('mursa://dev/evil'), '/today');
  });
}
