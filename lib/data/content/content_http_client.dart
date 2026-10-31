import 'dart:async';
import 'dart:io' as io;

import 'package:meta/meta.dart';
import 'package:prosoche/core/result.dart';

/// Odpoved na GET. [body] moze pocas citania zlyhat
/// [ContentHttpException] (preruseny download).
@immutable
class ContentHttpResponse {
  const ContentHttpResponse(this.statusCode, this.body);

  final int statusCode;
  final Stream<List<int>> body;
}

/// Ocakavana sietova chyba ([Offline], [Timeout]).
class ContentHttpException implements Exception {
  const ContentHttpException(this.failure);

  final NetworkFailure failure;

  @override
  String toString() => 'ContentHttpException(${failure.code})';
}

/// Siet pre ContentPackService. V testoch fake, v appke
/// [IoContentHttpClient].
abstract interface class ContentHttpClient {
  /// Hodi [ContentHttpException], ked spojenie zlyha.
  Future<ContentHttpResponse> get(Uri url);

  void close();
}

/// Implementacia nad `dart:io` [io.HttpClient] (bez dalsej zavislosti).
class IoContentHttpClient implements ContentHttpClient {
  IoContentHttpClient({
    io.HttpClient? client,
    this.connectTimeout = const Duration(seconds: 20),
    this.idleTimeout = const Duration(seconds: 30),
    this.userAgent = 'prosoche-app',
  }) : _client = client ?? io.HttpClient() {
    _client
      ..connectionTimeout = connectTimeout
      ..userAgent = userAgent;
  }

  final io.HttpClient _client;
  final Duration connectTimeout;

  /// Max pauza medzi blokmi dat; dlhsia = [Timeout].
  final Duration idleTimeout;
  final String userAgent;

  @override
  Future<ContentHttpResponse> get(Uri url) async {
    try {
      final req = await _client.getUrl(url).timeout(connectTimeout);
      final res = await req.close().timeout(idleTimeout);
      return ContentHttpResponse(res.statusCode, _guard(res));
    } on Object catch (e) {
      throw _map(e);
    }
  }

  Stream<List<int>> _guard(Stream<List<int>> body) =>
      body.timeout(idleTimeout).handleError((Object e) => throw _map(e));

  static Exception _map(Object e) => switch (e) {
    TimeoutException() => const ContentHttpException(Timeout()),
    io.SocketException() ||
    io.HttpException() ||
    io.TlsException() => const ContentHttpException(Offline()),
    final Exception other => other,
    _ => const ContentHttpException(Offline()),
  };

  @override
  void close() => _client.close(force: true);
}
