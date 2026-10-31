import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Najvacsi nasobok pisma titulku [AppBar] (Material ho clampuje na 1.34,
/// aby titulok neprebil hierarchiu obrazovky).
const double skAppBarTitleMaxScale = 1.34;

/// Sirka tlacidla `leading` a akcii v [AppBar].
const double _kActionWidth = kToolbarHeight;

/// Titulok [AppBar], ktory sa pri velkom pisme neoreze (A11Y-1, docs/01
/// 8.3): najviac 2 riadky namiesto jedneho s elipsou. Vysku toolbaru
/// k nemu dopocita [skAppBar].
class SkAppBarTitle extends StatelessWidget {
  const SkAppBarTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, maxLines: 2, softWrap: true, overflow: TextOverflow.ellipsis);
}

/// [AppBar] s titulkom [SkAppBarTitle]. Ked sa titulok pri danej sirke
/// a velkosti pisma nezmesti na riadok, toolbar sa zvysi na 2 riadky
/// (inak ostane standardnych [kToolbarHeight]).
AppBar skAppBar(
  BuildContext context, {
  required String title,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
}) => AppBar(
  title: SkAppBarTitle(title),
  actions: actions,
  bottom: bottom,
  toolbarHeight: skAppBarToolbarHeight(
    context,
    title,
    actionsCount: actions?.length ?? 0,
  ),
);

/// Vyska toolbaru pre [title]: [kToolbarHeight] alebo viac, ked sa
/// titulok zalomi na 2 riadky.
double skAppBarToolbarHeight(
  BuildContext context,
  String title, {
  int actionsCount = 0,
}) {
  final theme = Theme.of(context);
  final style = theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge!;
  final route = ModalRoute.of(context);
  final hasLeading = route?.impliesAppBarDismissal ?? false;
  final width = MediaQuery.sizeOf(context).width;
  // NavigationToolbar: medzera 16 dp na oboch stranach titulku.
  final available =
      width -
      (hasLeading ? _kActionWidth : 0) -
      actionsCount * _kActionWidth -
      2 * NavigationToolbar.kMiddleSpacing;
  final painter = TextPainter(
    text: TextSpan(text: title, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: skAppBarTitleMaxScale),
    maxLines: 2,
  )..layout(maxWidth: math.max(available, 1));
  try {
    final lines = painter.computeLineMetrics().length;
    if (lines <= 1) return kToolbarHeight;
    return math.max(kToolbarHeight, painter.height + 2 * 12);
  } finally {
    painter.dispose();
  }
}
