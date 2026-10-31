import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/features/quran/quran_format.dart';
import 'package:prosoche/features/quran/quran_providers.dart';
import 'package:prosoche/features/quran/quran_routes.dart';
import 'package:prosoche/features/quran/widgets/ayah_tile.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// Vyhladavanie v Korane (docs/02 A5.4): referencia `2:255`, nazov sury,
/// fulltext v preklade alebo v arabcine. Nic sa neuklada (sukromie).
class QuranSearchScreen extends ConsumerStatefulWidget {
  const QuranSearchScreen({
    this.initialQuery = '',
    this.debounce = defaultDebounce,
    super.key,
  });

  static const defaultDebounce = Duration(milliseconds: 300);
  static const minLength = 2;

  final String initialQuery;
  final Duration debounce;

  @override
  ConsumerState<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends ConsumerState<QuranSearchScreen> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  late String _query = widget.initialQuery.trim();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () => _apply(text));
    setState(() {}); // tlacidlo Clear
  }

  void _apply(String text) {
    _debounce?.cancel();
    final q = QuranRoutes.parseQuery(text).trim();
    if (q != _query && mounted) setState(() => _query = q);
  }

  void _clear() {
    _controller.clear();
    _apply('');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Pole je v tele (nie v AppBar), aby sa hint pri 200 % zalomil.
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: SkSpace.space16,
              ),
              child: TextField(
                controller: _controller,
                autofocus: widget.initialQuery.isEmpty,
                maxLength: QuranRoutes.maxQueryLength,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.quranSearchHint,
                  hintMaxLines: 3,
                  counterText: '',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : SkIconButton(
                          icon: Icons.close,
                          tooltip: l10n.quranClearSearch,
                          onPressed: _clear,
                        ),
                ),
                onChanged: _onChanged,
                onSubmitted: _apply,
              ),
            ),
            Expanded(child: _results()),
          ],
        ),
      ),
    );
  }

  Widget _results() {
    final l10n = context.l10n;
    final sk = context.sk;
    if (_query.length < QuranSearchScreen.minLength) {
      return Padding(
        padding: const EdgeInsetsDirectional.all(SkSpace.space24),
        child: Text(
          l10n.quranSearchTips,
          style: sk.text.bodyLarge!.copyWith(color: sk.colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }
    final result = ref.watch(quranSearchProvider(_query));
    return switch (result) {
      AsyncData(:final value) when value.isEmpty => SingleChildScrollView(
        child: SkEmptyState(
          title: l10n.quranSearchEmptyTitle(_query),
          body: l10n.quranSearchEmptyBody,
        ),
      ),
      AsyncData(:final value) => _ResultList(
        result: value,
        arabicQuery: hasArabic(_query),
      ),
      AsyncError() => SingleChildScrollView(
        child: SkErrorState(
          title: l10n.quranSearchErrorTitle,
          body: l10n.quranSearchErrorBody,
          onRetry: () => ref.invalidate(quranSearchProvider(_query)),
        ),
      ),
      _ => const Padding(
        padding: EdgeInsetsDirectional.all(SkSpace.space24),
        child: SkLoadingView(
          skeleton: Center(child: CircularProgressIndicator()),
        ),
      ),
    };
  }
}

/// Rovnaka detekcia ako `DriftQuranRepository.search` (arabsky FTS).
/// Regex (nie zobrazovany text), preto ignore.
bool hasArabic(String s) =>
    // prosoche-lint: ignore prosoche_arabic_text_outside_sk_arabic_text
    RegExp('[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(s);

class _ResultList extends ConsumerWidget {
  const _ResultList({required this.result, required this.arabicQuery});

  final QuranSearchResult result;
  final bool arabicQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final names = {
      for (final s in ref.watch(surahsProvider).value ?? const <SurahInfo>[])
        s.id: s.nameTranslit,
    };
    final lang = ref.watch(contentLanguageProvider).value ?? 'en';
    final reference = result.reference;
    void open(AyahId id) => context.push(
      QuranRoutes.read(
        id.surah,
        ayahId: id.value,
        mode: ReaderMode.browse.name,
      ),
    );

    final children = <Widget>[
      if (reference != null)
        ListTile(
          minTileHeight: SkSpace.minTouchTarget,
          leading: const DirectionalIcon(Icons.arrow_forward),
          title: Text(
            l10n.quranGoTo(
              context.ayahReference(names[reference.surah] ?? '', reference),
            ),
          ),
          onTap: () => open(reference),
        ),
      for (final s in result.surahs)
        ListTile(
          minTileHeight: SkSpace.minTouchTarget,
          leading: Text(
            context.quranNumber(s.id),
            style: sk.text.titleMedium!.copyWith(color: sk.colors.accentText),
          ),
          title: Text(s.nameTranslit),
          subtitle: s.nameMeaning == null ? null : Text(s.nameMeaning!),
          trailing: const DirectionalIcon(Icons.chevron_right),
          onTap: () => context.push(
            QuranRoutes.read(s.id, mode: ReaderMode.browse.name),
          ),
        ),
      if (result.hits.isNotEmpty)
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            SkSpace.space16,
            SkSpace.space16,
            SkSpace.space16,
            SkSpace.space4,
          ),
          child: Semantics(
            header: true,
            child: Text(l10n.quranSearchVerses, style: sk.text.titleSmall),
          ),
        ),
    ];
    final hits = result.hits;
    return ListView.builder(
      itemCount: children.length + hits.length,
      itemBuilder: (context, i) {
        if (i < children.length) return children[i];
        final hit = hits[i - children.length];
        final id = AyahId.tryFromValue(hit.ayahId);
        if (id == null) return const SizedBox.shrink();
        return _HitTile(
          hit: hit,
          reference: context.ayahReference(names[id.surah] ?? '', id),
          arabic: arabicQuery,
          lang: lang,
          onTap: () => open(id),
        );
      },
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({
    required this.hit,
    required this.reference,
    required this.arabic,
    required this.lang,
    required this.onTap,
  });

  final SearchHit hit;
  final String reference;
  final bool arabic;
  final String lang;
  final VoidCallback onTap;

  /// Snippet rozdeleny na (text, je zhoda).
  List<(String, bool)> get _parts {
    final out = <(String, bool)>[];
    final re = RegExp(
      '${SearchHit.matchStart}(.*?)${SearchHit.matchEnd}',
      dotAll: true,
    );
    var last = 0;
    for (final m in re.allMatches(hit.snippet)) {
      if (m.start > last) {
        out.add((hit.snippet.substring(last, m.start), false));
      }
      out.add((m[1]!, true));
      last = m.end;
    }
    if (last < hit.snippet.length) {
      out.add((hit.snippet.substring(last), false));
    }
    return [
      for (final p in out)
        if (p.$1.isNotEmpty) p,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    final parts = _parts;
    final plain = parts.map((p) => p.$1).join();
    final Widget snippet;
    if (arabic) {
      final first = parts.indexWhere((p) => p.$2);
      snippet = SkArabicText.quran(
        [for (final p in parts) SkArabicSegment(p.$1)],
        textSimple: plain,
        style: SkQuranStyle.reader,
        textAlign: TextAlign.start,
        selectedSegment: first < 0 ? null : first,
      );
    } else {
      final base = translationStyle(sk.text.bodyLarge!, lang);
      snippet = Directionality(
        textDirection: textDirectionForLanguage(lang),
        child: Text.rich(
          TextSpan(
            children: [
              for (final (text, match) in parts)
                TextSpan(
                  text: text,
                  style: match
                      ? TextStyle(
                          fontWeight: FontWeight.w600,
                          backgroundColor: sk.colors.primaryContainer,
                        )
                      : null,
                ),
            ],
          ),
          style: base,
          locale: Locale(lang),
        ),
      );
    }
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: SkSpace.space16,
            vertical: SkSpace.space8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                reference,
                style: sk.text.bodySmall!.copyWith(
                  color: sk.colors.textSecondary,
                ),
              ),
              snippet,
            ],
          ),
        ),
      ),
    );
  }
}
