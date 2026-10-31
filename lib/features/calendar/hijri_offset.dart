import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/calendar/calendar.dart';
import 'package:sakina/domain/settings/settings_repository.dart';
import 'package:sakina/features/calendar/calendar_providers.dart';
import 'package:sakina/features/prayer/prayer_texts.dart';
import 'package:sakina/ui/ui.dart';

/// Hijri offset -2..+2 s nahladom dnesneho datumu (docs/02 A10.8).
///
/// Zmena sa ulozi hned do `hijri.offset`; kalendar a Dnes sa prepocitaju
/// (providery sleduju kluc). Dnesna sada a questy sa nemenia (A10.8).
class HijriOffsetEditor extends ConsumerWidget {
  const HijriOffsetEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final offset = ref.watch(hijriOffsetProvider).value ?? 0;
    final today = ref.watch(localDateProvider);
    final preview = IslamicCalendar(offset: offset).hijriOf(today);
    final value = context.hijriOffsetLabel(offset);

    Future<void> set(int v) =>
        ref.read(settingsRepositoryProvider).set(SettingsKeys.hijriOffset, v);

    final canDown = offset > IslamicCalendar.minOffset;
    final canUp = offset < IslamicCalendar.maxOffset;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.calendarOffsetHelp, style: sk.text.bodyMedium),
        const SizedBox(height: SkSpace.space16),
        Semantics(
          container: true,
          label: l10n.calendarOffsetTitle,
          value: value,
          increasedValue: canUp ? context.hijriOffsetLabel(offset + 1) : null,
          decreasedValue: canDown ? context.hijriOffsetLabel(offset - 1) : null,
          onIncrease: canUp ? () => unawaited(set(offset + 1)) : null,
          onDecrease: canDown ? () => unawaited(set(offset - 1)) : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SkIconButton(
                icon: Icons.remove,
                tooltip: l10n.calendarOffsetEarlier,
                onPressed: canDown ? () => unawaited(set(offset - 1)) : null,
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 96),
                child: ExcludeSemantics(
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: sk.text.titleMedium,
                  ),
                ),
              ),
              SkIconButton(
                icon: Icons.add,
                tooltip: l10n.calendarOffsetLater,
                onPressed: canUp ? () => unawaited(set(offset + 1)) : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: SkSpace.space8),
        Semantics(
          liveRegion: true,
          child: Text(
            l10n.calendarOffsetPreview(context.hijriDateLabel(preview)),
            textAlign: TextAlign.center,
            style: sk.text.bodyLarge!.copyWith(color: sk.colors.accentText),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet s [HijriOffsetEditor] (z kalendara A9).
Future<void> showHijriOffsetSheet(BuildContext context) => showSkInfoSheet(
  context,
  title: context.l10n.calendarOffsetTitle,
  closeLabel: MaterialLocalizations.of(context).closeButtonTooltip,
  child: const HijriOffsetEditor(),
);

/// Nastavenie hijri kalendara (docs/02 A10.8). Route `/settings/calendar`
/// patri F-07 (`settings_routes.dart`), obrazovku dodava F-05.
class HijriOffsetScreen extends StatelessWidget {
  const HijriOffsetScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: skAppBar(context, title: context.l10n.calendarOffsetTitle),
    body: ListView(
      padding: EdgeInsetsDirectional.all(
        SkSpace.gutterFor(MediaQuery.sizeOf(context).width),
      ),
      children: const [HijriOffsetEditor()],
    ),
  );
}
