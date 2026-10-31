import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/router/scaffold_with_nav_bar.dart';

/// Shell so 4 tabmi (docs/01 D1) a back spravanim podla docs/02 C5:
/// back na koreni tabu okrem Today prepne na Today, na Today zavrie appku
/// (systemovo, vratane predictive back).
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const todayBranch = 0;

  @override
  Widget build(BuildContext context) {
    final onToday = navigationShell.currentIndex == todayBranch;
    return PopScope<Object?>(
      canPop: onToday,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !onToday) navigationShell.goBranch(todayBranch);
      },
      child: ScaffoldWithNavBar(navigationShell: navigationShell),
    );
  }
}
