import 'package:flutter/material.dart';
import 'package:prosoche/ui/components/sk_states.dart';
import 'package:prosoche/ui/foundation/sk_ui_strings.dart';

/// E-CONTENT-1: text Koranu sa nezobrazi, radsej chybovy stav
/// (docs/01 1.3 bod 10, docs/01 6 "Quran - zoznam sur/citatel").
class QuranContentError extends StatelessWidget {
  const QuranContentError({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = SkUiStrings.of(context);
    return Center(
      child: SingleChildScrollView(
        child: SkErrorState(
          title: s.contentUnavailableTitle,
          body: s.contentUnavailableBody,
          onRetry: onRetry,
        ),
      ),
    );
  }
}

/// Skeleton riadkov zoznamu/readera (zobrazi sa az po 300 ms).
class QuranLoading extends StatelessWidget {
  const QuranLoading({this.lines = 6, super.key});

  final int lines;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsetsDirectional.all(16),
    child: SkLoadingView(skeleton: SkSkeleton.list(lines: lines)),
  );
}
