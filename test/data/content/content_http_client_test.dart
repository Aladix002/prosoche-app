// IoContentHttpClient proti lokalnemu serveru na loopbacku (ziadna
// externa siet).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart' hide Timeout;
import 'package:prosoche/core/result.dart';
import 'package:prosoche/data/content/content_http_client.dart';

void main() {
  late HttpServer server;
  late IoContentHttpClient client;
  late Uri base;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = Uri.parse('http://${server.address.host}:${server.port}');
    client = IoContentHttpClient(idleTimeout: const Duration(seconds: 1));
    server.listen((req) async {
      switch (req.uri.path) {
        case '/ok':
          req.response.add([1, 2, 3]);
          await req.response.close();
        case '/missing':
          req.response.statusCode = 404;
          await req.response.close();
        case '/stall':
          req.response
            ..contentLength = 100
            ..add([1]);
          await req.response.flush();
        // Bez close: klient narazi na idleTimeout.
        case '/cut':
          // Mensie telo ako contentLength: server zavrie spojenie.
          req.response
            ..contentLength = 100
            ..add([1]);
          try {
            await req.response.close();
          } on HttpException {
            // ocakavane na strane servera
          }
      }
    });
  });

  tearDown(() async {
    client.close();
    await server.close(force: true);
  });

  test('returns status and body', () async {
    final res = await client.get(base.resolve('/ok'));
    expect(res.statusCode, 200);
    expect(await res.body.expand((c) => c).toList(), [1, 2, 3]);
    expect((await client.get(base.resolve('/missing'))).statusCode, 404);
  });

  test('stalled body is a Timeout', () async {
    final res = await client.get(base.resolve('/stall'));
    await expectLater(
      res.body.drain<void>(),
      throwsA(
        isA<ContentHttpException>().having(
          (e) => e.failure,
          'failure',
          isA<Timeout>(),
        ),
      ),
    );
  });

  test('cut connection is Offline', () async {
    final res = await client.get(base.resolve('/cut'));
    await expectLater(
      res.body.drain<void>(),
      throwsA(
        isA<ContentHttpException>().having(
          (e) => e.toString(),
          'code',
          contains('net.offline'),
        ),
      ),
    );
  });

  test('refused connection is Offline', () async {
    final port = server.port;
    await server.close(force: true);
    await expectLater(
      client.get(Uri.parse('http://127.0.0.1:$port/ok')),
      throwsA(isA<ContentHttpException>()),
    );
  });
}
