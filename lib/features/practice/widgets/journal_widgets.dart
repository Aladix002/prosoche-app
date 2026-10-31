import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prosoche/core/l10n/l10n.dart';
import 'package:prosoche/ui/ui.dart';

/// Poznamka o sukromi dennika (zamok + text).
class JournalPrivacyNote extends StatelessWidget {
  const JournalPrivacyNote({super.key});

  @override
  Widget build(BuildContext context) {
    final sk = context.sk;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.lock_outline,
            size: 18,
            color: sk.colors.textSecondary,
          ),
        ),
        const SizedBox(width: SkSpace.space8),
        Expanded(
          child: Text(
            context.l10n.journalPrivacyNote,
            style: sk.text.bodySmall!.copyWith(color: sk.colors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Pole dennika s otazkou ako labelom. Uklada sa po pauze v pisani
/// a pri opusteni pola ([onSave]); text nikdy neopusti zariadenie.
class JournalField extends StatefulWidget {
  const JournalField({
    required this.label,
    required this.onSave,
    this.initial = '',
    this.minLines = 3,
    super.key,
  });

  static const saveDelay = Duration(milliseconds: 800);

  final String label;
  final String initial;
  final int minLines;
  final Future<void> Function(String text) onSave;

  @override
  State<JournalField> createState() => _JournalFieldState();
}

class _JournalFieldState extends State<JournalField> {
  late final _controller = TextEditingController(text: widget.initial);
  final _focus = FocusNode();
  Timer? _timer;
  String _saved = '';

  @override
  void initState() {
    super.initState();
    _saved = widget.initial;
    _focus.addListener(() {
      if (!_focus.hasFocus) _flush();
    });
  }

  @override
  void didUpdateWidget(JournalField old) {
    super.didUpdateWidget(old);
    if (widget.initial != old.initial &&
        _controller.text == old.initial &&
        !_focus.hasFocus) {
      _controller.text = widget.initial;
      _saved = widget.initial;
    }
  }

  @override
  void dispose() {
    _flush();
    _timer?.cancel();
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _flush() {
    _timer?.cancel();
    final text = _controller.text;
    if (text == _saved) return;
    _saved = text;
    unawaited(widget.onSave(text));
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _focus,
    skipTraversal: true,
    // D-01 pole dennika (otazka nad polom), ulozenie po pauze.
    child: SkJournalField(
      controller: _controller,
      label: widget.label,
      minLines: widget.minLines,
      onChanged: (_) {
        _timer?.cancel();
        _timer = Timer(JournalField.saveDelay, _flush);
      },
    ),
  );
}

/// Dialog s jednym textovym polom; vrati text alebo null (Cancel).
/// Controller patri stavu dialogu (zrusi sa az po zatvoreni animacie).
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String saveLabel,
  String initial = '',
  String? helper,
  TextInputType keyboardType = TextInputType.multiline,
  int maxLines = 8,
  Key? fieldKey,
  Key? saveKey,
}) => showDialog<String>(
  context: context,
  builder: (dialog) => _TextInputDialog(
    title: title,
    saveLabel: saveLabel,
    initial: initial,
    helper: helper,
    keyboardType: keyboardType,
    maxLines: maxLines,
    fieldKey: fieldKey,
    saveKey: saveKey,
  ),
);

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.saveLabel,
    required this.initial,
    required this.keyboardType,
    required this.maxLines,
    this.helper,
    this.fieldKey,
    this.saveKey,
  });

  final String title;
  final String saveLabel;
  final String initial;
  final String? helper;
  final TextInputType keyboardType;
  final int maxLines;
  final Key? fieldKey;
  final Key? saveKey;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      key: widget.fieldKey,
      controller: _controller,
      autofocus: true,
      keyboardType: widget.keyboardType,
      minLines: widget.maxLines > 1 ? 3 : 1,
      maxLines: widget.maxLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        helperText: widget.helper,
        helperMaxLines: 3,
        border: const OutlineInputBorder(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(SkUiStrings.of(context).cancel),
      ),
      TextButton(
        key: widget.saveKey,
        onPressed: () => Navigator.of(context).pop(_controller.text),
        child: Text(widget.saveLabel),
      ),
    ],
  );
}
