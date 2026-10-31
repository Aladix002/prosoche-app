import 'package:flutter/material.dart';
import 'package:prosoche/ui/theme/sk_context.dart';
import 'package:prosoche/ui/tokens/sk_space.dart';

/// Maly tag (oznacenie). `radiusXs`, `surfaceAlt`.
class SkTag extends StatelessWidget {
  const SkTag({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: SkSpace.space8,
        vertical: SkSpace.space2,
      ),
      decoration: BoxDecoration(
        color: sk.colors.surfaceAlt,
        borderRadius: BorderRadius.circular(SkRadius.xs),
      ),
      child: Text(
        label,
        style: sk.text.labelSmall!.copyWith(color: sk.colors.accentText),
      ),
    );
  }
}
