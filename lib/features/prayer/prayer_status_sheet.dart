import 'package:flutter/material.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/data/repositories/repositories.dart';
import 'package:sakina/domain/prayer/prayer.dart';
import 'package:sakina/features/prayer/prayer_texts.dart';
import 'package:sakina/features/prayer/prayer_view.dart';
import 'package:sakina/ui/ui.dart';

/// Volba v sheete trackera; [status] null = "Clear".
@immutable
final class PrayerStatusChoice {
  const PrayerStatusChoice(this.status);

  final PrayerStatus? status;
}

/// Long press na riadok modlitby (A7.1): On time, Late, Missed, Made up,
/// Clear. Buducu modlitbu sheet len vysvetli ([canLog] false).
Future<PrayerStatusChoice?> showPrayerStatusSheet(
  BuildContext context, {
  required Prayer prayer,
  required PrayerStatus? current,
  required bool canLog,
}) {
  final l10n = context.l10n;
  final options = [
    (PrayerStatus.onTime, l10n.prayerMarkOnTime),
    (PrayerStatus.late, l10n.prayerMarkLate),
    (PrayerStatus.missed, l10n.prayerMarkMissed),
    (PrayerStatus.qada, l10n.prayerMarkQada),
  ];
  return showModalBottomSheet<PrayerStatusChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SkSheet(
      title: context.prayerName(prayer),
      closeLabel: MaterialLocalizations.of(context).closeButtonTooltip,
      child: canLog
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (status, label) in options)
                  ListTile(
                    leading: SkPrayerTracker(status: skStatus(status)),
                    title: Text(label),
                    selected: current == status,
                    trailing: current == status
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () =>
                        Navigator.of(context).pop(PrayerStatusChoice(status)),
                  ),
                if (current != null)
                  ListTile(
                    leading: const SizedBox.square(
                      dimension: SkSpace.minTouchTarget,
                      child: Icon(Icons.close),
                    ),
                    title: Text(l10n.prayerClearLog),
                    onTap: () =>
                        Navigator.of(context)
                            .pop(const PrayerStatusChoice(null)),
                  ),
              ],
            )
          : Text(l10n.prayerFutureHint),
    ),
  );
}
