import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/content/content_documents.dart';
import 'package:prosoche/data/content/content_pack_state.dart';
import 'package:prosoche/data/content/remote_config_policy.dart';
import 'package:prosoche/data/content/sem_ver.dart';
import 'package:prosoche/data/content/signature_verifier.dart';
import 'package:prosoche/data/content/trusted_keys.dart';

import 'content_test_helpers.dart';

Uint8List _json(Object o) => utf8.encode(jsonEncode(o));

Uint8List remoteConfigBytes({
  int seq = 1,
  String expiresAt = '2099-01-01T00:00:00Z',
  String minSupported = '0.1.0',
  String? recommended,
  bool autoUpdate = true,
  List<String> broken = const [],
  Map<String, Object?>? notice,
  Map<String, Object?> extraFeatures = const {},
}) => _json({
  'schema': 1,
  'seq': seq,
  'issued_at': '2026-01-01T00:00:00Z',
  'expires_at': expiresAt,
  'min_supported_version': minSupported,
  'recommended_version': recommended,
  'features': {
    'content_auto_update': {'enabled': autoUpdate},
    ...extraFeatures,
  },
  'broken_versions': broken,
  'notice': notice,
});

Map<String, Object?> _manifest() =>
    jsonDecode(utf8.decode(manifestBytes(contentVersion: 5, db: [1], gz: [2])))
        as Map<String, Object?>;

void main() {
  group('SemVer', () {
    test('parses and compares', () {
      expect(SemVer.parse('1.2.3+4'), const SemVer(1, 2, 3));
      expect(SemVer.tryParse('1.2'), isNull);
      expect(SemVer.tryParse(null), isNull);
      expect(() => SemVer.parse('x'), throwsFormatException);
      expect(SemVer.parse('1.10.0') > SemVer.parse('1.9.9'), isTrue);
      expect(SemVer.parse('2.0.0') > SemVer.parse('1.99.99'), isTrue);
      expect(SemVer.parse('1.0.1') <= SemVer.parse('1.0.1'), isTrue);
      expect(SemVer.parse('1.0.0') < SemVer.parse('1.0.1'), isTrue);
      expect(SemVer.parse('1.0.0').hashCode, const SemVer(1, 0, 0).hashCode);
      expect('${const SemVer(1, 2, 3)}', '1.2.3');
    });
  });

  group('ContentManifest', () {
    test('valid manifest parses', () {
      final m = ContentManifest.parse(_json(_manifest())).valueOrNull!;
      expect(m.contentVersion, 5);
      expect(m.db.url.host, 'cdn.test');
      expect(m.createdAt, DateTime.utc(2026));
      expect(m.sectionsSha256, fixtureSectionsSha256());
      expect(m.devContent, isTrue);
    });

    test('ignores unknown packs field (v1 has none)', () {
      final m = ContentManifest.parse(_json(_manifest()..['packs'] = [1]));
      expect(m.isOk, isTrue);
    });

    for (final (name, mutate)
        in <(String, void Function(Map<String, Object?>))>[
          ('wrong schema', (m) => m['schema'] = 2),
          ('zero content_version', (m) => m['content_version'] = 0),
          ('string schema_version', (m) => m['schema_version'] = '2'),
          ('bad min_app_version', (m) => m['min_app_version'] = '1.0'),
          ('build in min_app_version', (m) => m['min_app_version'] = '1.0.0+1'),
          ('bad created_at', (m) => m['created_at'] = '2026-01-01'),
          ('bad kid', (m) => m['kid'] = 'X'),
          ('no db', (m) => m['db'] = null),
          ('http url', (m) => (m['db']! as Map)['url'] = 'http://x.test/a'),
          ('no host', (m) => (m['db']! as Map)['fallback_url'] = 'https://'),
          ('bad sha', (m) => (m['db']! as Map)['sha256'] = 'abc'),
          ('compression', (m) => (m['db']! as Map)['compression'] = 'zstd'),
          ('disabled not list', (m) => m['disabled_ids'] = 'quote:q_0001'),
          ('bad card id', (m) => m['disabled_ids'] = ['Quote 1']),
          ('no sources', (m) => m['sources'] = <Object?>[]),
          ('no sections_sha256', (m) => m.remove('sections_sha256')),
          ('bad sections_sha256', (m) => m['sections_sha256'] = 'x'),
          ('no dev_content', (m) => m.remove('dev_content')),
          ('string dev_content', (m) => m['dev_content'] = 'true'),
        ]) {
      test('rejects $name', () {
        final m = _manifest();
        mutate(m);
        expect(
          ContentManifest.parse(_json(m)),
          const Err<ContentManifest>(ContentIntegrityFailed('manifest')),
        );
      });
    }

    test('rejects non-object and invalid utf8', () {
      expect(ContentManifest.parse(_json([1])).isOk, isFalse);
      expect(
        ContentManifest.parse(Uint8List.fromList([0xff, 0xfe])).isOk,
        isFalse,
      );
    });
  });

  group('RemoteConfig', () {
    Map<String, Object?> cfg() =>
        jsonDecode(utf8.decode(remoteConfigBytes())) as Map<String, Object?>;

    test('parses notice and features', () {
      final m = cfg()
        ..['notice'] = {
          'id': 'n1',
          'severity': 'warning',
          'text': {'en': 'Please update.'},
          'show_on_versions': ['1.3.0'],
        }
        ..['features'] = {
          'blocker_overlay': {'enabled': false, 'max_version': '1.3.0'},
        };
      final c = RemoteConfig.parse(_json(m)).valueOrNull!;
      expect(c.notice!.text['en'], 'Please update.');
      expect(c.features['blocker_overlay']!.maxVersion, SemVer.parse('1.3.0'));

      final old = RemoteConfigPolicy(c, SemVer.parse('1.3.0'));
      expect(old.isFeatureEnabled('blocker_overlay'), isFalse);
      expect(old.notice?.id, 'n1');
      expect(old.updateRecommended, isFalse);
      final fixed = RemoteConfigPolicy(c, SemVer.parse('1.4.0'));
      expect(fixed.isFeatureEnabled('blocker_overlay'), isTrue);
      expect(fixed.notice, isNull);
      expect(const RemoteConfigPolicy(null, SemVer(1, 0, 0)).notice, isNull);
    });

    test('notice without versions shows everywhere', () {
      final m = cfg()
        ..['notice'] = {
          'id': 'n',
          'severity': 'info',
          'text': <String, Object?>{},
        };
      final c = RemoteConfig.parse(_json(m)).valueOrNull!;
      expect(RemoteConfigPolicy(c, const SemVer(9, 9, 9)).notice, isNotNull);
    });

    for (final (name, mutate)
        in <(String, void Function(Map<String, Object?>))>[
          ('schema', (m) => m['schema'] = 0),
          ('negative seq', (m) => m['seq'] = -1),
          (
            'expires before issued',
            (m) => m['expires_at'] = '2025-01-01T00:00:00Z',
          ),
          ('features', (m) => m['features'] = <Object?>[]),
          (
            'feature enabled',
            (m) => m['features'] = {
              'x': {'enabled': 1},
            },
          ),
          ('feature not map', (m) => m['features'] = {'x': true}),
          ('broken', (m) => m['broken_versions'] = '1.0.0'),
          ('broken item', (m) => m['broken_versions'] = ['1.0']),
          ('recommended', (m) => m['recommended_version'] = 'latest'),
          ('notice type', (m) => m['notice'] = 'x'),
          (
            'notice text',
            (m) => m['notice'] = {'id': 'n', 'severity': 's', 'text': 1},
          ),
          (
            'notice id',
            (m) => m['notice'] = {'severity': 's', 'text': <String, Object?>{}},
          ),
          (
            'notice value',
            (m) => m['notice'] = {
              'id': 'n',
              'severity': 's',
              'text': {'en': 1},
            },
          ),
          (
            'url in key',
            (m) => m['features'] = {
              'https://x': {'enabled': true},
            },
          ),
          ('url in list', (m) => m['broken_versions'] = ['ftp://x']),
        ]) {
      test('rejects $name', () {
        final m = cfg();
        mutate(m);
        expect(
          RemoteConfig.parse(_json(m)),
          const Err<RemoteConfig>(ContentIntegrityFailed('remote_config')),
        );
      });
    }
  });

  group('SignatureVerifier', () {
    late TestKeys keys;
    setUpAll(() async => keys = await TestKeys.create());

    Future<Result<ResolvedKey>> verify(Object envelope) =>
        SignatureVerifier(keys.set).verify(Uint8List(1), _json(envelope));

    test('non-string kid and sig are rejected', () async {
      expect(
        await verify({'alg': 'Ed25519', 'kid': 1, 'sig': ''}),
        const Err<ResolvedKey>(SecurityFailure.unknownKey()),
      );
      expect(
        await verify({'alg': 'Ed25519', 'kid': 'test-root-1', 'sig': 5}),
        const Err<ResolvedKey>(SecurityFailure.malformedSignature()),
      );
      expect(
        await verify([1]),
        const Err<ResolvedKey>(SecurityFailure.malformedSignature()),
      );
    });

    test('valid signature returns the key', () async {
      final payload = utf8.encode('payload');
      final r = await SignatureVerifier(
        keys.set,
      ).verify(payload, await keys.root.sign(payload), allowed: {KeyRole.root});
      expect(r.valueOrNull?.kid, 'test-root-1');
      expect(KeyRole.fromWire('x'), isNull);
    });
  });

  group('TrustedKeySet', () {
    test('skips empty keys and rejects bad ones', () {
      expect(TrustedKeySet(kTrustedKeys).isEmpty, isTrue);
      expect(
        () => TrustedKeySet(const [TrustedKey('a', '***', KeyRole.root)]),
        throwsArgumentError,
      );
      expect(
        () => TrustedKeySet(const [TrustedKey('a', 'AAAA', KeyRole.root)]),
        throwsArgumentError,
      );
      expect(
        () => TrustedKeySet(const [...kDevTrustedKeys, ...kDevTrustedKeys]),
        throwsArgumentError,
      );
    });
  });

  group('ContentPackStateStore', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('content_state'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('round trip', () async {
      final store = ContentPackStateStore(File(p.join(tmp.path, 's.json')));
      expect((await store.load()).installedVersion, isNull);
      const state = ContentPackState(
        installedVersion: 7,
        origin: ContentDbOrigin.downloaded,
        disabledIds: {'quote:q_0001'},
        disabledIdsVersion: 7,
        rejectedVersion: 8,
      );
      await store.save(state);
      final loaded = await store.load();
      expect(loaded.toJson(), state.toJson());
      expect(loaded.rejectedVersion, 8);
    });

    test('corrupted file yields empty state', () async {
      final file = File(p.join(tmp.path, 's.json'))..writeAsStringSync('{');
      expect((await ContentPackStateStore(file).load()).disabledIds, isEmpty);
      // Stare kluce Mursy (revokacie, remote config) sa ignoruju.
      file.writeAsStringSync('{"revoked_kids": ["a"], "installed_version": 3}');
      expect((await ContentPackStateStore(file).load()).installedVersion, 3);
      file.writeAsStringSync('[1]');
      expect((await ContentPackStateStore(file).load()).origin, isNull);
      file.writeAsStringSync('{"origin": "nope", "installed_version": "x"}');
      final s = await ContentPackStateStore(file).load();
      expect(s.origin, isNull);
      expect(s.installedVersion, isNull);
    });
  });
}
