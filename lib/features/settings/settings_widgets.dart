import 'package:flutter/material.dart';
import 'package:sakina/ui/ui.dart';

/// Kostra podobrazovky nastaveni: AppBar a zoznam s max. sirkou obsahu.
class SettingsScaffold extends StatelessWidget {
  const SettingsScaffold({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: skAppBar(context, title: title),
    body: SettingsList(children: children),
  );
}

/// Zoznam nastaveni centrovany na [SkSpace.maxContentWidth].
class SettingsList extends StatelessWidget {
  const SettingsList({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: SkSpace.maxContentWidth),
      child: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: SkSpace.space32),
        children: children,
      ),
    ),
  );
}

/// Nadpis sekcie (Semantics header) s volitelnym vysvetlenim.
class SettingsSection extends StatelessWidget {
  const SettingsSection(this.title, {this.help, super.key});

  final String title;
  final String? help;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        SkSpace.space16,
        SkSpace.space24,
        SkSpace.space16,
        SkSpace.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: sk.text.titleSmall!.copyWith(color: sk.colors.accentText),
            ),
          ),
          if (help != null) ...[
            const SizedBox(height: SkSpace.space4),
            Text(
              help!,
              style: sk.text.bodySmall!.copyWith(
                color: sk.colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Odsek textu v zozname (vysvetlenie, disclaimer).
class SettingsNote extends StatelessWidget {
  const SettingsNote(this.text, {this.secondary = true, super.key});

  final String text;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: SkSpace.space16,
        vertical: SkSpace.space8,
      ),
      child: Text(
        text,
        style: sk.text.bodyMedium!.copyWith(
          color: secondary ? sk.colors.textSecondary : null,
        ),
      ),
    );
  }
}

/// Riadok, ktory otvori podobrazovku; [value] je aktualna hodnota.
class SettingsNavTile extends StatelessWidget {
  const SettingsNavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.warning = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;

  /// Varovna ikona (napr. brana nebezi, docs/02 A10.0).
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    return ListTile(
      // D-05: ikona v tonalnom kruhu (jednotne s questami na Dnes).
      leading: ExcludeSemantics(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: sk.colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: sk.colors.onPrimaryContainer),
        ),
      ),
      title: Text(title),
      subtitle: value == null ? null : Text(value!),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (warning) Icon(Icons.warning_amber, color: sk.colors.warning),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
