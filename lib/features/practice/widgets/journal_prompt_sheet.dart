import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/data/repositories/repositories.dart';
import 'package:prosoche/domain/common/common.dart';
import 'package:prosoche/features/practice/widgets/journal_widgets.dart';
import 'package:prosoche/ui/ui.dart';

/// Zapis odpovede na otazku (karta `prompt`) do lokalneho dennika.
/// Vrati true, ak sa nieco ulozilo.
Future<bool> showJournalPromptSheet(
  BuildContext context, {
  required LocalDate date,
  required String promptId,
  required String prompt,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) =>
        _PromptSheet(date: date, promptId: promptId, prompt: prompt),
  );
  return saved ?? false;
}

class _PromptSheet extends ConsumerStatefulWidget {
  const _PromptSheet({
    required this.date,
    required this.promptId,
    required this.prompt,
  });

  final LocalDate date;
  final String promptId;
  final String prompt;

  @override
  ConsumerState<_PromptSheet> createState() => _PromptSheetState();
}

class _PromptSheetState extends ConsumerState<_PromptSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      await ref
          .read(practiceRepositoryProvider)
          .addNote(
            widget.date,
            text,
            promptId: widget.promptId,
            prompt: widget.prompt,
          );
    }
    if (mounted) Navigator.of(context).pop(text.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sk = context.sk;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: SkSpace.space16,
        end: SkSpace.space16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + SkSpace.space16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.prompt,
            style: sk.type.reflection.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: SkSpace.space16),
          TextField(
            key: const ValueKey('prompt:field'),
            controller: _controller,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.journalYourAnswer,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: SkSpace.space8),
          const JournalPrivacyNote(),
          const SizedBox(height: SkSpace.space16),
          SkButton.primary(
            key: const ValueKey('prompt:save'),
            label: l10n.journalSave,
            onPressed: _save,
            expand: true,
          ),
        ],
      ),
    );
  }
}
