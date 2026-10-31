import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/features/settings/settings_routes.dart';
import 'package:sakina/ui/components/sk_button.dart';

/// Ozubene koleso do app baru Today a Journey (docs/01 4.1). Nastavenia sa
/// otvoria ako push route nad shellom (bez spodnej navigacie).
class ShellSettingsButton extends StatelessWidget {
  const ShellSettingsButton({super.key});

  @override
  Widget build(BuildContext context) => SkIconButton(
    icon: Icons.settings_outlined,
    tooltip: context.l10n.shellSettings,
    onPressed: () => context.push(SettingsRoutes.root),
  );
}
