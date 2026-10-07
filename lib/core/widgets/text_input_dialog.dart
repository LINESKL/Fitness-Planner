import 'package:flutter/material.dart';

/// Диалог с одним полем; возвращает введённый текст или null при отмене.
/// Контроллер живёт столько же, сколько диалог (в том числе во время анимации закрытия).
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String initial = '',
  String? hint,
  String confirmLabel = 'ОК',
  TextInputType? keyboardType,
  int maxLines = 1,
}) => showDialog<String>(
  context: context,
  builder: (_) => _TextInputDialog(
    title: title,
    initial: initial,
    hint: hint,
    confirmLabel: confirmLabel,
    keyboardType: keyboardType,
    maxLines: maxLines,
  ),
);

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.initial,
    required this.hint,
    required this.confirmLabel,
    required this.keyboardType,
    required this.maxLines,
  });

  final String title;
  final String initial;
  final String? hint;
  final String confirmLabel;
  final TextInputType? keyboardType;
  final int maxLines;

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
      controller: _controller,
      autofocus: true,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      decoration: InputDecoration(hintText: widget.hint),
      onSubmitted: widget.maxLines == 1
          ? (v) => Navigator.pop(context, v)
          : null,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Отмена'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text),
        child: Text(widget.confirmLabel),
      ),
    ],
  );
}
