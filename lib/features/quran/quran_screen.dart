import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/features/quran/quran_format.dart';
import 'package:prosoche/features/quran/quran_providers.dart';
import 'package:prosoche/features/quran/quran_routes.dart';
import 'package:prosoche/features/quran/widgets/quran_states.dart';
import 'package:prosoche/features/quran/widgets/surah_tile.dart';
import 'package:prosoche/ui/i18n/i18n.dart';
import 'package:prosoche/ui/ui.dart';

/// Zalozka Koran: zoznam sur a juz, "Continue" (docs/02 A5.1).
class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

enum _ListTab { surahs, juz }

class _QuranScreenState extends ConsumerState<QuranScreen> {
  _ListTab _tab = _ListTab.surahs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final surahs = ref.watch(surahsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabQuran),
        actions: [
          SkIconButton(
            icon: Icons.search,
            tooltip: l10n.quranSearchTooltip,
            onPressed: () => context.push(QuranRoutes.search),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (surahs) {
          AsyncData(value: final list) when list.isNotEmpty => _body(list),
          AsyncError() || AsyncData() => QuranContentError(
            onRetry: () => ref.invalidate(surahsProvider),
          ),
          _ => const QuranLoading(),
        },
      ),
    );
  }

  Widget _body(List<SurahInfo> surahs) {
    final l10n = context.l10n;
    final byId = {for (final s in surahs) s.id: s};
    final counts = ref.watch(readCountsProvider).value ?? const {};
    final juz = _tab == _ListTab.juz ? ref.watch(juzStartsProvider) : null;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _ContinueBanner(surahs: byId)),
        SliverPadding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: SkSpace.space16,
            vertical: SkSpace.space8,
          ),
          sliver: SliverToBoxAdapter(
            child: SegmentedButton<_ListTab>(
              segments: [
                ButtonSegment(
                  value: _ListTab.surahs,
                  label: Text(l10n.quranTabSurahs),
                ),
                ButtonSegment(
                  value: _ListTab.juz,
                  label: Text(l10n.quranTabJuz),
                ),
              ],
              selected: {_tab},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
        ),
        if (_tab == _ListTab.surahs)
          SliverList.builder(
            itemCount: surahs.length,
            itemBuilder: (context, i) {
              final s = surahs[i];
              return SurahTile(
                surah: s,
                readCount: counts[s.id] ?? 0,
                onTap: () => context.push(
                  QuranRoutes.read(s.id, mode: ReaderMode.browse.name),
                ),
              );
            },
          )
        else
          switch (juz) {
            AsyncData(:final value) => SliverList.builder(
              itemCount: value.length,
              itemBuilder: (context, i) =>
                  _JuzTile(start: value[i], surahs: byId),
            ),
            AsyncError() => SliverToBoxAdapter(
              child: QuranContentError(
                onRetry: () => ref.invalidate(juzStartsProvider),
              ),
            ),
            _ => const SliverToBoxAdapter(child: QuranLoading()),
          },
        const SliverToBoxAdapter(child: SizedBox(height: SkSpace.space24)),
      ],
    );
  }
}

/// "Continue: Al-Baqarah 2:144" (khatm) a "Last opened" (browse).
class _ContinueBanner extends ConsumerWidget {
  const _ContinueBanner({required this.surahs});

  final Map<int, SurahInfo> surahs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(readingPositionProvider);
    if (!position.hasValue) return const SizedBox.shrink();
    final l10n = context.l10n;
    final sk = context.sk;
    final read = position.value;
    final next = read?.next ?? AyahId.first;
    final last = ref.watch(readerLastAyahProvider);

    String reference(AyahId id) =>
        context.ayahReference(surahs[id.surah]?.nameTranslit ?? '', id);

    final continueLabel = read == null
        ? l10n.quranStartReading(reference(next))
        : l10n.quranContinue(reference(next));
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        SkSpace.space16,
        SkSpace.space8,
        SkSpace.space16,
        0,
      ),
      child: Material(
        color: sk.colors.primaryContainer,
        borderRadius: BorderRadius.circular(SkRadius.md),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BannerRow(
              label: continueLabel,
              color: sk.colors.onPrimaryContainer,
              style: sk.text.titleMedium,
              onTap: () => context.push(
                QuranRoutes.read(
                  next.surah,
                  ayahId: next.value,
                  mode: ReaderMode.khatm.name,
                ),
              ),
            ),
            if (last != null && last != next)
              _BannerRow(
                label: l10n.quranLastOpened(reference(last)),
                color: sk.colors.onPrimaryContainer,
                style: sk.text.bodyMedium,
                onTap: () => context.push(
                  QuranRoutes.read(
                    last.surah,
                    ayahId: last.value,
                    mode: ReaderMode.browse.name,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BannerRow extends StatelessWidget {
  const _BannerRow({
    required this.label,
    required this.color,
    required this.onTap,
    this.style,
  });

  final String label;
  final Color color;
  final TextStyle? style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: SkSpace.minTouchTarget),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: SkSpace.space16,
            vertical: SkSpace.space12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: style?.copyWith(color: color)),
              ),
              DirectionalIcon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    ),
  );
}

class _JuzTile extends StatelessWidget {
  const _JuzTile({required this.start, required this.surahs});

  final JuzStart start;
  final Map<int, SurahInfo> surahs;

  @override
  Widget build(BuildContext context) {
    final id = AyahId.tryFromValue(start.firstAyahId) ?? AyahId.first;
    return ListTile(
      minTileHeight: SkSpace.minTouchTarget,
      title: Text(context.l10n.quranJuzTitle(context.quranNumber(start.juz))),
      subtitle: Text(
        context.ayahReference(surahs[id.surah]?.nameTranslit ?? '', id),
      ),
      trailing: const DirectionalIcon(Icons.chevron_right),
      onTap: () => context.push(
        QuranRoutes.read(
          id.surah,
          ayahId: id.value,
          mode: ReaderMode.browse.name,
        ),
      ),
    );
  }
}
