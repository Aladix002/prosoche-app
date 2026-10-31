import 'package:flutter_test/flutter_test.dart';
import 'package:prosoche_lints/prosoche_lints.dart';

/// RTL lint nad celym lib/ (PLAN_VYVOJA 4.2 bod 3, docs/04 5.3).
/// Bezi v `flutter test`, teda aj v `tool/check.sh`. Rucne:
/// `dart run prosoche_lints:check lib`.
void main() {
  test('lib/ has no RTL violations', () {
    final violations = checkPaths(['lib']);
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
