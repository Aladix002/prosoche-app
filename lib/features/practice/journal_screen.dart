import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/db/user_enums.dart' show JournalKind;
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/features/cards/card_parts.dart';
import 'package:prosoche/features/cards/card_share.dart';
import 'package:prosoche/features/practice/widgets/journal_widgets.dart';
import 'package:prosoche/ui/ui.dart';

/// Lokalny dennik (F-01): zaznamy rannej pripravy, vecernej reflexie
/// a poznamky. Nikdy neopusti zariadenie; export len pouzivatelom cez
/// share sheet, zmazanie tu alebo v "Delete all my data".
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final text = await showTextInputDialog(
      context,
      title: l10n.journalNewNote,
      saveLabel: l10n.journalSave,
      fieldKey: const ValueKey('journal:noteField'),
      saveKey: const ValueKey('journal:noteSave'),
    );
    if (text == null || text.trim().isEmpty) return;
    await ref
        .read(practiceRepositoryProvider)
        .addNote(ref.read(localDateProvider), text);
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final text = await ref
        .read(practiceRepositoryProvider)
        .exportJournal(title: l10n.journalExportTitle(l10n.appTitle));
    await ref.read(cardSharerProvider).shareText(text);
  }

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.journalDeleteAllTitle),
        content: Text(l10n.journalDeleteAllBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(SkUiStrings.of(context).cancel),
          ),
          TextButton(
            key: const ValueKey('journal:deleteConfirm'),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.journalDelete),
          ),
        ],
      ),
    );
    if (ok ?? false) await ref.read(practiceRepositoryProvider).deleteJournal();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final journal = ref.watch(journalProvider);
    final entries = journal.value ?? const <JournalEntry>[];
    final Widget body;
    if (journal.hasError && !journal.isLoading) {
      body = SkErrorState(
        title: l10n.errorGeneric,
        onRetry: () => ref.invalidate(journalProvider),
      );
    } else if (!journal.hasValue) {
      body = const SkLoadingView(skeleton: SkSkeleton.list());
    } else if (entries.isEmpty) {
      body = SkEmptyState(
        icon: Icons.edit_note,
        title: l10n.journalEmptyTitle,
        body: l10n.journalEmptyBody,
      );
    } else {
      final rows = <Widget>[];
      Object? day;
      for (final e in entries) {
        if (e.date != day) {
          day = e.date;
          rows.add(
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                SkSpace.space16,
                SkSpace.space16,
                SkSpace.space16,
                SkSpace.space4,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  context.longDateLabel(e.date),
                  style: sk.text.titleSmall!.copyWith(
                    color: sk.colors.accentText,
                  ),
                ),
              ),
            ),
          );
        }
        rows.add(_EntryTile(entry: e));
      }
      body = ListView(key: const ValueKey('journal:list'), children: rows);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.journalTitle),
        actions: [
          SkIconButton(
            key: const ValueKey('journal:export'),
            icon: Icons.ios_share,
            tooltip: l10n.journalExport,
            onPressed: entries.isEmpty
                ? null
                : () => unawaited(_export(context, ref)),
          ),
          SkIconButton(
            key: const ValueKey('journal:deleteAll'),
            icon: Icons.delete_outline,
            tooltip: l10n.journalDeleteAllTitle,
            onPressed: entries.isEmpty
                ? null
                : () => unawaited(_deleteAll(context, ref)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('journal:add'),
        onPressed: () => unawaited(_addNote(context, ref)),
        icon: const Icon(Icons.add),
        label: Text(l10n.journalNewNote),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                SkSpace.space16,
                SkSpace.space8,
                SkSpace.space16,
                0,
              ),
              child: JournalPrivacyNote(),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends ConsumerWidget {
  const _EntryTile({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sk = context.sk;
    final kind = switch (entry.kind) {
      JournalKind.morning => l10n.practiceMorning,
      JournalKind.evening => l10n.practiceEvening,
      JournalKind.note => l10n.journalNote,
    };
    return ListTile(
      key: ValueKey('entry:${entry.id}'),
      title: Text(
        entry.prompt ?? kind,
        style: sk.text.titleSmall!.copyWith(
          fontStyle: entry.prompt == null ? null : FontStyle.italic,
        ),
      ),
      subtitle: Text(entry.body, style: sk.text.bodyLarge),
      trailing: SkIconButton(
        icon: Icons.delete_outline,
        tooltip: l10n.journalDelete,
        onPressed: () => unawaited(
          ref.read(practiceRepositoryProvider).deleteEntry(entry.id),
        ),
      ),
    );
  }
}
