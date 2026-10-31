import 'package:flutter/material.dart';
import 'package:prosoche/features/shell/settings_button.dart';
import 'package:prosoche/ui/ui.dart';

/// Docasny obsah tabu, kym featura nedoda skutocne UI (S-01 -> F-01).
class TabPlaceholder extends StatelessWidget {
  const TabPlaceholder({
    required this.title,
    required this.icon,
    required this.body,
    super.key,
  });

  final String title;
  final IconData icon;
  final String body;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: skAppBar(
      context,
      title: title,
      actions: const [ShellSettingsButton()],
    ),
    body: SafeArea(
      child: SkEmptyState(icon: icon, title: title, body: body),
    ),
  );
}
