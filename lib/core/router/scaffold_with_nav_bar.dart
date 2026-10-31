import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/ui/components/sk_nav_bar.dart';

/// Shell so spodnou navigaciou pre 4 taby (docs/01 kap. 4.1, `SkNavBar`).
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = [
      l10n.tabToday,
      l10n.tabLibrary,
      l10n.tabPractice,
      l10n.tabJourney,
    ];
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SkNavBar(
        selectedIndex: navigationShell.currentIndex,
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (final (i, (icon, selectedIcon)) in SkNavBar.tabIcons.indexed)
            SkNavDestination(
              icon: icon,
              selectedIcon: selectedIcon,
              label: labels[i],
            ),
        ],
      ),
    );
  }
}
