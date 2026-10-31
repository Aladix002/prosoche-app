// Zluci ARB casti uloh do ARB suborov pre gen-l10n (PLAN_VYVOJA kap. 2).
//
//   dart run tool/merge_arb.dart          # zapise lib/l10n/app_<lang>.arb
//   dart run tool/merge_arb.dart --check  # len overi, ze su aktualne
//
// Vstup: lib/l10n/parts/<ID>_<lang>.arb (napr. S-01_en.arb, F-02_ar.arb).
// Vystup: lib/l10n/app_<lang>.arb pre kazdy jazyk, ktory ma aspon jednu cast.
// Chyba: duplicitny kluc medzi castami, `@kluc` bez kluca, kluc v jazyku,
// ktory nie je v EN (sablona), zly nazov suboru alebo `@@locale`.
import 'dart:convert';
import 'dart:io';

const defaultDir = 'lib/l10n';
const templateLang = 'en';

final _partName = RegExp(
  r'^([A-Z]+-\d+[a-z]?)_([a-z]{2,3}(?:_[A-Za-z]{2,4})?)\.arb$',
);
final _outName = RegExp(r'^app_([a-z]{2,3}(?:_[A-Za-z]{2,4})?)\.arb$');

class ArbMergeException implements Exception {
  ArbMergeException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Zluci casti [parts] (nazov suboru -> obsah) do vystupov
/// (`app_<lang>.arb` -> obsah). Cista funkcia, bez I/O.
Map<String, String> mergeArbParts(Map<String, String> parts) {
  final byLang = <String, List<(String, String, Map<String, Object?>)>>{};
  for (final MapEntry(key: file, value: content) in parts.entries) {
    final m = _partName.firstMatch(file);
    if (m == null) {
      throw ArbMergeException(
        '$file: nazov musi byt <ID>_<lang>.arb (napr. F-02_en.arb)',
      );
    }
    final Object? json;
    try {
      json = jsonDecode(content);
    } on FormatException catch (e) {
      throw ArbMergeException('$file: neplatny JSON (${e.message})');
    }
    if (json is! Map<String, Object?>) {
      throw ArbMergeException('$file: ocakavany JSON objekt');
    }
    (byLang[m[2]!] ??= []).add((m[1]!, file, json));
  }
  if (!byLang.containsKey(templateLang)) {
    throw ArbMergeException('Chyba aspon jedna cast *_$templateLang.arb');
  }

  final out = <String, String>{};
  Set<String>? templateKeys;
  for (final lang in [
    templateLang,
    ...byLang.keys.where((l) => l != templateLang).toList()..sort(),
  ]) {
    final entries = byLang[lang]!..sort((a, b) => a.$1.compareTo(b.$1));
    final merged = <String, Object?>{'@@locale': lang};
    final owner = <String, String>{};
    for (final (_, file, json) in entries) {
      final locale = json['@@locale'];
      if (locale != null && locale != lang) {
        throw ArbMergeException('$file: @@locale "$locale" != "$lang"');
      }
      for (final MapEntry(:key, :value) in json.entries) {
        if (key.startsWith('@@')) continue;
        if (key.startsWith('@')) {
          if (!json.containsKey(key.substring(1))) {
            throw ArbMergeException('$file: $key bez kluca');
          }
          continue;
        }
        final prev = owner[key];
        if (prev != null) {
          throw ArbMergeException('Kluc "$key" je v $prev aj v $file');
        }
        if (templateKeys != null && !templateKeys.contains(key)) {
          throw ArbMergeException('$file: kluc "$key" nie je v EN');
        }
        owner[key] = file;
        merged[key] = value;
        if (json.containsKey('@$key')) merged['@$key'] = json['@$key'];
      }
    }
    templateKeys ??= owner.keys.toSet();
    out['app_$lang.arb'] =
        '${const JsonEncoder.withIndent('  ').convert(merged)}\n';
  }
  return out;
}

/// Spusti zlucenie nad adresarom [dir]. Vrati exit code.
int runMergeArb(
  List<String> args, {
  String dir = defaultDir,
  StringSink? out,
  StringSink? err,
}) {
  out ??= stdout;
  err ??= stderr;
  final check = args.contains('--check');
  final partsDir = Directory('$dir/parts');
  if (!partsDir.existsSync()) {
    err.writeln('Adresar ${partsDir.path} neexistuje');
    return 2;
  }
  final parts = {
    for (final f in partsDir.listSync().whereType<File>())
      if (f.path.endsWith('.arb'))
        f.uri.pathSegments.last: f.readAsStringSync(),
  };

  final Map<String, String> merged;
  try {
    merged = mergeArbParts(parts);
  } on ArbMergeException catch (e) {
    err.writeln('merge_arb: $e');
    return 1;
  }

  final existing = {
    for (final f in Directory(dir).listSync().whereType<File>())
      if (_outName.hasMatch(f.uri.pathSegments.last))
        f.uri.pathSegments.last: f,
  };
  final stale = [
    for (final MapEntry(key: name, value: content) in merged.entries)
      if (existing[name]?.readAsStringSync() != content) name,
  ];
  final extra = existing.keys.where((n) => !merged.containsKey(n)).toList();

  if (check) {
    if (stale.isEmpty && extra.isEmpty) return 0;
    err.writeln(
      'merge_arb: neaktualne ${[...stale, ...extra].join(', ')}. '
      'Spusti: dart run tool/merge_arb.dart',
    );
    return 1;
  }
  for (final name in stale) {
    File('$dir/$name').writeAsStringSync(merged[name]!);
  }
  for (final name in extra) {
    existing[name]!.deleteSync();
  }
  out.writeln(
    'merge_arb: ${parts.length} casti -> ${merged.keys.join(', ')}'
    '${stale.isEmpty && extra.isEmpty ? ' (bez zmeny)' : ''}',
  );
  return 0;
}

void main(List<String> args) {
  exitCode = runMergeArb(args);
}
