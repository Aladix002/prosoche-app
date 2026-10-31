import 'package:flutter/widgets.dart';

/// Clamp systemoveho textScale pre UI na 2.0 (docs/01 8.3, D12).
///
/// Vlozit raz pod `MaterialApp` (napr. v `builder`). Povodny (neclampnuty)
/// scaler si drzi pre texty, ktore sa clampovat nemaju ([unclampedOf]).
class SkTextScaling extends StatelessWidget {
  const SkTextScaling({
    required this.child,
    this.maxScaleFactor = 2,
    super.key,
  });

  final Widget child;
  final double maxScaleFactor;

  /// Systemovy scaler pred clampom, ak je v strome [SkTextScaling];
  /// inak aktualny `MediaQuery.textScalerOf`.
  static TextScaler unclampedOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_UnclampedScaler>()?.scaler ??
      MediaQuery.textScalerOf(context);

  @override
  Widget build(BuildContext context) => _UnclampedScaler(
    scaler: MediaQuery.textScalerOf(context),
    child: MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxScaleFactor,
      child: child,
    ),
  );
}

class _UnclampedScaler extends InheritedWidget {
  const _UnclampedScaler({required this.scaler, required super.child});

  final TextScaler scaler;

  @override
  bool updateShouldNotify(_UnclampedScaler oldWidget) =>
      oldWidget.scaler != scaler;
}
