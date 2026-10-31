/// RTL a arabsky text lint pre Prosoche (U-02).
///
/// custom_lint 0.8.x vyzaduje analyzer ^8 a s analyzerom 14 (Dart 3.13)
/// sa neda vyriesit, preto je kontrola samostatny syntakticky checker
/// spustany z `tool/check.sh` (`dart run prosoche_lints:check lib`).
library;

export 'src/checker.dart'
    show
        allowedRulesByPathPrefix,
        checkPaths,
        checkSource,
        containsArabicScript,
        isExcludedPath;
export 'src/rules.dart';
