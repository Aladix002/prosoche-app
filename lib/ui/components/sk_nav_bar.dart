import 'package:flutter/material.dart';
import 'package:prosoche/ui/theme/sk_context.dart';

/// Destinacia spodnej navigacie.
@immutable
class SkNavDestination {
  const SkNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  /// Neaktivna ikona (fill 0).
  final IconData icon;

  /// Aktivna ikona (fill 1).
  final IconData selectedIcon;
  final String label;
}

/// Spodna navigacia (docs/01 3.2 `SkNavBar`): M3 `NavigationBar`, 64 dp +
/// safe area, labely vzdy viditelne, indikator `primaryContainer`, ziadne
/// badge. Nad sebou ma 1 dp `outline` (elevacia e2).
///
/// Pri velkom texte (`context.sk.largeText`) sa ikony zmensia na 20 a label
/// sa smie zalomit na 2 riadky (docs/01 8.3).
class SkNavBar extends StatelessWidget {
  const SkNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<SkNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Vsetky Prosoche taby (docs/01 4.1) maju 4 destinacie.
  static const List<(IconData, IconData)> tabIcons = [
    (Icons.wb_twilight_outlined, Icons.wb_twilight),
    (Icons.menu_book_outlined, Icons.menu_book),
    (Icons.mosque_outlined, Icons.mosque),
    (Icons.route_outlined, Icons.route),
  ];

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final large = sk.largeText;
    final iconSize = large ? 20.0 : 24.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: sk.colors.outline)),
      ),
      child: NavigationBarTheme(
        data: NavigationBarTheme.of(context).copyWith(
          height: large ? 80 : 64,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (s) => sk.text.labelSmall!.copyWith(
              color: s.contains(WidgetState.selected)
                  ? sk.colors.textPrimary
                  : sk.colors.textSecondary,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon, size: iconSize),
                selectedIcon: Icon(d.selectedIcon, size: iconSize),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }
}
