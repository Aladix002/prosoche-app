import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/features/library/library_routes.dart';
import 'package:prosoche/features/library/widgets/reader_page.dart';
import 'package:prosoche/ui/ui.dart';

/// Zalozky na sekcie (najnovsie prve). Tap otvori citacku na sekcii.
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final marks = ref.watch(sectionBookmarksProvider);
    final Widget body;
    if (marks.hasError && !marks.isLoading) {
      body = SkErrorState(
        title: l10n.errorGeneric,
        onRetry: () => ref.invalidate(sectionBookmarksProvider),
      );
    } else if (!marks.hasValue) {
      body = const SkLoadingView(skeleton: SkSkeleton.list());
    } else if (marks.requireValue.isEmpty) {
      body = SkEmptyState(
        icon: Icons.bookmarks_outlined,
        title: l10n.libraryBookmarksEmptyTitle,
        body: l10n.libraryBookmarksEmptyBody,
      );
    } else {
      final list = marks.requireValue;
      body = ListView.separated(
        key: const ValueKey('bookmarks:list'),
        itemCount: list.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) =>
            _BookmarkRow(bookmark: list[i], key: ValueKey(list[i].sectionKey)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.libraryBookmarks)),
      body: SafeArea(top: false, child: body),
    );
  }
}

class _BookmarkRow extends ConsumerWidget {
  const _BookmarkRow({required this.bookmark, super.key});

  final SectionBookmark bookmark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final section = ref.watch(sectionProvider(bookmark.sectionKey)).value;
    final preview = section == null ? '' : section.paragraphs.firstOrNull ?? '';
    return SectionRow(
      reference: section?.reference ?? bookmark.sectionKey,
      preview: Text(
        preview,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: sk.text.bodyMedium!.copyWith(color: sk.colors.textSecondary),
      ),
      trailing: SkIconButton(
        icon: Icons.bookmark_remove_outlined,
        tooltip: l10n.readerRemoveBookmark,
        onPressed: () => unawaited(
          ref
              .read(libraryRepositoryProvider)
              .setBookmark(bookmark.sectionKey, bookmark.workId, on: false),
        ),
      ),
      onTap: () => unawaited(
        openReader(
          context,
          workId: bookmark.workId,
          section: bookmark.sectionKey,
        ),
      ),
    );
  }
}
