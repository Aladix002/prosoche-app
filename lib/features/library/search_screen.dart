import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/features/library/library_routes.dart';
import 'package:prosoche/features/library/widgets/library_widgets.dart';
import 'package:prosoche/features/library/widgets/reader_page.dart';
import 'package:prosoche/ui/ui.dart';

/// Vyhladavanie v celych dielach (FTS5, kontrakt kap. 7). Dotaz sa nikam
/// neposiela (ani do analytiky).
class LibrarySearchScreen extends ConsumerStatefulWidget {
  const LibrarySearchScreen({super.key});

  static const debounce = Duration(milliseconds: 300);

  @override
  ConsumerState<LibrarySearchScreen> createState() =>
      _LibrarySearchScreenState();
}

class _LibrarySearchScreenState extends ConsumerState<LibrarySearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    _debounce = Timer(LibrarySearchScreen.debounce, () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final Widget body;
    if (_query.isEmpty) {
      body = SkEmptyState(
        icon: Icons.search,
        title: l10n.librarySearchHintTitle,
        body: l10n.librarySearchHintBody,
      );
    } else {
      final hits = ref.watch(librarySearchProvider(_query));
      if (hits.hasError && !hits.isLoading) {
        body = SkErrorState(
          title: l10n.errorGeneric,
          onRetry: () => ref.invalidate(librarySearchProvider(_query)),
        );
      } else if (!hits.hasValue) {
        body = const SkLoadingView(skeleton: SkSkeleton.list());
      } else if (hits.requireValue.isEmpty) {
        body = SkEmptyState(
          icon: Icons.search_off,
          title: l10n.librarySearchEmpty,
        );
      } else {
        final list = hits.requireValue;
        body = ListView.separated(
          key: const ValueKey('search:results'),
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final h = list[i];
            return SectionRow(
              key: ValueKey('hit:${h.sectionKey}'),
              reference: h.reference,
              preview: SnippetText(h.snippet),
              onTap: () => unawaited(
                openReader(context, workId: h.workId, section: h.sectionKey),
              ),
            );
          },
        );
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const ValueKey('search:field'),
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.librarySearchHint,
            border: InputBorder.none,
          ),
          onChanged: _changed,
          onSubmitted: (v) {
            _debounce?.cancel();
            setState(() => _query = v.trim());
          },
        ),
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}
