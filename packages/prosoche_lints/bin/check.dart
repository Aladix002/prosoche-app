// RTL lint nad zadanymi adresarmi (predvolene lib).
//
//   dart run prosoche_lints:check lib
//
// Exit 0 = bez porusenia, 1 = porusenia (vypisane na stderr).
import 'dart:io';

import 'package:prosoche_lints/prosoche_lints.dart';

void main(List<String> args) {
  final roots = args.isEmpty ? ['lib'] : args;
  final violations = checkPaths(roots)..forEach(stderr.writeln);
  stdout.writeln(
    'prosoche_lints: ${violations.length} poruseni v ${roots.join(', ')}',
  );
  exitCode = violations.isEmpty ? 0 : 1;
}
