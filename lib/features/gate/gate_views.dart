import 'package:flutter/material.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/blocker/gate_repository.dart' show GateIntent;
import 'package:prosoche/ui/ui.dart';

/// CLDR kategoria radovej cislovky [n] pre jazyk [locale] (`one`, `two`,
/// `few`, `other`) pre ICU `select` v `gateOpenCount`. gen-l10n
/// `selectordinal` nepodporuje. Pravidla ma zatial len EN (appka je len
/// EN); ine jazyky dostanu `other`.
String ordinalCategory(Locale locale, int n) {
  if (locale.languageCode != 'en') return 'other';
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return 'one';
  if (mod10 == 2 && mod100 != 12) return 'two';
  if (mod10 == 3 && mod100 != 13) return 'few';
  return 'other';
}

/// Texty brany s nazvom appky alebo bez neho (appka bez `label`).
extension GateTexts on AppLocalizations {
  String gateTitleFor(String? app) =>
      app == null ? gatePauseTitleGeneric : gatePauseTitle(app);

  String gateSubtitleFor(String? app, int count) =>
      app == null ? gateSubtitleGeneric(count) : gateSubtitle(count, app);

  String gateContinueFor(String? app) =>
      app == null ? gateContinue : gateContinueTo(app);

  String gateEmergencyTitleFor(String? app) =>
      app == null ? gateEmergencyTitleGeneric : gateEmergencyTitle(app);

  String gateEmergencyDialogFor(String? app, int minutes) => app == null
      ? gateEmergencyA11yDialogGeneric(minutes)
      : gateEmergencyA11yDialog(app, minutes);

  String gateUnlockedTitleFor(String? app, int minutes) => app == null
      ? gateUnlockedTitleGeneric(minutes)
      : gateUnlockedTitle(app, minutes);

  String gateUnlockedCloseFor(String? app) =>
      app == null ? gateUnlockedCloseGeneric : gateUnlockedClose(app);

  String gateEmptyFor(String? app) =>
      app == null ? gateEmptyGeneric : gateEmpty(app);

  String gateIntentQuestionFor(String? app) =>
      app == null ? gateIntentQuestionGeneric : gateIntentQuestion(app);

  /// "This is your {n}th time opening {app} today." (G-01).
  String gateOpenCountFor(String? app, int count, Locale locale) {
    final form = ordinalCategory(locale, count);
    return app == null
        ? gateOpenCountGeneric(count, form)
        : gateOpenCount(count, form, app);
  }

  String gatePracticeFirstBodyFor(String? app, String time) => app == null
      ? gatePracticeFirstBodyGeneric(time)
      : gatePracticeFirstBody(app, time);

  String gateIntentLabel(GateIntent intent) => switch (intent) {
    GateIntent.boredom => gateIntentBoredom,
    GateIntent.message => gateIntentMessage,
    GateIntent.work => gateIntentWork,
    GateIntent.habit => gateIntentHabit,
    GateIntent.other => gateIntentOther,
  };
}

/// Hlavicka brany: nazov, kolko kariet, progres (docs/02 A4).
class GateHeader extends StatelessWidget {
  const GateHeader({
    required this.app,
    required this.done,
    required this.total,
    required this.onBack,
    this.freeReading = false,
    this.continueLabel,
    this.onContinue,
    this.note,
    super.key,
  });

  final String? app;

  /// Pocitadlo otvoreni dna a odpor (G-01); null = nic.
  final String? note;
  final int done;
  final int total;
  final VoidCallback onBack;

  /// Aktualna karta je volne citanie (B11).
  final bool freeReading;

  /// Po odomknuti ("Keep reading") tlacidlo "Continue to {app}".
  final String? continueLabel;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final unlocked = onContinue != null;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        SkSpace.space16,
        SkSpace.space8,
        SkSpace.space8,
        SkSpace.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // D-01: brana = oblúk; prechadzas nim k appke. Pri velkom
              // texte sa vynecha (miesto patri karte).
              if (!sk.largeText) ...[
                const SkArch(size: 28, keystone: false),
                const SizedBox(width: SkSpace.space12),
              ],
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.gateTitleFor(app),
                    style: sk.text.headlineSmall,
                  ),
                ),
              ),
              if (!unlocked)
                SkButton.tertiary(label: l10n.gateBack, onPressed: onBack),
            ],
          ),
          if (unlocked)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SkButton.tertiary(
                label: continueLabel ?? l10n.gateContinueFor(app),
                onPressed: onContinue,
              ),
            ),
          if (!unlocked) ...[
            Text(
              l10n.gateSubtitleFor(app, total),
              style: sk.text.bodyMedium!.copyWith(
                color: sk.colors.textSecondary,
              ),
            ),
            const SizedBox(height: SkSpace.space8),
            Semantics(
              label: l10n.gateProgress(done.clamp(0, total), total),
              child: ExcludeSemantics(
                child: SkDailyProgress(
                  done: done.clamp(0, total),
                  total: total,
                  variant: SkDailyProgressVariant.gate,
                ),
              ),
            ),
            // Pri velkom texte sa nevojde (miesto patri karte); pocitadlo
            // ostava na obrazovke zameru.
            if (note != null && !sk.largeText) ...[
              const SizedBox(height: SkSpace.space8),
              Text(
                note!,
                key: const ValueKey('gate:opens'),
                style: sk.text.bodySmall!.copyWith(
                  color: sk.colors.textSecondary,
                ),
              ),
            ],
          ],
          if (freeReading) ...[
            const SizedBox(height: SkSpace.space8),
            Text(
              l10n.gateFreeReadingNote,
              style: sk.text.bodySmall!.copyWith(
                color: sk.colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Spodna lista: odpocet karty, "Next" a emergency.
class GateFooter extends StatelessWidget {
  const GateFooter({
    required this.secondsLeft,
    required this.onNext,
    required this.onEmergency,
    required this.onEmergencyA11y,
    super.key,
  });

  /// 0 = karta je prejdena.
  final int secondsLeft;

  /// null = dalsia karta este nie je dostupna.
  final VoidCallback? onNext;

  /// null = emergency sa nezobrazi (po odomknuti).
  final VoidCallback? onEmergency;
  final VoidCallback? onEmergencyA11y;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        SkSpace.space16,
        SkSpace.space8,
        SkSpace.space16,
        SkSpace.space16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: SkSpace.minTouchTarget,
            child: Center(
              child: secondsLeft > 0
                  ? Semantics(
                      liveRegion: true,
                      label: l10n.gateDwellA11y(secondsLeft),
                      child: ExcludeSemantics(
                        child: Text(
                          l10n.gateDwellLeft(secondsLeft),
                          style: sk.text.titleMedium!.copyWith(
                            color: sk.colors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : SkButton.primary(
                      label: l10n.gateNext,
                      onPressed: onNext,
                      icon: Icons.arrow_downward,
                    ),
            ),
          ),
          if (onEmergency != null) ...[
            const SizedBox(height: SkSpace.space8),
            Center(
              child: SkHoldToConfirmButton(
                label: l10n.gateEmergency,
                icon: Icons.lock_open,
                onConfirmed: onEmergency!,
                onAccessibleConfirm: onEmergencyA11y ?? onEmergency!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Spolocny layout stavovych obrazoviek brany (odomknute, chyba).
class _GateMessage extends StatelessWidget {
  const _GateMessage({
    required this.title,
    required this.actions,
    this.body,
    this.extra,
    this.icon,
    this.eyebrow,
  });

  /// Maly text nad titulkom (pocitadlo otvoreni, G-01).
  final String? eyebrow;
  final String title;
  final String? body;
  final String? extra;
  final IconData? icon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(SkSpace.space24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight.isFinite
                ? constraints.maxHeight - 2 * SkSpace.space24
                : 0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 40, color: sk.colors.primary),
                const SizedBox(height: SkSpace.space16),
              ],
              if (eyebrow != null) ...[
                Text(
                  eyebrow!,
                  key: const ValueKey('gate:opens'),
                  textAlign: TextAlign.center,
                  style: sk.text.bodyMedium!.copyWith(
                    color: sk.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: SkSpace.space12),
              ],
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: sk.text.headlineSmall,
                ),
              ),
              if (body != null) ...[
                const SizedBox(height: SkSpace.space8),
                Text(
                  body!,
                  textAlign: TextAlign.center,
                  style: sk.text.bodyLarge!.copyWith(
                    color: sk.colors.textSecondary,
                  ),
                ),
              ],
              if (extra != null) ...[
                const SizedBox(height: SkSpace.space8),
                Text(
                  extra!,
                  textAlign: TextAlign.center,
                  style: sk.text.bodyMedium!.copyWith(
                    color: sk.colors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: SkSpace.space24),
              for (final (i, a) in actions.indexed) ...[
                if (i > 0) const SizedBox(height: SkSpace.space8),
                a,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "{app} is open for {minutes} minutes" (docs/01 5.3, 7.4).
class GateUnlockedView extends StatelessWidget {
  const GateUnlockedView({
    required this.app,
    required this.minutes,
    required this.onContinue,
    required this.onClose,
    required this.onKeepReading,
    this.setFinished = false,
    super.key,
  });

  final String? app;
  final int minutes;
  final VoidCallback onContinue;
  final VoidCallback onClose;
  final VoidCallback onKeepReading;
  final bool setFinished;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _GateMessage(
      icon: Icons.check_circle_outline,
      title: l10n.gateUnlockedTitleFor(app, minutes),
      body: l10n.gateUnlockedBody,
      extra: setFinished ? l10n.gateSetFinished : null,
      actions: [
        SkButton.primary(
          label: l10n.gateContinueFor(app),
          onPressed: onContinue,
          expand: true,
        ),
        SkButton.secondary(
          label: l10n.gateUnlockedCloseFor(app),
          onPressed: onClose,
          expand: true,
        ),
        SkButton.tertiary(
          label: l10n.gateKeepReading,
          onPressed: onKeepReading,
          expand: true,
        ),
      ],
    );
  }
}

/// Chyba alebo timeout: "Continue to {app}" a "Go back" (docs/01 D5).
class GateErrorView extends StatelessWidget {
  const GateErrorView({
    required this.app,
    required this.onContinue,
    required this.onBack,
    super.key,
  });

  final String? app;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _GateMessage(
      icon: Icons.cloud_off_outlined,
      title: l10n.gateErrorTitle,
      body: l10n.gateErrorBody,
      actions: [
        SkButton.primary(
          label: l10n.gateContinueFor(app),
          onPressed: onContinue,
          expand: true,
        ),
        SkButton.secondary(
          label: l10n.gateBack,
          onPressed: onBack,
          expand: true,
        ),
      ],
    );
  }
}

/// Nic na zobrazenie: appka sa otvori.
class GateEmptyView extends StatelessWidget {
  const GateEmptyView({required this.app, required this.onContinue, super.key});

  final String? app;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _GateMessage(
      title: l10n.gateEmptyFor(app),
      actions: [
        SkButton.primary(
          label: l10n.gateContinueFor(app),
          onPressed: onContinue,
          expand: true,
        ),
      ],
    );
  }
}

/// Emergency odpocet 10 s s "Cancel" (docs/01 D4).
class GateEmergencyView extends StatelessWidget {
  const GateEmergencyView({
    required this.app,
    required this.secondsLeft,
    required this.onCancel,
    super.key,
  });

  final String? app;
  final int secondsLeft;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _GateMessage(
      icon: Icons.timer_outlined,
      title: l10n.gateEmergencyTitleFor(app),
      body: l10n.gateEmergencyBody(secondsLeft),
      actions: [
        SkButton.primary(
          label: l10n.gateEmergencyCancel,
          onPressed: onCancel,
          expand: true,
        ),
      ],
    );
  }
}

/// Nacitavanie: pokojna plocha ako nativny splash, po 1 s "Still loading…".
class GateLoadingView extends StatelessWidget {
  const GateLoadingView({this.slow = false, super.key});

  final bool slow;

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: sk.colors.primary,
              semanticsLabel: SkUiStrings.of(context).loading,
            ),
          ),
          if (slow) ...[
            const SizedBox(height: SkSpace.space16),
            Semantics(
              liveRegion: true,
              child: Text(
                context.l10n.gateLoadingSlow,
                style: sk.text.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Emergency podrzanim (G-01: aj pri otazke zameru a rannom zamku).
class GateEmergencyButton extends StatelessWidget {
  const GateEmergencyButton({
    required this.onEmergency,
    required this.onEmergencyA11y,
    super.key,
  });

  final VoidCallback onEmergency;
  final VoidCallback onEmergencyA11y;

  @override
  Widget build(BuildContext context) => Center(
    child: SkHoldToConfirmButton(
      label: context.l10n.gateEmergency,
      icon: Icons.lock_open,
      onConfirmed: onEmergency,
      onAccessibleConfirm: onEmergencyA11y,
    ),
  );
}

/// "Why are you opening {app}?" (G-01): jeden tuk na cip alebo "Skip",
/// ziadny volny text. Odpoved ostava v telefone.
class GateIntentView extends StatelessWidget {
  const GateIntentView({
    required this.app,
    required this.onChoose,
    required this.onEmergency,
    required this.onEmergencyA11y,
    this.opensNote,
    super.key,
  });

  final String? app;

  /// Pocitadlo otvoreni dna (null = vypnute).
  final String? opensNote;

  /// Volba; null = "Skip".
  final ValueChanged<GateIntent?> onChoose;
  final VoidCallback onEmergency;
  final VoidCallback onEmergencyA11y;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    return _GateMessage(
      title: l10n.gateIntentQuestionFor(app),
      body: l10n.gateIntentNote,
      eyebrow: opensNote,
      actions: [
        Semantics(
          container: true,
          label: l10n.gateIntentChoicesA11y,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: SkSpace.space8,
            runSpacing: SkSpace.space8,
            children: [
              for (final intent in GateIntent.values)
                ActionChip(
                  key: ValueKey('gate:intent:${intent.wire}'),
                  label: Text(l10n.gateIntentLabel(intent)),
                  labelStyle: sk.text.labelLarge,
                  onPressed: () => onChoose(intent),
                ),
            ],
          ),
        ),
        SkButton.tertiary(
          key: const ValueKey('gate:intent:skip'),
          label: l10n.gateIntentSkip,
          onPressed: () => onChoose(null),
          expand: true,
        ),
        const SizedBox(height: SkSpace.space8),
        GateEmergencyButton(
          onEmergency: onEmergency,
          onEmergencyA11y: onEmergencyA11y,
        ),
      ],
    );
  }
}

/// Ranny zamok "Practice first" (G-01): namiesto kariet ponuka rannej
/// pripravy v Practice, "Go back" a emergency.
class GatePracticeFirstView extends StatelessWidget {
  const GatePracticeFirstView({
    required this.app,
    required this.until,
    required this.onStart,
    required this.onBack,
    required this.onEmergency,
    required this.onEmergencyA11y,
    super.key,
  });

  final String? app;

  /// Koniec zamku (lokalny cas).
  final TimeOfDay until;
  final VoidCallback onStart;
  final VoidCallback onBack;
  final VoidCallback onEmergency;
  final VoidCallback onEmergencyA11y;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      until,
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return _GateMessage(
      icon: Icons.wb_twilight,
      title: l10n.gatePracticeFirstTitle,
      body: l10n.gatePracticeFirstBodyFor(app, time),
      extra: l10n.gatePracticeFirstWhy,
      actions: [
        SkButton.primary(
          key: const ValueKey('gate:practice:start'),
          label: l10n.gatePracticeFirstStart,
          onPressed: onStart,
          expand: true,
        ),
        SkButton.secondary(
          label: l10n.gateBack,
          onPressed: onBack,
          expand: true,
        ),
        const SizedBox(height: SkSpace.space8),
        GateEmergencyButton(
          onEmergency: onEmergency,
          onEmergencyA11y: onEmergencyA11y,
        ),
      ],
    );
  }
}
