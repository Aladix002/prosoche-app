import 'package:flutter/material.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/features/shell/tab_placeholder.dart';

/// Library: citanie celych diel po knihach a sekciach. Zatial placeholder,
/// implementuje F-01 (PLAN.md kap. 2).
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TabPlaceholder(
      key: const ValueKey('library:placeholder'),
      title: l10n.tabLibrary,
      icon: Icons.menu_book_outlined,
      body: l10n.libraryPlaceholderBody,
    );
  }
}
