import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/domain/quests/quests.dart' show CardContext;
import 'package:prosoche/features/quran/quran_format.dart';
import 'package:prosoche/features/quran/quran_providers.dart';
import 'package:prosoche/features/quran/quran_routes.dart';
import 'package:prosoche/features/quran/reader/read_tracker.dart';
import 'package:prosoche/features/quran/widgets/ayah_tile.dart';
import 'package:prosoche/features/quran/widgets/quran_states.dart';
import 'package:prosoche/features/quran/widgets/reader_sheets.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// Citatel sury (docs/02 A5.2): suvisly text s prekladom, bismillah,
/// cislo versa, pozicia citania (khatm) a posledny otvoreny vers (browse).
///
/// Zoznam versov je lenivy (`SliverList.builder`); skok na `ayah` je cez
/// `CustomScrollView.center`, takze sa nevytvara nic pred cielovym versom.
class QuranReaderScreen extends ConsumerStatefulWidget {
  const QuranReaderScreen({
    required this.surah,
    this.ayahId,
    this.mode = ReaderMode.browse,
    this.dwell = ReadTracker.defaultDwell,
    super.key,
  });

  /// 1..114 (overuje routa).
  final int surah;

  /// `ayah` query parameter (`surah*1000+cislo`); neplatny = zaciatok sury.
  final int? ayahId;
  final ReaderMode mode;
  final Duration dwell;

  static ReaderMode parseMode(String? raw) =>
      raw == ReaderMode.khatm.name ? ReaderMode.khatm : ReaderMode.browse;

  @override
  ConsumerState<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends ConsumerState<QuranReaderScreen> {
  late final ReadTracker _tracker = ReadTracker(
    onRead: _onRead,
    dwell: widget.dwell,
  );
  late final AppLifecycleListener _lifecycle;
  final GlobalKey _scrollKey = GlobalKey();
  static const Key _centerKey = ValueKey('quran-reader-center');
  final _items = <int, BuildContext>{};
  final _topAyah = ValueNotifier<int?>(null);
  final _notice = ValueNotifier<String?>(null);
  final _pendingKhatm = <int>{};
  Timer? _noticeTimer;
  bool _visibilityScheduled = false;
  late final int _anchor;

  @override
  void initState() {
    super.initState();
    final raw = widget.ayahId;
    final id = raw == null ? null : AyahId.tryFromValue(raw);
    final valid = id != null && id.surah == widget.surah;
    _anchor = valid ? id.ayah : 1;
    if (raw != null && !valid) {
      // E-LINK-1: sura sa otvori na zaciatku (docs/02 A5.2).
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showNotice(context.l10n.quranVerseNotFound, sticky: true),
      );
    }
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) => state == AppLifecycleState.resumed
          ? _tracker.resume()
          : _tracker.pause(),
    );
  }

  @override
  void dispose() {
    _tracker.dispose();
    _lifecycle.dispose();
    _noticeTimer?.cancel();
    _topAyah.dispose();
    _notice.dispose();
    super.dispose();
  }

  void _showNotice(String text, {bool sticky = false}) {
    if (!mounted) return;
    _noticeTimer?.cancel();
    _notice.value = text;
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        text,
        Directionality.of(context),
      ),
    );
    if (!sticky) {
      _noticeTimer = Timer(
        const Duration(seconds: 4),
        () => _notice.value = null,
      );
    }
  }

  // ------------------------------------------------------------ citanie

  Future<void> _onRead(int number) async {
    if (!mounted) return;
    final id = AyahId(widget.surah, number);
    final result = await ref
        .read(quranRepositoryProvider)
        .markRead(id, mode: widget.mode, date: ref.read(localDateProvider));
    if (!mounted || widget.mode != ReaderMode.khatm) return;
    if (!result.moved) {
      // Precitany mimo poradia: posunie sa, ked dobehne predchadzajuci.
      _pendingKhatm.add(number);
      return;
    }
    if (result.khatmCompleted != null) {
      unawaited(_showKhatmDone());
      return;
    }
    if (_pendingKhatm.remove(number + 1)) await _onRead(number + 1);
  }

  Future<void> _showKhatmDone() async {
    final l10n = context.l10n;
    final first = ref
        .read(surahsProvider)
        .value
        ?.where((s) => s.id == 1)
        .firstOrNull;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.quranKhatmTitle),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go(
                QuranRoutes.read(
                  1,
                  ayahId: AyahId.first.value,
                  mode: ReaderMode.khatm.name,
                ),
              );
            },
            child: Text(l10n.quranKhatmStartAgain(first?.nameTranslit ?? '1')),
          ),
        ],
      ),
    );
  }

  void _register(int number, BuildContext context) {
    _items[number] = context;
    _scheduleVisibility();
  }

  void _unregister(int number, BuildContext context) {
    if (identical(_items[number], context)) _items.remove(number);
  }

  void _scheduleVisibility() {
    if (_visibilityScheduled) return;
    _visibilityScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityScheduled = false;
      if (mounted) _updateVisibility();
    });
  }

  void _updateVisibility() {
    final view = _scrollKey.currentContext?.findRenderObject();
    if (view is! RenderBox || !view.attached || !view.hasSize) return;
    final viewTop = view.localToGlobal(Offset.zero).dy;
    final viewBottom = viewTop + view.size.height;
    final visible = <int>{};
    int? top;
    var topY = double.infinity;
    for (final MapEntry(key: n, value: ctx) in _items.entries) {
      final box = ctx.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final t = box.localToGlobal(Offset.zero).dy;
      final b = t + box.size.height;
      final fraction = visibleFractionOf(
        top: t,
        bottom: b,
        viewTop: viewTop,
        viewBottom: viewBottom,
      );
      if (fraction >= ReadTracker.visibleFraction) visible.add(n);
      if (b > viewTop && t < viewBottom && t < topY) {
        topY = t;
        top = n;
      }
    }
    _tracker.update(visible);
    _topAyah.value = top;
  }

  // ------------------------------------------------------------- akcie

  Future<void> _setSaved(AyahView ayah, bool save) async {
    final repo = ref.read(cardActionsRepositoryProvider);
    final date = ref.read(localDateProvider);
    final card = AyahCardId(ayah.id);
    if (save) {
      await repo.save(date, card, context: CardContext.reader);
    } else {
      await repo.unsave(date, card, context: CardContext.reader);
    }
  }

  /// "Share as text" format (docs/02 B0.7) bez bidi izolacie.
  String _copyText(AyahView ayah, String surahName, String? attribution) {
    final l10n = context.l10n;
    final reference = Bidi.strip(context.ayahReference(surahName, ayah.id));
    final translation = ayah.translation?.text;
    final source = attribution != null && translation != null
        ? ' ($attribution)'
        : '';
    final body = [ayah.textUthmani, ?translation, '- $reference$source'];
    return '${body.join('\n\n')}\n${l10n.quranShareVia(l10n.appTitle)}';
  }

  Future<void> _openActions(
    AyahView ayah,
    String surahName,
    Map<String, TranslationSource> sources,
  ) async {
    final saved = ref.read(isSavedProvider(AyahCardId(ayah.id))).value ?? false;
    final source = sources[ayah.translation?.sourceId];
    await showVerseActionsSheet(
      context,
      saved: saved,
      copyText: _copyText(ayah, surahName, source?.name),
      onSaved: (v) => _setSaved(ayah, v),
      onCopied: () => _showNotice(context.l10n.quranCopied),
    );
  }

  // -------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final surahAsync = ref.watch(quranSurahProvider(widget.surah));
    final ayahsAsync = ref.watch(surahAyahsProvider(widget.surah));
    final scale = ref.watch(readerArabicScaleProvider);
    final theme = Theme.of(context);
    final typography = context.sk.type.copyWith(arabicScale: scale);

    final Widget body;
    if (surahAsync.hasError || ayahsAsync.hasError) {
      body = QuranContentError(
        onRetry: () => ref
          ..invalidate(quranSurahProvider(widget.surah))
          ..invalidate(surahAyahsProvider(widget.surah)),
      );
    } else if (surahAsync.value case final surah? when ayahsAsync.hasValue) {
      final ayahs = ayahsAsync.requireValue;
      body = ayahs.isEmpty
          ? QuranContentError(
              onRetry: () => ref.invalidate(surahAyahsProvider(widget.surah)),
            )
          : _reader(surah, ayahs);
    } else if (surahAsync.hasValue && surahAsync.value == null) {
      body = QuranContentError(
        onRetry: () => ref.invalidate(quranSurahProvider(widget.surah)),
      );
    } else {
      body = const QuranLoading();
    }

    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values.where((e) => e is! ProsocheTypography),
          typography,
        ],
      ),
      child: Scaffold(
        // Nazov sury je v hlavicke pod listou (zalamuje sa pri 200 %),
        // AppBar ma len spat a "Aa".
        appBar: AppBar(
          actions: [
            SkIconButton(
              icon: Icons.text_fields,
              tooltip: l10n.quranTextSettings,
              onPressed: () => showReaderSettingsSheet(context),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ValueListenableBuilder(
                valueListenable: _notice,
                builder: (context, notice, _) => notice == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsetsDirectional.all(
                          SkSpace.space8,
                        ),
                        child: SkInlineBanner(
                          message: notice,
                          onDismiss: () => _notice.value = null,
                        ),
                      ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reader(SurahInfo surah, List<AyahView> ayahs) {
    final lang = ref.watch(contentLanguageProvider).value ?? 'en';
    final showTranslation = ref.watch(readerShowTranslationProvider);
    final sources = <String, TranslationSource>{
      for (final l in {lang, 'en'})
        if (l != 'ar')
          for (final TranslationSource s
              in ref.watch(translationSourcesProvider(l)).value ?? const [])
            s.id: s,
    };
    final usedSources = {for (final a in ayahs) ?a.translation?.sourceId};
    final attribution = [for (final id in usedSources) ?sources[id]];
    final surahs = ref.watch(surahsProvider).value ?? const <SurahInfo>[];
    final next = surahs.where((s) => s.id == surah.id + 1).firstOrNull;

    final anchorIndex = ayahs.indexWhere((a) => a.number == _anchor);
    final start = anchorIndex < 0 ? 0 : anchorIndex;

    Widget item(int i) {
      final ayah = ayahs[i];
      return _Registered(
        number: ayah.number,
        onAttach: _register,
        onDetach: _unregister,
        child: AyahTile(
          key: ValueKey(ayah.id.value),
          ayah: ayah,
          surahName: surah.nameTranslit,
          contentLang: lang,
          showTranslation: showTranslation,
          onActions: () => _openActions(ayah, surah.nameTranslit, sources),
          onToggleSaved: (v) => _setSaved(ayah, v),
        ),
      );
    }

    final header = _SurahHeader(
      surah: surah,
      attribution: showTranslation && lang != 'ar' ? attribution : const [],
    );
    final footer = _SurahFooter(surah: surah, next: next, mode: widget.mode);

    final slivers = start == 0
        ? <Widget>[
            SliverToBoxAdapter(child: header),
            SliverList.builder(
              itemCount: ayahs.length,
              itemBuilder: (_, i) => item(i),
            ),
            SliverToBoxAdapter(child: footer),
          ]
        : <Widget>[
            // Pred centrom rastie zoznam nahor: kotva-1, ..., 1, hlavicka.
            SliverList.builder(
              itemCount: start + 1,
              itemBuilder: (_, j) => j == start ? header : item(start - 1 - j),
            ),
            SliverList.builder(
              key: _centerKey,
              itemCount: ayahs.length - start,
              itemBuilder: (_, j) => item(start + j),
            ),
            SliverToBoxAdapter(child: footer),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _JuzPageBar(
          title: '${surah.nameTranslit} ${context.quranNumber(surah.id)}',
          ayahs: ayahs,
          top: _topAyah,
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (_) {
              _scheduleVisibility();
              return false;
            },
            child: CustomScrollView(
              key: _scrollKey,
              center: start == 0 ? null : _centerKey,
              slivers: slivers,
            ),
          ),
        ),
      ],
    );
  }
}

/// Registruje kontext riadku versa (meranie viditelnosti).
class _Registered extends StatefulWidget {
  const _Registered({
    required this.number,
    required this.onAttach,
    required this.onDetach,
    required this.child,
  });

  final int number;
  final void Function(int, BuildContext) onAttach;
  final void Function(int, BuildContext) onDetach;
  final Widget child;

  @override
  State<_Registered> createState() => _RegisteredState();
}

class _RegisteredState extends State<_Registered> {
  @override
  void initState() {
    super.initState();
    widget.onAttach(widget.number, context);
  }

  @override
  void didUpdateWidget(_Registered old) {
    super.didUpdateWidget(old);
    if (old.number != widget.number) {
      old.onDetach(old.number, context);
      widget.onAttach(widget.number, context);
    }
  }

  @override
  void dispose() {
    widget.onDetach(widget.number, context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Nazov sury a "Juz 3 · Page 42" podla versa navrchu.
class _JuzPageBar extends StatelessWidget {
  const _JuzPageBar({
    required this.title,
    required this.ayahs,
    required this.top,
  });

  final String title;
  final List<AyahView> ayahs;
  final ValueListenable<int?> top;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    return ValueListenableBuilder(
      valueListenable: top,
      builder: (context, n, _) {
        final ayah =
            ayahs.where((a) => a.number == n).firstOrNull ?? ayahs.first;
        return Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: SkSpace.space16,
            vertical: SkSpace.space4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: sk.text.titleMedium),
              ),
              Text(
                context.l10n.quranJuzPage(
                  context.quranNumber(ayah.juz),
                  context.quranNumber(ayah.page),
                ),
                style: sk.text.bodySmall!.copyWith(
                  color: sk.colors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Hlavicka sury: nazov, preklad nazvu, bismillah (okrem 1 a 9, D4) a
/// atribucia prekladu (docs/01 1.3 bod 8, docs/09 2.2).
class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.surah, required this.attribution});

  final SurahInfo surah;
  final List<TranslationSource> attribution;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final secondary = sk.text.bodySmall!.copyWith(
      color: sk.colors.textSecondary,
    );
    final bismillah = surah.bismillahUthmani;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        SkSpace.space16,
        SkSpace.space16,
        SkSpace.space16,
        SkSpace.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkArabicText.text(surah.nameAr),
          Semantics(
            header: true,
            child: Text(
              surah.nameTranslit,
              style: sk.text.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          if (surah.nameMeaning case final meaning?)
            Text(
              meaning,
              style: sk.text.bodyLarge,
              textAlign: TextAlign.center,
            ),
          Text(
            '${context.revelationLabel(surah)} · '
            '${l10n.quranAyahCount(surah.ayahCount)}',
            style: secondary,
            textAlign: TextAlign.center,
          ),
          if (surah.bismillahPre && bismillah != null)
            SkArabicText.quran(
              [SkArabicSegment(bismillah)],
              textSimple: bismillah,
              style: SkQuranStyle.bismillah,
            ),
          for (final s in attribution) ...[
            const SizedBox(height: SkSpace.space8),
            Text(
              l10n.quranTranslationOfMeaning(s.name),
              style: secondary,
              textAlign: TextAlign.center,
            ),
            Text(
              translationAttribution(context, s),
              style: secondary,
              textAlign: TextAlign.center,
            ),
          ],
          // D-05: ornament medzi hlavickou sury a textom (nie pod textom).
          const Padding(
            padding: EdgeInsetsDirectional.symmetric(vertical: SkSpace.space12),
            child: SkOrnamentDivider(),
          ),
        ],
      ),
    );
  }
}

/// Koniec sury: "Next: Al-Imran" alebo navrat na zoznam po 114.
class _SurahFooter extends StatelessWidget {
  const _SurahFooter({
    required this.surah,
    required this.next,
    required this.mode,
  });

  final SurahInfo surah;
  final SurahInfo? next;
  final ReaderMode mode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final nextSurah = next;
    return Padding(
      padding: const EdgeInsetsDirectional.all(SkSpace.space16),
      child: nextSurah != null
          ? SkButton.secondary(
              label: l10n.quranNextSurah(nextSurah.nameTranslit),
              onPressed: () => context.pushReplacement(
                QuranRoutes.read(nextSurah.id, mode: mode.name),
              ),
            )
          : surah.id == AyahId.surahCount
          ? SkButton.secondary(
              label: l10n.quranBackToSurahs,
              onPressed: () => context.go(QuranRoutes.root),
            )
          : const SizedBox.shrink(),
    );
  }
}
