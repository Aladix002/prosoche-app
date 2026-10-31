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
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    focusNode: _focus,
    minLines: widget.minLines,
    maxLines: null,
    keyboardType: TextInputType.multiline,
    textCapitalization: TextCapitalization.sentences,
    decoration: InputDecoration(
      labelText: widget.label,
      alignLabelWithHint: true,
      border: const OutlineInputBorder(),
    ),
    onChanged: (_) {
      _timer?.cancel();
      _timer = Timer(JournalField.saveDelay, _flush);
    },
  );
}
