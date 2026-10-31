import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/features/library/library_routes.dart';
import 'package:prosoche/features/library/widgets/library_widgets.dart';
import 'package:prosoche/ui/ui.dart';

/// Library (F-01): autori a ich diela z content.db, pokracovanie v citani,
/// vyhladavanie a zalozky. Zoznam bez motivu (docs/DESIGN.md 5.3).
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final authors = ref.watch(libraryAuthorsProvider);
    final positions =
        ref.watch(readingPositionsProvider).value ??
        const <String, ReadingPosition>{};
    final Widget body;
    if (authors.hasError && !authors.isLoading) {
      body = SkErrorState(
        title: l10n.errorGeneric,
        onRetry: () => ref.invalidate(libraryAuthorsProvider),
      );
    } else if (!authors.hasValue) {
      body = const SkLoadingView(skeleton: SkSkeleton.list());
    } else if (authors.requireValue.isEmpty) {
      body = SkEmptyState(
        icon: Icons.menu_book_outlined,
        title: l10n.libraryEmptyTitle,
        body: l10n.libraryEmptyBody,
      );
    } else {
      final works = {
        for (final a in authors.requireValue)
          for (final w in a.works) w.id: w,
      };
      final last = ref.watch(lastReadingProvider).value;
      final lastWork = last == null ? null : works[last.workId];
      body = ListView(
        key: const ValueKey('library:list'),
        padding: const EdgeInsetsDirectional.only(bottom: SkSpace.space24),
        children: [
          if (last != null && lastWork != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                SkSpace.space16,
                SkSpace.space8,
                SkSpace.space16,
                SkSpace.space8,
              ),
              child: ContinueReadingTile(work: lastWork, position: last),
            ),
          for (final a in authors.requireValue) ...[
            AuthorHeading(name: a.name, lifespan: a.lifespan),
            for (final w in a.works)
              WorkTile(
                work: w,
                position: positions[w.id],
                onTap: () => unawaited(openReader(context, workId: w.id)),
              ),
            const Divider(height: SkSpace.space24),
          ],
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabLibrary, style: sk.text.headlineSmall),
        actions: [
          SkIconButton(
            key: const ValueKey('library:search'),
            icon: Icons.search,
            tooltip: l10n.librarySearch,
            onPressed: () => context.push(LibraryRoutes.search),
          ),
          SkIconButton(
            key: const ValueKey('library:bookmarks'),
            icon: Icons.bookmarks_outlined,
            tooltip: l10n.libraryBookmarks,
            onPressed: () => context.push(LibraryRoutes.bookmarks),
          ),
        ],
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}
