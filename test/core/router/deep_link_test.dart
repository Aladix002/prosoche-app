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
    expect(map('prosoche://library'), '/library');
    expect(map('prosoche://practice'), '/practice');
    expect(map('prosoche://journey'), '/journey');
    expect(map('prosoche://quran'), '/today');
    expect(map('prosoche://unknown'), '/today');
    expect(map('prosoche:'), '/today');
  });

  test('maps nested targets from docs/02 C4', () {
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
