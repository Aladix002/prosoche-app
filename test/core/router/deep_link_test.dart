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

  test('W-01: maps reader with validated work, section and highlight', () {
    expect(map('prosoche://reader/meditations'), '/reader/meditations');
    expect(
      map('prosoche://reader/meditations?section=meditations.4.3'),
      '/reader/meditations?section=meditations.4.3',
    );
    final hl = Uri.parse(
      map('prosoche://reader/on-anger?section=on-anger.3.36&hl=A%20b%3F')!,
    );
    expect(hl.path, '/reader/on-anger');
    expect(hl.queryParameters, {'section': 'on-anger.3.36', 'hl': 'A b?'});
  });

  test('W-01: invalid reader targets never reach the reader with bad ids', () {
    expect(map('prosoche://reader'), '/library');
    expect(map('prosoche://reader/..'), '/library');
    expect(map('prosoche://reader/Evil%2F..'), '/library');
    expect(
      map('prosoche://reader/meditations?section=../x'),
      '/reader/meditations',
    );
    final long = 'x' * 601;
    expect(
      map('prosoche://reader/meditations?hl=$long'),
      '/reader/meditations',
    );
    expect(map('prosoche://reader/meditations?hl=%20'), '/reader/meditations');
  });
}
