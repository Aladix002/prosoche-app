import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/library/library.dart';
import 'package:prosoche/domain/settings/settings_repository.dart';
import 'package:prosoche/features/library/library_routes.dart';
import 'package:prosoche/features/library/widgets/library_widgets.dart';
import 'package:prosoche/features/library/widgets/reader_page.dart';
import 'package:prosoche/ui/ui.dart';

/// Citacka diela (F-01): jedna sekcia na stranu (PageView), pozicia
/// citania sa uklada pri kazdej zmene strany, zalozka na sekciu, obsah
/// (knihy a sekcie) a vyhladavanie.
///
/// [sectionKey] otvori danu sekciu (napr. "Read in context" z karty),
/// inak poslednu poziciu citania, inak prvu sekciu. [highlight] (text karty)
/// sa v sekcii zvyrazni.
class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({
    required this.workId,
    this.sectionKey,
    this.highlight,
    super.key,
  });

  final String workId;
  final String? sectionKey;
  final String? highlight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final work = ref.watch(workTextProvider(workId));
    final positions = ref.watch(readingPositionsProvider);
    if (work.hasError && !work.isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: SkErrorState(
          title: l10n.errorGeneric,
          onRetry: () => ref.invalidate(workTextProvider(workId)),
        ),
      );
    }
    final text = work.value;
    if (!work.hasValue || (sectionKey == null && !positions.hasValue)) {
      return Scaffold(
        appBar: AppBar(),
        body: const SkLoadingView(skeleton: SkSkeleton.list()),
      );
    }
    if (text == null || text.sections.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: SkEmptyState(
          icon: Icons.menu_book_outlined,
          title: l10n.readerMissingTitle,
          body: l10n.readerMissingBody,
        ),
      );
    }
    final keys = [for (final s in text.sections) s.key];
    final start =
        sectionKey ?? positions.value?[workId]?.sectionKey ?? keys.first;
    return _Reader(
      key: ValueKey('reader:$workId'),
      text: text,
      initialIndex: sectionIndex(keys, start),
      highlightKey: sectionKey,
      highlight: highlight,
    );
  }
}

class _Reader extends ConsumerStatefulWidget {
  const _Reader({
    required this.text,
    required this.initialIndex,
    this.highlightKey,
    this.highlight,
    super.key,
  });

  final WorkText text;
  final int initialIndex;
  final String? highlightKey;
  final String? highlight;

  @override
  ConsumerState<_Reader> createState() => _ReaderState();
}

class _ReaderState extends ConsumerState<_Reader> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  List<LibrarySection> get _sections => widget.text.sections;
  LibrarySection get _current => _sections[_index];

  @override
  void initState() {
    super.initState();
    // Az po prvom frame: zapis meni providery (pozicia citania).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _save();
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _save() {
    final s = _sections[_index];
    unawaited(
      ref.read(libraryRepositoryProvider).savePosition(s.workId, s.key),
    );
  }

  void _onPage(int i) {
    setState(() => _index = i);
    _save();
  }

  Future<void> _go(int i) async {
    if (i < 0 || i >= _sections.length) return;
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _pages.jumpToPage(i);
    } else {
      await _pages.animateToPage(
        i,
        duration: const Duration(milliseconds: 320),
        curve: const Cubic(0.2, 0, 0, 1),
      );
    }
  }

  Future<void> _contents() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => _ContentsSheet(text: widget.text, current: _index),
    );
    if (picked != null) await _go(picked);
  }

  Future<void> _toggleBookmark({required bool on}) async {
    final l10n = context.l10n;
    final s = _current;
    await ref
        .read(libraryRepositoryProvider)
        .setBookmark(s.key, s.workId, on: on);
    if (!mounted) return;
    showSkSnackbar(
      context,
      message: on ? l10n.readerBookmarkAdded : l10n.readerBookmarkRemoved,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final work = widget.text.work;
    final marked = {
      for (final b
          in ref.watch(sectionBookmarksProvider).value ??
              const <SectionBookmark>[])
        b.sectionKey,
    };
    final bookmarked = marked.contains(_current.key);
    final size = readerSizeOf(
      ref.watch(settingOf(SettingsKeys.readerScale)).value,
    );
    final progress = readingProgress(_index + 1, _sections.length);
    return Scaffold(
      appBar: AppBar(
        actions: [
          SkIconButton(
            key: const ValueKey('reader:bookmark'),
            icon: Icons.bookmark_border,
            selectedIcon: Icons.bookmark,
            selected: bookmarked,
            tooltip: bookmarked
                ? l10n.readerRemoveBookmark
                : l10n.readerAddBookmark,
            onPressed: () => unawaited(_toggleBookmark(on: !bookmarked)),
          ),
          SkIconButton(
            key: const ValueKey('reader:text_size'),
            icon: Icons.format_size,
            tooltip: l10n.readerTextSize,
            onPressed: () => unawaited(showReaderSizeSheet(context, ref)),
          ),
          SkIconButton(
            key: const ValueKey('reader:contents'),
            icon: Icons.list,
            tooltip: l10n.readerContents,
            onPressed: () => unawaited(_contents()),
          ),
          SkIconButton(
            icon: Icons.search,
            tooltip: l10n.librarySearch,
            onPressed: () => context.push(LibraryRoutes.search),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: SkReadingProgress(
            value: progress,
            label: l10n.readerProgressA11y,
            valueLabel: l10n.readerProgressValue(_index + 1, _sections.length),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                key: const ValueKey('reader:pages'),
                controller: _pages,
                onPageChanged: _onPage,
                itemCount: _sections.length,
                itemBuilder: (context, i) {
                  final s = _sections[i];
                  final book = s.book;
                  final first = i == 0 || _sections[i - 1].book != book;
                  final bookTitle = book == null
                      ? null
                      : widget.text.books
                            .where((b) => b.number == book)
                            .firstOrNull
                            ?.title;
                  return ReaderPage(
                    key: ValueKey('reader:section:${s.key}'),
                    section: s,
                    bookTitle: first ? bookTitle : null,
                    work: work,
                    highlight: s.key == widget.highlightKey
                        ? widget.highlight
                        : null,
                    targeted: s.key == widget.highlightKey,
                    size: size,
                  );
                },
              ),
            ),
            _PageNav(
              index: _index,
              count: _sections.length,
              onPrevious: () => unawaited(_go(_index - 1)),
              onNext: () => unawaited(_go(_index + 1)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vyber velkosti pisma citacky (S-XL), uklada `reader.scale` (I-01).
/// To iste nastavenie je v Settings > Display.
Future<void> showReaderSizeSheet(BuildContext context, WidgetRef ref) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => const SafeArea(
        child: SingleChildScrollView(child: ReaderSizePicker()),
      ),
    );

/// Radio S, M, L, XL nad nastavenim `reader.scale`.
class ReaderSizePicker extends ConsumerWidget {
  const ReaderSizePicker({this.showTitle = true, super.key});

  final bool showTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final value =
        ref.watch(settingOf(SettingsKeys.readerScale)).value ??
        SettingsKeys.readerScale.defaultValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: SkSpace.space16,
            ),
            child: Semantics(
              header: true,
              child: Text(l10n.readerTextSize, style: sk.text.titleLarge),
            ),
          ),
        RadioGroup<String>(
          groupValue: value,
          onChanged: (v) {
            if (v != null) {
              unawaited(
                ref
                    .read(settingsRepositoryProvider)
                    .set(SettingsKeys.readerScale, v),
              );
            }
          },
          child: Column(
            children: [
              for (final v in SettingsKeys.readerScales)
                RadioListTile<String>(
                  key: ValueKey('reader_scale:$v'),
                  value: v,
                  title: Text(
                    l10n.readerTextSizeName(v),
                    style: sk.type.reader.copyWith(
                      fontSize:
                          sk.type.reader.fontSize! * readerSizeOf(v).factor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PageNav extends StatelessWidget {
  const _PageNav({
    required this.index,
    required this.count,
    required this.onPrevious,
    required this.onNext,
  });

  final int index;
  final int count;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: SkSpace.space8,
        vertical: SkSpace.space4,
      ),
      child: Row(
        children: [
          SkIconButton(
            key: const ValueKey('reader:previous'),
            icon: Icons.chevron_left,
            tooltip: l10n.readerPrevious,
            onPressed: index > 0 ? onPrevious : null,
          ),
          Expanded(
            child: Text(
              l10n.readerProgressValue(index + 1, count),
              textAlign: TextAlign.center,
              style: sk.text.labelMedium!.copyWith(
                color: sk.colors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          SkIconButton(
            key: const ValueKey('reader:next'),
            icon: Icons.chevron_right,
            tooltip: l10n.readerNext,
            onPressed: index < count - 1 ? onNext : null,
          ),
        ],
      ),
    );
  }
}

/// Obsah diela: knihy a sekcie s referenciami a nadpismi kapitol.
class _ContentsSheet extends StatelessWidget {
  const _ContentsSheet({required this.text, required this.current});

  final WorkText text;
  final int current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final rows = <Widget>[];
    var i = 0;
    for (final b in text.books) {
      if (b.title case final t?) {
        rows.add(AuthorHeading(name: t));
      }
      for (final s in b.sections) {
        final index = i++;
        rows.add(
          ListTile(
            key: ValueKey('contents:${s.key}'),
            selected: index == current,
            minTileHeight: SkSpace.minTouchTarget,
            title: Text(s.reference, style: sk.text.titleSmall),
            subtitle: s.title == null ? null : Text(s.title!),
            onTap: () => Navigator.of(context).pop(index),
          ),
        );
      }
    }
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: SkSpace.space16,
            ),
            child: Text(l10n.readerContents, style: sk.text.titleLarge),
          ),
          Expanded(
            child: ListView(controller: controller, children: rows),
          ),
        ],
      ),
    );
  }
}
