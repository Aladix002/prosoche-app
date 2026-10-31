import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prosoche/ui/components/sk_button.dart';
import 'package:prosoche/ui/foundation/sk_ui_strings.dart';
import 'package:prosoche/ui/motif/sk_motif.dart';
import 'package:prosoche/ui/theme/sk_context.dart';
import 'package:prosoche/ui/tokens/sk_space.dart';

/// Prazdny stav: volitelna ilustracia/ornament, titulok, text, 1 akcia
/// (docs/01 3.2 Banery a feedback).
class SkEmptyState extends StatelessWidget {
  const SkEmptyState({
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.illustration,
    this.icon,
    super.key,
  });

  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Dekor (obalene `ExcludeSemantics`); default medailon motivu (D-05).
  final Widget? illustration;

  /// Ikona v strede medailonu (napr. zalozka pri prazdnych ulozenych).
  final IconData? icon;

  @override
  Widget build(BuildContext context) => _StateLayout(
    illustration: illustration ?? SkMotifBadge(icon: icon),
    title: title,
    body: body,
    actions: [
      if (actionLabel != null)
        SkButton.secondary(label: actionLabel!, onPressed: onAction),
    ],
  );
}

/// Chybovy stav: co sa stalo, co sa da urobit, "Try again", volitelne
/// "Report a problem" (docs/01 6).
class SkErrorState extends StatelessWidget {
  const SkErrorState({
    required this.title,
    this.body,
    this.onRetry,
    this.retryLabel,
    this.secondaryLabel,
    this.onSecondary,
    this.illustrated = true,
    super.key,
  });

  final String title;
  final String? body;
  final VoidCallback? onRetry;

  /// Maly tichy medailon nad textom (D-05); bez cervenej a vykricnika.
  final bool illustrated;

  /// Default `SkUiStrings.tryAgain`.
  final String? retryLabel;

  /// Napr. "Report a problem" alebo "Skip this card".
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final strings = SkUiStrings.of(context);
    return _StateLayout(
      title: title,
      body: body,
      liveRegion: true,
      illustration: illustrated
          ? const SkMotifBadge(icon: Icons.refresh_rounded, size: 64)
          : null,
      actions: [
        if (onRetry != null)
          SkButton.secondary(
            label: retryLabel ?? strings.tryAgain,
            onPressed: onRetry,
          ),
        if (secondaryLabel != null)
          SkButton.tertiary(label: secondaryLabel!, onPressed: onSecondary),
      ],
    );
  }
}

class _StateLayout extends StatelessWidget {
  const _StateLayout({
    required this.title,
    required this.actions,
    this.body,
    this.illustration,
    this.liveRegion = false,
  });

  final String title;
  final String? body;
  final Widget? illustration;
  final List<Widget> actions;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: SkSpace.space24,
        vertical: SkSpace.space48,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pri velkom texte bez dekoru: text ma prednost (docs/01 8.3).
          if (illustration != null && !sk.largeText) ...[
            ExcludeSemantics(child: illustration),
            const SizedBox(height: SkSpace.space24),
          ],
          Semantics(
            header: true,
            liveRegion: liveRegion,
            child: Text(
              title,
              style: sk.text.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: SkSpace.space8),
            Text(
              body!,
              style: sk.text.bodyLarge!.copyWith(
                color: sk.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: SkSpace.space24),
            for (final (i, a) in actions.indexed) ...[
              if (i > 0) const SizedBox(height: SkSpace.space8),
              SizedBox(width: double.infinity, child: a),
            ],
          ],
        ],
      ),
    );
  }
}

/// Staticky placeholder tvaru (docs/01 3.2 `SkSkeleton`). Nikdy fake
/// arabsky text. Bez shimmer animacie (pokoj, P2; nerozbije
/// `pumpAndSettle` v testoch obrazoviek).
class SkSkeletonBox extends StatelessWidget {
  const SkSkeletonBox({
    this.width,
    this.height = 16,
    this.radius = SkRadius.xs,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.sk.colors.surfaceAlt,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Skeleton karty alebo zoznamu.
class SkSkeleton extends StatelessWidget {
  const SkSkeleton.card({super.key}) : _lines = 0;

  const SkSkeleton.list({this._lines = 3, super.key});

  final int _lines;

  @override
  Widget build(BuildContext context) {
    final strings = SkUiStrings.of(context);
    final Widget child;
    if (_lines == 0) {
      child = Container(
        padding: const EdgeInsets.all(SkSpace.space24),
        decoration: BoxDecoration(
          color: context.sk.colors.surface,
          borderRadius: BorderRadius.circular(SkRadius.lg),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkSkeletonBox(width: 120, height: 12),
            SizedBox(height: SkSpace.space32),
            Center(child: SkSkeletonBox(width: 220, height: 40)),
            SizedBox(height: SkSpace.space32),
            SkSkeletonBox(),
            SizedBox(height: SkSpace.space8),
            SkSkeletonBox(width: 200),
          ],
        ),
      );
    } else {
      child = Column(
        children: [
          for (var i = 0; i < _lines; i++)
            const Padding(
              padding: EdgeInsetsDirectional.symmetric(
                vertical: SkSpace.space8,
              ),
              child: Row(
                children: [
                  SkSkeletonBox(width: 28, height: 28, radius: SkRadius.full),
                  SizedBox(width: SkSpace.space12),
                  Expanded(child: SkSkeletonBox()),
                ],
              ),
            ),
        ],
      );
    }
    return Semantics(
      label: strings.loading,
      child: ExcludeSemantics(child: child),
    );
  }
}

/// Loading podla docs/01 6: pod 300 ms nic, potom skeleton, po 3 s
/// "Still loading…". Chybovy stav po 10 s riesi volajuci (ma kontext).
class SkLoadingView extends StatefulWidget {
  const SkLoadingView({
    this.skeleton = const SkSkeleton.card(),
    this.showAfter = const Duration(milliseconds: 300),
    this.stillLoadingAfter = const Duration(seconds: 3),
    super.key,
  });

  final Widget skeleton;
  final Duration showAfter;
  final Duration stillLoadingAfter;

  @override
  State<SkLoadingView> createState() => _SkLoadingViewState();
}

class _SkLoadingViewState extends State<SkLoadingView> {
  final _timers = <Timer>[];
  bool _visible = false;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _visible = widget.showAfter == Duration.zero;
    _timers
      ..add(Timer(widget.showAfter, () => setState(() => _visible = true)))
      ..add(
        Timer(widget.stillLoadingAfter, () => setState(() => _slow = true)),
      );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final sk = context.sk;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.skeleton,
        if (_slow) ...[
          const SizedBox(height: SkSpace.space16),
          Semantics(
            liveRegion: true,
            child: Text(
              SkUiStrings.of(context).stillLoading,
              style: sk.text.bodyMedium,
            ),
          ),
        ],
      ],
    );
  }
}

/// Stav obrazovky (docs/01 6).
enum SkViewState { loading, empty, data, error }

/// Prepina medzi stavmi obrazovky s crossfade (`motion.crossfade`).
class SkStateView extends StatelessWidget {
  const SkStateView({
    required this.state,
    required this.data,
    this.loading = const SkLoadingView(),
    this.empty = const SizedBox.shrink(),
    this.error = const SizedBox.shrink(),
    super.key,
  });

  final SkViewState state;
  final WidgetBuilder data;
  final Widget loading;
  final Widget empty;
  final Widget error;

  @override
  Widget build(BuildContext context) {
    final motion = context.sk.motion.crossfade;
    final child = switch (state) {
      SkViewState.loading => loading,
      SkViewState.empty => empty,
      SkViewState.error => error,
      SkViewState.data => Builder(builder: data),
    };
    return AnimatedSwitcher(
      duration: motion.duration,
      switchInCurve: motion.curve,
      switchOutCurve: motion.curve,
      child: KeyedSubtree(key: ValueKey(state), child: child),
    );
  }
}
