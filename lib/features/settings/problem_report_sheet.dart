import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/core/l10n/l10n.dart';
import 'package:sakina/core/logging/logger_provider.dart';
import 'package:sakina/data/observability/observability_providers.dart';
import 'package:sakina/ui/i18n/i18n.dart';
import 'package:sakina/ui/ui.dart';

/// "Report a problem" (docs/06 C.9, D-04 `ProblemReport`): pouzivatel
/// vidi presny text reportu a posle ho sam ako `.txt` cez systemovy share
/// sheet (napr. e-mailom). Appka nic neodosiela.
///
/// [subject] je technicka referencia, napr. karta `hadith:42` a jej
/// zbierka a cislo. Nikdy nie text Koranu, hadisu ani modlitby.
///
/// Vrati true, ked sa otvoril share sheet s reportom.
Future<bool> showProblemReportSheet(
  BuildContext context, {
  String? subject,
}) async {
  final shared = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ProblemReportSheet(subject: subject),
  );
  return shared ?? false;
}

class ProblemReportSheet extends ConsumerStatefulWidget {
  const ProblemReportSheet({this.subject, super.key});

  final String? subject;

  @override
  ConsumerState<ProblemReportSheet> createState() => _ProblemReportSheetState();
}

class _ProblemReportSheetState extends ConsumerState<ProblemReportSheet> {
  final _description = TextEditingController();
  bool _includeLog = true;
  bool _sharing = false;
  bool _failed = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  /// Popis do reportu: referencia (karta) a text pouzivatela.
  String get _text => [
    ?widget.subject,
    if (_description.text.trim() case final t when t.isNotEmpty) t,
  ].join('\n');

  Future<void> _share() async {
    setState(() {
      _sharing = true;
      _failed = false;
    });
    final report = ref.read(problemReportProvider);
    try {
      await report.share(
        description: _text,
        includeLog: _includeLog,
        subject: context.l10n.reportShareSubject(context.l10n.appTitle),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e, st) {
      ref
          .read(appLoggerProvider)
          .error('report', 'share failed', error: e, stack: st);
      if (mounted) {
        setState(() {
          _sharing = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    final report = ref.watch(problemReportProvider);
    return SkSheet(
      title: l10n.cardSheetReport,
      closeLabel: SkUiStrings.of(context).cancel,
      actions: [
        SkButton.primary(
          key: const ValueKey('report:share'),
          label: l10n.reportShare,
          icon: Icons.ios_share,
          loading: _sharing,
          expand: true,
          onPressed: _sharing ? null : () => unawaited(_share()),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.reportBody),
          const SizedBox(height: SkSpace.space16),
          TextField(
            key: const ValueKey('report:description'),
            controller: _description,
            minLines: 2,
            maxLines: 5,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.reportDescriptionLabel,
              alignLabelWithHint: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          CheckboxListTile(
            key: const ValueKey('report:log'),
            contentPadding: EdgeInsetsDirectional.zero,
            value: _includeLog,
            title: Text(l10n.reportIncludeLog),
            subtitle: Text(l10n.reportIncludeLogHelp),
            onChanged: (v) => setState(() => _includeLog = v ?? true),
          ),
          if (_failed)
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.reportShareFailed,
                style: sk.text.bodyMedium!.copyWith(color: sk.colors.error),
              ),
            ),
          ExpansionTile(
            key: const ValueKey('report:preview'),
            tilePadding: EdgeInsetsDirectional.zero,
            title: Text(l10n.reportPreview),
            children: [
              Container(
                constraints: const BoxConstraints(maxHeight: 240),
                padding: const EdgeInsetsDirectional.all(SkSpace.space8),
                color: sk.colors.surfaceAlt,
                child: SingleChildScrollView(
                  child: SelectableText(
                    report.preview(description: _text, includeLog: _includeLog),
                    // Technicky report je anglicky (hlavicka, log).
                    textDirection: textDirectionForLanguage('en'),
                    style: sk.text.bodySmall!.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
