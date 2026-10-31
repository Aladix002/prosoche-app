import 'package:meta/meta.dart';
import 'package:sakina/core/failures.dart';

export 'package:sakina/core/failures.dart';

/// Vysledok operacie, ktora moze ocakavane zlyhat (docs/06 C.1).
///
/// Programatorske chyby sa do [Result] nebalia - hadzu sa ako exception
/// a zachyti ich globalny handler.
@immutable
sealed class Result<T> {
  const Result();

  R fold<R>(R Function(T value) ok, R Function(AppFailure f) err) =>
      switch (this) {
        Ok<T>(:final value) => ok(value),
        Err<T>(:final failure) => err(failure),
      };

  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  bool get isOk => this is Ok<T>;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok, value);
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final AppFailure failure;

  @override
  bool operator ==(Object other) =>
      other is Err<T> && other.failure.code == failure.code;

  @override
  int get hashCode => Object.hash(Err, failure.code);
}

extension ResultFutureX<T> on Future<Result<T>> {
  /// Zretazi dalsi krok, ak predchadzajuci skoncil [Ok].
  Future<Result<R>> then2<R>(Future<Result<R>> Function(T) next) async {
    switch (await this) {
      case Ok<T>(:final value):
        return await next(value);
      case Err<T>(:final failure):
        return Err<R>(failure);
    }
  }
}
