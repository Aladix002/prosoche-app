import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/router/deep_link.dart';

void main() {
  String? map(String s) => mapDeepLink(Uri.parse(s));

  test('ignores non-prosoche URIs', () {
    expect(map('/today'), isNull);
    expect(map('https://example.com/gate'), isNull);
  });

  test('maps tabs and feed', () {
    expect(map('prosoche://today'), '/today');
    expect(map('prosoche://feed'), '/feed');
    expect(map('prosoche://prayer?p=asr'), '/prayer');
    expect(map('prosoche://quran'), '/quran');
    expect(map('prosoche://journey'), '/journey');
    expect(map('prosoche://unknown'), '/today');
    expect(map('prosoche:'), '/today');
  });

  test('maps nested targets from docs/02 C4', () {
    expect(
      map('prosoche://quran/2/255'),
      '/quran/read/2?ayah=2255&mode=browse',
    );
    expect(map('prosoche://quran/18'), '/quran/read/18?mode=browse');
    expect(map('prosoche://quran/115/1'), '/quran');
    expect(map('prosoche://quran/x'), '/quran');
    expect(map('prosoche://prayer/qibla'), '/prayer/qibla');
    expect(map('prosoche://words'), '/words');
    expect(map('prosoche://words/quiz'), '/words/quiz');
    expect(map('prosoche://calendar'), '/calendar');
    expect(map('prosoche://settings/blocking'), '/settings/blocking');
    expect(map('prosoche://settings/notifications'), '/settings/notifications');
    expect(map('prosoche://settings/evil'), '/settings');
  });

  test('maps gate with validated app and default src', () {
    expect(
      map('prosoche://gate?app=com.instagram.android'),
      '/gate?app=com.instagram.android&src=monitor',
    );
    expect(
      map('prosoche://gate?app=com.example.app&src=notif'),
      '/gate?app=com.example.app&src=notif',
    );
    expect(
      map('prosoche://gate?app=com.example.app&src=evil'),
      '/gate?app=com.example.app&src=monitor',
    );
  });

  test('gate with invalid app falls back to today', () {
    expect(map('prosoche://gate'), '/today');
    expect(map('prosoche://gate?app=not-a-package'), '/today');
    expect(map('prosoche://gate?app=..%2F..'), '/today');
  });

  test('maps dev gallery, unknown dev targets fall back to today', () {
    expect(map('prosoche://dev/gallery'), '/dev/gallery');
    expect(map('prosoche://dev'), '/today');
    expect(map('prosoche://dev/evil'), '/today');
  });
}
