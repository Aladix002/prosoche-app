import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;
import 'package:prosoche_lints/src/rules.dart';

/// Syntakticka kontrola (bez resolvera), aby bezala rychlo a bez pluginu.
///
/// Potlacenie: `// prosoche-lint: ignore <kod>` na rovnakom alebo
/// predchadzajucom riadku, `// prosoche-lint: ignore-file <kod>` kdekolvek
/// v subore.
List<LintViolation> checkSource(String content, {String path = '<memory>'}) {
  final result = parseString(
    content: content,
    path: path,
    throwIfDiagnostics: false,
  );
  final visitor = _Visitor(path, result.lineInfo);
  result.unit.accept(visitor);
  final ignores = _Ignores.parse(content);
  return [
    for (final v in visitor.found)
      if (!ignores.suppresses(v)) v,
  ];
}

/// Subory, ktore sa nekontroluju vobec (generovany kod, preklady).
bool isExcludedPath(String path) {
  final norm = p.posix.joinAll(p.split(path));
  return norm.endsWith('.g.dart') ||
      norm.endsWith('.freezed.dart') ||
      norm.endsWith('.pigeon.dart') ||
      norm.contains('lib/core/l10n/generated/');
}

/// Subory, kde su vybrane pravidla dovolene. `lib/ui/i18n/` je jedine
/// miesto, ktore smie natvrdo rozhodovat o smere a obsahuje tabulky cislic.
const Map<String, Set<ProsocheRule>> allowedRulesByPathPrefix = {
  'lib/ui/i18n/': {
    ProsocheRule.hardcodedTextDirection,
    ProsocheRule.arabicTextOutsideSkArabicText,
  },
};

/// Skontroluje vsetky `.dart` subory pod [roots]. Cesty vo vysledku su
/// relativne voci [base].
List<LintViolation> checkPaths(List<String> roots, {String? base}) {
  base ??= Directory.current.path;
  final out = <LintViolation>[];
  for (final root in roots) {
    final entity = FileSystemEntity.typeSync(root);
    final files = (switch (entity) {
      FileSystemEntityType.directory =>
        Directory(root)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .toList(),
      FileSystemEntityType.file => [File(root)],
      _ => throw ArgumentError('Neexistuje: $root'),
    })..sort((a, b) => a.path.compareTo(b.path));
    for (final f in files) {
      final rel = p.posix.joinAll(p.split(p.relative(f.path, from: base)));
      if (isExcludedPath(rel)) continue;
      final allowed = <ProsocheRule>{
        for (final MapEntry(:key, :value) in allowedRulesByPathPrefix.entries)
          if (rel.startsWith(key)) ...value,
      };
      out.addAll(
        checkSource(
          f.readAsStringSync(),
          path: rel,
        ).where((v) => !allowed.contains(v.rule)),
      );
    }
  }
  return out;
}

final _arabicScript = RegExp(
  '[\u0600-\u06FF\u0750-\u077F\u0870-\u089F\u08A0-\u08FF'
  '\uFB50-\uFDFF\uFE70-\uFEFF]',
);

/// Ci text obsahuje znak arabskeho pisma (arabcina, urdcina, ...).
bool containsArabicScript(String text) => _arabicScript.hasMatch(text);

const _alignmentTypes = {'Alignment', 'FractionalOffset'};
const _leftRightAlignments = {
  'topLeft',
  'centerLeft',
  'bottomLeft',
  'topRight',
  'centerRight',
  'bottomRight',
};
const _leftRight = {'left', 'right'};
const _corners = {'topLeft', 'topRight', 'bottomLeft', 'bottomRight'};
const _skArabicText = 'SkArabicText';

class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor(this.path, this.lineInfo);

  final String path;
  final LineInfo lineInfo;
  final found = <LintViolation>[];

  void _report(ProsocheRule rule, AstNode node) {
    final loc = lineInfo.getLocation(node.offset);
    var snippet = node.toSource().replaceAll(RegExp(r'\s+'), ' ');
    if (snippet.length > 60) snippet = '${snippet.substring(0, 57)}...';
    found.add(
      LintViolation(
        rule: rule,
        path: path,
        line: loc.lineNumber,
        column: loc.columnNumber,
        snippet: snippet,
      ),
    );
  }

  Set<String> _namedArgs(ArgumentList args) => {
    for (final a in args.arguments)
      if (a is NamedArgument) a.name.lexeme,
  };

  /// Spolocna kontrola volani `Typ.konstruktor(args)` v roznych tvaroch
  /// AST (s `const`, bez `new`, dot shorthand, kde typ je null).
  void _checkCall(AstNode node, String? type, String? ctor, ArgumentList args) {
    final named = _namedArgs(args);
    final hasLeftRight = named.any(_leftRight.contains);
    if ((type == 'EdgeInsets' || type == null) &&
        ctor == 'only' &&
        hasLeftRight) {
      _report(ProsocheRule.edgeInsetsLeftRight, node);
    }
    if (type == 'Positioned' && (ctor == null || ctor == 'fill')) {
      if (hasLeftRight) _report(ProsocheRule.positionedLeftRight, node);
    }
    if ((type == 'BorderRadius' || type == null) &&
        ((ctor == 'only' && named.any(_corners.contains)) ||
            (ctor == 'horizontal' && hasLeftRight))) {
      _report(ProsocheRule.borderRadiusLeftRight, node);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final namedType = node.constructorName.type;
    var type = namedType.name.lexeme;
    var ctor = node.constructorName.name?.name;
    // Bez resolvera je `const A.b()` NamedType(prefix: A, name: b).
    final prefix = namedType.importPrefix?.name.lexeme;
    if (ctor == null && prefix != null && _isTypeName(prefix)) {
      ctor = type;
      type = prefix;
    }
    _checkCall(node, type, ctor, node.argumentList);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    final name = node.methodName.name;
    if (target == null && _isTypeName(name)) {
      _checkCall(node, name, null, node.argumentList);
    } else if (target is SimpleIdentifier && _isTypeName(target.name)) {
      _checkCall(node, target.name, name, node.argumentList);
    } else if (target is PrefixedIdentifier &&
        _isTypeName(target.identifier.name)) {
      // `w.EdgeInsets.only(...)` s prefixom importu.
      _checkCall(node, target.identifier.name, name, node.argumentList);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitDotShorthandInvocation(DotShorthandInvocation node) {
    _checkCall(node, null, node.memberName.name, node.argumentList);
    super.visitDotShorthandInvocation(node);
  }

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    _checkCall(node, null, node.constructorName.name, node.argumentList);
    super.visitDotShorthandConstructorInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _checkMember(node, node.prefix.name, node.identifier.name);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final target = node.target;
    final type = switch (target) {
      SimpleIdentifier(:final name) => name,
      PrefixedIdentifier(:final identifier) => identifier.name,
      _ => null,
    };
    if (type != null) _checkMember(node, type, node.propertyName.name);
    super.visitPropertyAccess(node);
  }

  @override
  void visitDotShorthandPropertyAccess(DotShorthandPropertyAccess node) {
    final name = node.propertyName.name;
    if (_leftRightAlignments.contains(name)) {
      _report(ProsocheRule.alignmentLeftRight, node);
    } else if (name == 'ltr') {
      _report(ProsocheRule.hardcodedTextDirection, node);
    } else if (_leftRight.contains(name)) {
      // `.left` je nejednoznacne, hlasime len v kontexte `textAlign:`.
      final parent = node.parent;
      if (parent is NamedArgument && parent.name.lexeme == 'textAlign') {
        _report(ProsocheRule.textAlignLeftRight, node);
      }
    }
    super.visitDotShorthandPropertyAccess(node);
  }

  void _checkMember(AstNode node, String type, String member) {
    if (_alignmentTypes.contains(type) &&
        _leftRightAlignments.contains(member)) {
      _report(ProsocheRule.alignmentLeftRight, node);
    } else if (type == 'TextDirection' && member == 'ltr') {
      _report(ProsocheRule.hardcodedTextDirection, node);
    } else if (type == 'TextAlign' && _leftRight.contains(member)) {
      _report(ProsocheRule.textAlignLeftRight, node);
    }
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _checkArabic(node, node.value);
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    final text = node.elements
        .whereType<InterpolationString>()
        .map((e) => e.value)
        .join();
    _checkArabic(node, text);
    super.visitStringInterpolation(node);
  }

  void _checkArabic(StringLiteral node, String value) {
    if (!containsArabicScript(value)) return;
    // Sucast AdjacentStrings sa hlasi raz, cez rodica nie (rodic nema value).
    if (_insideSkArabicText(node)) return;
    _report(ProsocheRule.arabicTextOutsideSkArabicText, node);
  }

  bool _insideSkArabicText(AstNode node) {
    for (var n = node.parent; n != null; n = n.parent) {
      switch (n) {
        case InstanceCreationExpression(:final constructorName):
          final t = constructorName.type;
          if (t.name.lexeme == _skArabicText ||
              t.importPrefix?.name.lexeme == _skArabicText) {
            return true;
          }
        case MethodInvocation(:final target, :final methodName):
          if (methodName.name == _skArabicText) return true;
          if (target is SimpleIdentifier && target.name == _skArabicText) {
            return true;
          }
        case FunctionBody() || ClassMember() || CompilationUnitMember():
          return false;
      }
    }
    return false;
  }
}

bool _isTypeName(String name) =>
    name.isNotEmpty && name[0].toUpperCase() == name[0] && name[0] != '_';

final class _Ignores {
  _Ignores(this.byLine, this.file);

  factory _Ignores.parse(String content) {
    final byLine = <int, Set<String>>{};
    final file = <String>{};
    final lines = content.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final f = _file.firstMatch(lines[i]);
      if (f != null) {
        file.addAll(_codes(f[1]!));
        continue;
      }
      final m = _line.firstMatch(lines[i]);
      if (m != null) byLine[i + 1] = _codes(m[1]!);
    }
    return _Ignores(byLine, file);
  }

  static final _line = RegExp(r'//\s*prosoche-lint:\s*ignore\s+([\w, ]+)');
  static final _file = RegExp(r'//\s*prosoche-lint:\s*ignore-file\s+([\w, ]+)');

  final Map<int, Set<String>> byLine;
  final Set<String> file;

  static Set<String> _codes(String raw) =>
      raw.split(RegExp('[ ,]+')).where((s) => s.isNotEmpty).toSet();

  bool suppresses(LintViolation v) =>
      file.contains(v.rule.code) ||
      (byLine[v.line]?.contains(v.rule.code) ?? false) ||
      (byLine[v.line - 1]?.contains(v.rule.code) ?? false);
}
