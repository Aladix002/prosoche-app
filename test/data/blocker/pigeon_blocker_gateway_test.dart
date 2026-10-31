import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche/core/logging/app_logger.dart';
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/blocker/blocker_api.pigeon.dart' as api;
import 'package:prosoche/data/blocker/blocker_gateway.dart';
import 'package:prosoche/data/blocker/pigeon_blocker_gateway.dart';

const _prefix = 'dev.flutter.pigeon.prosoche.BlockerHostApi.';
const MessageCodec<Object?> _codec = api.BlockerHostApi.pigeonChannelCodec;

class _MemorySink implements LogSink {
  final entries = <LogEntry>[];

  @override
  void add(LogEntry entry) => entries.add(entry);
}

/// Nativna strana cez mock handlery kanalov Pigeon.
class _FakeNative {
  _FakeNative(this.messenger);

  final TestDefaultBinaryMessenger messenger;
  final received = <String, List<Object?>>{};

  void on(String method, Object? Function(List<Object?> args) reply) {
    messenger.setMockMessageHandler('$_prefix$method', (data) async {
      final args = (_codec.decodeMessage(data) as List<Object?>?) ?? const [];
      received[method] = args;
      return _codec.encodeMessage(<Object?>[reply(args)]);
    });
  }

  void fail(String method, String code) {
    messenger.setMockMessageHandler('$_prefix$method', (data) async {
      return _codec.encodeMessage(<Object?>[code, 'msg', null]);
    });
  }

  void missing(String method) =>
      messenger.setMockMessageHandler('$_prefix$method', (data) async => null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeNative native;
  late _MemorySink sink;
  late PigeonBlockerGateway gateway;

  setUp(() {
    native = _FakeNative(
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger,
    );
    sink = _MemorySink();
    gateway = PigeonBlockerGateway(
      api.BlockerHostApi(),
      AppLogger(sinks: [sink], echoToConsole: false),
    );
  });

  group('mapping', () {
    test('clearUnlocks and deviceManufacturer (B-03)', () async {
      native
        ..on('clearUnlocks', (_) => null)
        ..on('deviceManufacturer', (_) => 'samsung');
      expect((await gateway.clearUnlocks()).isOk, isTrue);
      expect(native.received.containsKey('clearUnlocks'), isTrue);
      expect((await gateway.deviceManufacturer()).valueOrNull, 'samsung');
    });

    test('status', () async {
      native.on(
        'status',
        (_) => api.BlockerStatus(
          apiVersion: blockerApiVersion,
          enabled: true,
          permission: api.BlockerPermission.granted,
          serviceRunning: true,
        ),
      );
      final s = (await gateway.status()).valueOrNull!;
      expect(
        s,
        const BlockerState(
          enabled: true,
          permission: BlockerPermissionState.granted,
          serviceRunning: true,
          apiVersion: blockerApiVersion,
        ),
      );
      expect(s.apiCompatible, isTrue);
      expect(s.hashCode, isA<int>());
    });

    test('older native api is reported as incompatible', () async {
      native.on(
        'status',
        (_) => api.BlockerStatus(
          apiVersion: 0,
          enabled: false,
          permission: api.BlockerPermission.notDetermined,
          serviceRunning: false,
        ),
      );
      final s = (await gateway.status()).valueOrNull!;
      expect(s.apiCompatible, isFalse);
      expect(s.permission, BlockerPermissionState.notDetermined);
    });

    test('permissions detail', () async {
      native.on(
        'permissionsDetail',
        (_) => api.PermissionsDetail(
          usageAccess: true,
          overlay: false,
          notifications: true,
          exactAlarm: false,
          batteryOptimized: true,
        ),
      );
      final p = (await gateway.permissions()).valueOrNull!;
      expect(p.usageAccess, isTrue);
      expect(p.overlay, isFalse);
      expect(p.readyForGate, isFalse);
      expect(p.batteryOptimized, isTrue);
      expect(BlockerPermissions.allGranted.readyForGate, isTrue);
      expect(
        p,
        const BlockerPermissions(
          usageAccess: true,
          overlay: false,
          notifications: true,
          exactAlarm: false,
          batteryOptimized: true,
        ),
      );
      expect(p.hashCode, isNot(BlockerPermissions.allGranted.hashCode));
    });

    test('requestPermission', () async {
      native.on('requestPermission', (_) => api.BlockerPermission.restricted);
      expect(
        await gateway.requestPermission(),
        const Ok(BlockerPermissionState.restricted),
      );
    });

    test('openSystemSettings passes the kind', () async {
      native.on('openSystemSettings', (_) => null);
      for (final kind in BlockerSettings.values) {
        expect((await gateway.openSystemSettings(kind)).isOk, isTrue);
        expect(native.received['openSystemSettings'], [
          api.SystemSettingsKind.values[kind.index],
        ]);
        expect(
          api.SystemSettingsKind.values[kind.index].name,
          kind.name,
          reason: 'enumy musia mat rovnake poradie',
        );
      }
    });

    test('installedApps', () async {
      native.on(
        'installedApps',
        (_) => [
          api.InstalledApp(ref: 'com.a.b', label: 'A'),
          api.InstalledApp(ref: 'com.c.d', label: 'C'),
        ],
      );
      final apps = (await gateway.installedApps()).valueOrNull!;
      expect(apps, const [
        LaunchableApp(ref: 'com.a.b', label: 'A'),
        LaunchableApp(ref: 'com.c.d', label: 'C'),
      ]);
      expect(apps.first.hashCode, isNot(apps.last.hashCode));
    });

    test('appIcon bytes and null', () async {
      native.on('appIcon', (args) => args.first == 'com.a.b' ? _png : null);
      expect((await gateway.appIcon('com.a.b')).valueOrNull, _png);
      expect((await gateway.appIcon('com.x.y')).valueOrNull, isNull);
    });

    test('setTargets sends targets', () async {
      native.on('setTargets', (_) => null);
      const targets = [
        BlockTarget(
          ref: 'com.a.b',
          label: 'A',
          cardsRequired: 3,
          unlockMinutes: 15,
        ),
        BlockTarget(ref: 'com.c.d', cardsRequired: 2, unlockMinutes: 5),
      ];
      expect((await gateway.setTargets(targets)).isOk, isTrue);
      final sent = native.received['setTargets']!.first! as List<Object?>;
      expect(sent, [
        api.BlockedTarget(
          ref: 'com.a.b',
          label: 'A',
          cardsRequired: 3,
          unlockMinutes: 15,
        ),
        api.BlockedTarget(ref: 'com.c.d', cardsRequired: 2, unlockMinutes: 5),
      ]);
      expect(targets.first, isNot(targets.last));
      expect(targets.first.hashCode, isNot(targets.last.hashCode));
    });

    test('setEnabled, unlockFor, closeGate, schedulePrayerLocks', () async {
      for (final m in [
        'setEnabled',
        'unlockFor',
        'closeGate',
        'schedulePrayerLocks',
      ]) {
        native.on(m, (_) => null);
      }
      expect((await gateway.setEnabled(enabled: true)).isOk, isTrue);
      expect(native.received['setEnabled'], [true]);

      expect((await gateway.unlockFor('com.a.b', minutes: 5)).isOk, isTrue);
      expect(native.received['unlockFor'], ['com.a.b', 5]);

      expect((await gateway.closeGate(openTarget: false)).isOk, isTrue);
      expect(native.received['closeGate'], [false]);

      final start = DateTime.utc(2026, 11, 3, 12);
      expect(
        (await gateway.schedulePrayerLocks([start], durationMinutes: 20)).isOk,
        isTrue,
      );
      expect(native.received['schedulePrayerLocks'], [
        [start.millisecondsSinceEpoch],
        20,
      ]);
    });
  });

  group('errors (docs/06 C.5)', () {
    Future<AppFailure> failureFor(String code) async {
      native.fail('setEnabled', code);
      final r = await gateway.setEnabled(enabled: true);
      return r.fold<AppFailure>((_) => fail('expected Err'), (f) => f);
    }

    test('permission_missing -> usage_stats denied', () async {
      expect(
        (await failureFor('permission_missing')).code,
        'platform.permission_denied.usage_stats',
      );
    });

    test('overlay_denied -> overlay denied', () async {
      expect(
        (await failureFor('overlay_denied')).code,
        'platform.permission_denied.overlay',
      );
    });

    test('os_unsupported -> unsupported', () async {
      expect(
        (await failureFor('os_unsupported')).code,
        'platform.unsupported.blocker',
      );
    });

    test('other codes -> NativeFailure', () async {
      final f = await failureFor('internal');
      expect(f, isA<NativeFailure>());
      expect(f.code, 'platform.native.blocker.internal');
    });

    test('missing native side (lite, iOS) -> unsupported', () async {
      native.missing('status');
      final r = await gateway.status();
      expect(r, const Err<BlockerState>(UnsupportedOnPlatform('blocker')));
    });

    test('MissingPluginException -> unsupported', () async {
      final g = PigeonBlockerGateway(
        _ThrowingApi(),
        AppLogger(sinks: [sink], echoToConsole: false),
      );
      expect(
        await g.closeGate(openTarget: true),
        const Err<void>(UnsupportedOnPlatform('blocker')),
      );
    });

    test('log has only op and code, never message or package', () async {
      native.fail('unlockFor', 'invalid_target');
      await gateway.unlockFor('com.secret.app', minutes: 5);
      final entry = sink.entries.single;
      expect(entry.kv, {'op': 'unlockFor', 'code': 'invalid_target'});
      expect(entry.toJsonLine(), isNot(contains('com.secret.app')));
    });
  });

  group('gateRequests (BlockerFlutterApi)', () {
    const channel =
        'dev.flutter.pigeon.prosoche.BlockerFlutterApi.onGateRequested';

    Future<List<Object?>?> send(String ref) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final reply = await messenger.handlePlatformMessage(
        channel,
        api.BlockerFlutterApi.pigeonChannelCodec.encodeMessage(<Object?>[ref]),
        (_) {},
      );
      return api.BlockerFlutterApi.pigeonChannelCodec.decodeMessage(reply)
          as List<Object?>?;
    }

    test('native gate request is delivered while listening', () async {
      final got = <String>[];
      final sub = gateway.gateRequests.listen(got.add);
      expect(await send('com.a.b'), isEmpty);
      await pumpEventQueue();
      expect(got, ['com.a.b']);

      await sub.cancel();
      // Po zruseni odberu uz handler nie je zaregistrovany.
      expect(await send('com.c.d'), isNull);
      expect(got, ['com.a.b']);
    });
  });

  group('generated data classes', () {
    test('equality, hash and toString', () {
      final a = api.BlockedTarget(
        ref: 'com.a.b',
        iconPng: _png,
        cardsRequired: 1,
        unlockMinutes: 2,
      );
      final b = api.BlockedTarget.decode(a.encode());
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), contains('BlockedTarget'));
      expect(a == a, isTrue);
      expect(a, isNot(api.InstalledApp(ref: 'x', label: 'y')));

      final i = api.InstalledApp(ref: 'com.a.b', label: 'A');
      expect(i, api.InstalledApp.decode(i.encode()));
      expect(i.hashCode, api.InstalledApp.decode(i.encode()).hashCode);
      expect(i.toString(), contains('InstalledApp'));
      expect(i == i, isTrue);
      expect(i, isNot(a));

      final p = api.PermissionsDetail(
        usageAccess: true,
        overlay: true,
        notifications: true,
        exactAlarm: true,
        batteryOptimized: false,
      );
      expect(p, api.PermissionsDetail.decode(p.encode()));
      expect(p.hashCode, api.PermissionsDetail.decode(p.encode()).hashCode);
      expect(p.toString(), contains('PermissionsDetail'));
      expect(p == p, isTrue);
      expect(p, isNot(i));

      final s = api.BlockerStatus(
        apiVersion: 1,
        enabled: true,
        permission: api.BlockerPermission.denied,
        serviceRunning: false,
      );
      expect(s, api.BlockerStatus.decode(s.encode()));
      expect(s.hashCode, api.BlockerStatus.decode(s.encode()).hashCode);
      expect(s.toString(), contains('BlockerStatus'));
      expect(s == s, isTrue);
      expect(s, isNot(p));
    });
  });
}

final _png = Uint8List.fromList([137, 80, 78, 71]);

class _ThrowingApi extends api.BlockerHostApi {
  @override
  Future<void> closeGate(bool openTarget) =>
      throw MissingPluginException('no plugin');
}
